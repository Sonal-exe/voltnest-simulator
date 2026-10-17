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

obj ScheduleSimulationResult {
    has step_loads: list[StepLoad] = [];
    has total_kwh: float = 0.0;
}

def simulateCircuit(circuit: Circuit) -> SimulationResult {
    return SimulationResult(
        circuit_name=circuit.name,
        component_count=len(circuit.components),
        summary="Your circuit is ready to explore."
    );
}

def simulateDay(rooms: list[Room]) -> ScheduleSimulationResult {
    step_loads: list[StepLoad] = [];
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
    return ScheduleSimulationResult(step_loads=step_loads, total_kwh=total_kwh);
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
