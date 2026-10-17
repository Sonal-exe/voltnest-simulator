import from engine.circuits { Circuit, Device, Room, APPLIANCE_LIBRARY }

obj SimulationResult {
    has circuit_name: str = "";
    has component_count: int = 0;
    has summary: str = "";
}

obj StepLoad {
    has minute: int;
    has watts: float;
}

obj CircuitAdvice {
    has room_name: str;
    has circuit_name: str;
    has peak_watts: float;
    has peak_current: float;
    has suggested_rating: int;
    has trips: bool = False;
    has reason: str = "";
}

obj PeriodBar {
    has label: str;
    has kwh: float;
}

obj PeriodSimulationResult {
    has mode: str;
    has total_kwh: float = 0.0;
    has bars: list[PeriodBar] = [];
    has circuits: list[CircuitAdvice] = [];
}

obj ScheduleSimulationResult {
    has step_loads: list[StepLoad] = [];
    has total_kwh: float = 0.0;
    has circuits: list[CircuitAdvice] = [];
    has projection: PeriodSimulationResult = PeriodSimulationResult(mode="day");
    has estimated_cost: float | None = None;
}

def simulateCircuit(circuit: Circuit) -> SimulationResult {
    return SimulationResult(
        circuit_name=circuit.name,
        component_count=len(circuit.components),
        summary="Your circuit is ready to explore."
    );
}

def _circuit_label(device: Device) -> str {
    if device.lights_only or device.name == "Bulb" { return "Lights"; }
    return "Sockets";
}

def _is_heavy_device(device: Device) -> bool {
    return device.name.endswith(" (dedicated)");
}

def _rating_for_peak(peak_current: float) -> int {
    target = peak_current * 1.25;
    ratings: list[int] = [6, 10, 16, 20, 32, 40];
    for rating in ratings {
        if rating >= target { return rating; }
    }
    return 40;
}

def _circuit_advice(rooms: list[Room]) -> list[CircuitAdvice] {
    advice: list[CircuitAdvice] = [];
    for room in rooms {
        groups: list[str] = [];
        for device in room.devices {
            group = device.name if _is_heavy_device(device) else _circuit_label(device);
            exists = False;
            for existing in groups { if existing == group { exists = True; } }
            if not exists { groups.append(group); }
        }
        for group in groups {
            peak_watts: float = 0.0;
            for minute in range(0, 1440, 15) {
                load_watts: float = 0.0;
                for device in room.devices {
                    belongs = device.name == group if _is_heavy_device(device) else _circuit_label(device) == group;
                    if belongs {
                        active_minutes = 0;
                        interval_end = minute + 15;
                        for offset in [-1440, 0, 1440] {
                            start_at = device.start_minute + offset;
                            end_at = start_at + device.run_minutes;
                            overlap_start = minute if minute > start_at else start_at;
                            overlap_end = interval_end if interval_end < end_at else end_at;
                            overlap = overlap_end - overlap_start;
                            if overlap > 0 { active_minutes += overlap; }
                        }
                        if active_minutes > 15 { active_minutes = 15; }
                        if active_minutes > 0 {
                            load_watts = load_watts + device.watts * device.duty_cycle * active_minutes / 15.0;
                        }
                    }
                }
                if load_watts > peak_watts { peak_watts = load_watts; }
            }
            current = peak_watts / 230.0;
            rating = _rating_for_peak(current);
            trips = current > rating;
            reason = "Peak " + f"{peak_watts:.0f}" + " W at 230 V is " + f"{current:.2f}" + " A; 125% margin requires " + f"{current * 1.25:.2f}" + " A.";
            advice.append(CircuitAdvice(room_name=room.name, circuit_name=group, peak_watts=peak_watts, peak_current=current, suggested_rating=rating, trips=trips, reason=reason));
        }
    }
    return advice;
}

def simulateDay(rooms: list[Room]) -> ScheduleSimulationResult {
    step_loads: list[StepLoad] = [];
    circuits = _circuit_advice(rooms);
    total_kwh: float = 0.0;
    for step in range(96) {
        minute = step * 15;
        step_watts: float = 0.0;
        for room in rooms {
            for device in room.devices {
                active_minutes = 0;
                interval_end = minute + 15;
                for offset in [-1440, 0, 1440] {
                    device_start = device.start_minute + offset;
                    device_end = device_start + device.run_minutes;
                    overlap_start = minute if minute > device_start else device_start;
                    overlap_end = interval_end if interval_end < device_end else device_end;
                    overlap = overlap_end - overlap_start;
                    if overlap > 0 { active_minutes += overlap; }
                }
                if active_minutes > 15 { active_minutes = 15; }
                if active_minutes > 0 {
                    step_watts = step_watts + device.watts * device.duty_cycle * active_minutes / 15.0;
                }
            }
        }
        step_loads.append(StepLoad(minute=minute, watts=step_watts));
        total_kwh += step_watts * 0.25 / 1000.0;
    }
    return ScheduleSimulationResult(step_loads=step_loads, total_kwh=total_kwh, circuits=circuits);
}

def:pub simulateHomeDay(devices: list[Device]) -> ScheduleSimulationResult {
    return simulateDay([Room(name="Home", devices=devices)]);
}

def _season_multiplier(device: Device, month: int) -> float {
    return 1.0;
}

