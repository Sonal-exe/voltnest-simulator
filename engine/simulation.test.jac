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

test "circuits group lights sockets and heavy appliances with standard ratings" {
    bulb = Device(name="Bulb", watts=10.0, start_minute=1080, run_minutes=300, lights_only=True);
    fan = Device(name="Fan", watts=60.0);
    socket_device = Device(name="Socket device", watts=100.0);
    ac = Device(name="AC", watts=1200.0);
    result = simulateDay([Room(name="Bedroom", devices=[bulb, fan, socket_device, ac])]);
    assert len(result.circuits) == 3;
    assert result.circuits[0].circuit_name == "Lights";
    assert result.circuits[0].peak_watts == 10.0;
    assert result.circuits[0].suggested_rating == 6;
    assert result.circuits[1].circuit_name == "Sockets";
    assert result.circuits[1].peak_watts == 160.0;
    assert result.circuits[1].suggested_rating == 6;
    assert result.circuits[2].circuit_name == "AC";
    assert result.circuits[2].peak_current > 5.0;
    assert result.circuits[2].suggested_rating == 10;
    assert not result.circuits[2].trips;
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

test "seasonal multiplier increases spring fan usage" {
    fan = Device(name="Fan", watts=60.0);
    assert _season_multiplier(fan, 4) == 1.5;
    assert _season_multiplier(fan, 1) == 0.5;
}

test "kettle has a dedicated circuit with a 6 amp recommendation" {
    kettle = Device(name="Kettle", watts=1500.0, start_minute=720, run_minutes=20);
    result = simulateDay([Room(name="Kitchen", devices=[kettle])]);
    assert len(result.circuits) == 1;
    assert result.circuits[0].circuit_name == "Kettle";
    assert result.circuits[0].peak_current > 6.0;
    assert result.circuits[0].suggested_rating == 10;
    assert not result.circuits[0].trips;
}

test "bulb runs only between six and eleven pm" {
    bulb = Device(name="Bulb", watts=10.0, start_minute=1080, run_minutes=300, lights_only=True);
    result = simulateDay([Room(name="Living room", devices=[bulb])]);
    assert abs(result.total_kwh - 0.05) < 0.000001;
    for load in result.step_loads {
        if load.minute >= 1080 and load.minute < 1380 {
            assert load.watts == 10.0;
        } else {
            assert load.watts == 0.0;
        }
    }
}
