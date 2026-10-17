import from engine.circuits { Circuit, Device, Room }

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
                    overlap_start = minute if minute > device.start_minute else device.start_minute;
                    interval_end = minute + 15;
                    device_end = device.start_minute + device.run_minutes;
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