def _adjusted_rooms(rooms: list[Room], month: int, day: int, winter: bool) -> list[Room] {
    adjusted_rooms: list[Room] = [];
    for room in rooms {
        adjusted_devices: list[Device] = [];
        for device in room.devices {
            hours_multiplier = _season_multiplier(device, month);
            adjusted_run = int(device.run_minutes * hours_multiplier);
            if adjusted_run > 1440 { adjusted_run = 1440; }
            adjusted_start = device.start_minute;
            if winter and device.lights_only { adjusted_start = 1020; }
            adjusted_devices.append(Device(name=device.name, watts=device.watts, start_minute=adjusted_start, run_minutes=adjusted_run, duty_cycle=device.duty_cycle, lights_only=device.lights_only));
        }
        adjusted_rooms.append(Room(name=room.name, devices=adjusted_devices));
    }
    return adjusted_rooms;
}

def:pub simulatePeriod(room_names: list[str], room_devices: list[list[dict]], mode: str, price_per_kwh: float) -> dict {
    rooms: list[Room] = [];
    for (index, room_name) in enumerate(room_names) {
        devices: list[Device] = [];
        for item in room_devices[index] {
            devices.append(Device(name=item["name"] as str, watts=item["watts"] as float, start_minute=item["start_minute"] as int, run_minutes=item["run_minutes"] as int, duty_cycle=item["duty_cycle"] as float, lights_only=item["lights_only"] as bool));
        }
        rooms.append(Room(name=room_name, devices=devices));
    }
    if mode == "day" {
        day_result = simulateDay(rooms);
        daily_rows: list[dict] = [];
        advice_rows: list[dict] = [];
        for load in day_result.step_loads { daily_rows.append({"minute": load.minute, "watts": load.watts}); }
        for item in day_result.circuits { advice_rows.append({"room_name": item.room_name, "circuit_name": item.circuit_name, "peak_watts": item.peak_watts, "peak_current": item.peak_current, "suggested_rating": item.suggested_rating, "trips": item.trips, "reason": item.reason}); }
        return {"mode": mode, "total_kwh": day_result.total_kwh, "step_loads": daily_rows, "bars": [], "estimated_cost": (day_result.total_kwh * price_per_kwh if price_per_kwh > 0.0 else None), "circuits": advice_rows};
    }
    bars: list[PeriodBar] = [];
    total_kwh: float = 0.0;
    circuits = _circuit_advice(rooms);
    if mode == "month" {
        for day in range(30) {
            month = 1;
            adjusted = _adjusted_rooms(rooms, month, day, False);
            day_result = simulateDay(adjusted);
            bars.append(PeriodBar(label="Day " + str(day + 1), kwh=day_result.total_kwh));
            total_kwh += day_result.total_kwh;
        }
    } else {
        month_totals: list[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
        days_in_month: list[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        for month_index in range(12) {
            month = month_index + 1;
            for day in range(days_in_month[month_index]) {
                adjusted = _adjusted_rooms(rooms, month, day, False);
                day_result = simulateDay(adjusted);
                month_totals[month_index] = month_totals[month_index] + day_result.total_kwh;
                total_kwh += day_result.total_kwh;
            }
            labels: list[str] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            bars.append(PeriodBar(label=labels[month_index], kwh=month_totals[month_index]));
        }
    }
    cost: float | None = None;
    if price_per_kwh > 0.0 { cost = total_kwh * price_per_kwh; }
    bar_rows: list[dict] = [];
    advice_rows: list[dict] = [];
    for bar in bars { bar_rows.append({"label": bar.label, "kwh": bar.kwh}); }
    for item in circuits { advice_rows.append({"room_name": item.room_name, "circuit_name": item.circuit_name, "peak_watts": item.peak_watts, "peak_current": item.peak_current, "suggested_rating": item.suggested_rating, "trips": item.trips, "reason": item.reason}); }
    return {"mode": mode, "total_kwh": total_kwh, "step_loads": [], "bars": bar_rows, "estimated_cost": cost, "circuits": advice_rows};
}

def:pub simulateRoomData(room_names: list[str], room_devices: list[list[dict]]) -> ScheduleSimulationResult {
    rooms: list[Room] = [];
    for (index, room_name) in enumerate(room_names) {
        devices: list[Device] = [];
        for item in room_devices[index] {
            devices.append(Device(
                name=item["name"] as str,
                watts=item["watts"] as float,
                start_minute=item["start_minute"] as int,
                run_minutes=item["run_minutes"] as int,
                duty_cycle=item["duty_cycle"] as float,
                lights_only=item["lights_only"] as bool
            ));
        }
        rooms.append(Room(name=room_name, devices=devices));
    }
    return simulateDay(rooms);
}

def:pub simulateApplianceData(appliances: list[dict]) -> ScheduleSimulationResult {
    devices: list[Device] = [];
    for appliance in appliances {
        for estimate in APPLIANCE_LIBRARY {
            if estimate.name == (appliance["name"] as str) {
                devices.append(Device(
                    name=estimate.name,
                    watts=appliance["watts"] as float,
                    start_minute=estimate.start_minute,
                    run_minutes=estimate.run_minutes,
                    duty_cycle=appliance["duty_cycle"] as float,
                    lights_only=estimate.lights_only
                ));
            }
        }
    }
    return simulateDay([Room(name="Home", devices=devices)]);
}
