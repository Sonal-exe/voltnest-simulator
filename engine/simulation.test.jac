test "daily simulation covers all quarter hour intervals" {
    room = Room(name="Test room", devices=[]);
    result = simulateDay([room]);
    assert len(result.step_loads) == 96;
    assert result.total_kwh == 0.0;
}

test "kettle uses half a kilowatt hour" {
    kettle = Device(name="Kettle", watts=1500.0, start_minute=720, run_minutes=20);
    result = simulateDay([Room(name="Kitchen", devices=[kettle])]);
    assert abs(result.total_kwh - 0.5) < 0.000001;
}

test "circuits group lights separately and all plug-in appliances under sockets" {
    bulb = Device(name="Bulb", watts=10.0, start_minute=1080, run_minutes=300, lights_only=True);
    fan = Device(name="Fan", watts=60.0);
    socket_device = Device(name="Socket device", watts=100.0);
    heater = Device(name="Water heater", watts=1200.0);
    fridge = Device(name="Fridge", watts=150.0);
    result = simulateDay([Room(name="Bedroom", devices=[bulb, fan, socket_device, heater, fridge])]);
    assert len(result.circuits) == 2;
    assert result.circuits[0].circuit_name == "Lights";
    assert result.circuits[0].peak_watts == 10.0;
    assert result.circuits[0].suggested_rating == 6;
    assert result.circuits[1].circuit_name == "Sockets";
    assert result.circuits[1].peak_watts == 1510.0;
    assert result.circuits[1].suggested_rating == 10;
    assert not result.circuits[1].trips;
}

test "period simulation returns daily bars for a month and monthly bars for a year" {
    names: list[str] = ["Room"];
    appliance = {"name": "Fan", "watts": 60.0, "start_minute": 0, "run_minutes": 1440, "duty_cycle": 1.0, "lights_only": False};
    devices: list[list[dict]] = [[appliance]];
    month_result = simulatePeriod(names, devices, "month", 0.25);
    year_result = simulatePeriod(names, devices, "year", 0.25);
    assert len(month_result["bars"]) == 30;
    assert len(year_result["bars"]) == 12;
    assert month_result["total_kwh"] > 0.0;
    assert month_result["estimated_cost"] is not None;
}

test "seasonal estimates preserve configured appliance runtime" {
    fan = Device(name="Fan", watts=60.0, run_minutes=600);
    assert _season_multiplier(fan, 4) == 1.0;
    assert _season_multiplier(fan, 1) == 1.0;
    adjusted = _adjusted_rooms([Room(name="Room", devices=[fan])], 4, 2, False);
    assert adjusted[0].devices[0].run_minutes == 600;
}

test "socket appliances remain grouped unless explicitly moved to a dedicated circuit" {
    kettle = Device(name="Kettle", watts=1500.0, start_minute=720, run_minutes=20);
    fridge = Device(name="Fridge", watts=150.0, run_minutes=1440, duty_cycle=0.4);
    shared = simulateDay([Room(name="Kitchen", devices=[kettle, fridge])]);
    assert len(shared.circuits) == 1;
    assert shared.circuits[0].circuit_name == "Sockets";
    dedicated = Device(name="Kettle (dedicated)", watts=1500.0, start_minute=720, run_minutes=20);
    moved = simulateDay([Room(name="Kitchen", devices=[dedicated, fridge])]);
    assert len(moved.circuits) == 2;
    assert moved.circuits[0].circuit_name == "Kettle (dedicated)";
    assert moved.circuits[0].suggested_rating == 10;
}

test "bulb estimate respects the user configured run time" {
    bulb = Device(name="Bulb", watts=10.0, start_minute=1080, run_minutes=120, lights_only=True);
    result = simulateDay([Room(name="Living room", devices=[bulb])]);
    assert abs(result.total_kwh - 0.02) < 0.000001;
}

test "runtime spanning midnight is counted in both portions of the day" {
    fan = Device(name="Fan", watts=100.0, start_minute=1380, run_minutes=120);
    result = simulateDay([Room(name="Bedroom", devices=[fan])]);
    assert abs(result.total_kwh - 0.2) < 0.000001;
    assert result.step_loads[92].watts == 100.0;
    assert result.step_loads[0].watts == 100.0;
    assert abs(result.circuits[0].peak_watts - 100.0) < 0.000001;
}

test "day and month runtime use the same daily estimate" {
    fan = {"name": "Fan", "watts": 100.0, "start_minute": 0, "run_minutes": 120, "duty_cycle": 1.0, "lights_only": False};
    month_result = simulatePeriod(["Bedroom"], [[fan]], "month", 0.0);
    assert abs((month_result["total_kwh"] as float) - 6.0) < 0.000001;
}
