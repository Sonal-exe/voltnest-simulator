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

obj ScheduleSimulationResult {
    has step_loads: list[StepLoad] = [];
    has total_kwh: float = 0.0;
    has circuits: list[CircuitAdvice] = [];
}

def simulateCircuit(circuit: Circuit) -> SimulationResult {
    return SimulationResult(
        circuit_name=circuit.name,
        component_count=len(circuit.components),
        summary="Your circuit is ready to explore."
    );
}

def _circuit_label(device: Device) -> str {
    if device.name == "Bulb" { return "Lights"; }
    return "Sockets";
}

def _is_heavy_device(device: Device) -> bool {
    return device.name == "AC" or device.name == "Water heater" or device.name == "Kettle" or device.name == "Washing machine";
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
                        active_minutes = 15;
                        if device.lights_only and (minute < 1080 or minute >= 1380) {
                            active_minutes = 0;
                        } elif device.run_minutes < 1440 {
                            interval_end = minute + 15;
                            device_end = device.start_minute + device.run_minutes;
                            start = minute if minute > device.start_minute else device.start_minute;
                            finish = interval_end if interval_end < device_end else device_end;
                            active_minutes = finish - start;
                            if active_minutes < 0 { active_minutes = 0; }
                            if active_minutes > 15 { active_minutes = 15; }
                        }
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
                active_minutes = 15;
                if device.lights_only and (minute < 1080 or minute >= 1380) {
                    active_minutes = 0;
                } elif device.run_minutes < 1440 {
                    interval_start = minute;
                    interval_end = minute + 15;
                    device_start = device.start_minute;
                    device_end = device.start_minute + device.run_minutes;
                    overlap_start = interval_start if interval_start > device_start else device_start;
                    overlap_end = interval_end if interval_end < device_end else device_end;
                    active_minutes = overlap_end - overlap_start;
                    if active_minutes < 0 { active_minutes = 0; }
                    if active_minutes > 15 { active_minutes = 15; }
                }
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
