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
