test "simple two bedroom fan description works without llm" {
    plan = _simpleHousePlan("2 bedrooms with fans");
    assert plan is not None;
    assert len(plan.rooms) == 2;
    assert plan.rooms[0].name == "Bedroom 1";
    assert len(plan.rooms[0].devices) == 1;
    assert plan.rooms[0].devices[0].name == "Fan";
    assert plan.rooms[0].devices[0].count == 1;
}

test "simple bedroom kitchen description uses only catalog devices" {
    plan = _simpleHousePlan("2 bedrooms with fans, kitchen with fridge and kettle");
    assert plan is not None;
    assert len(plan.rooms) == 3;
    assert plan.rooms[2].name == "Kitchen";
    assert len(plan.rooms[2].devices) == 2;
    assert plan.rooms[2].devices[0].name == "Fridge";
    assert plan.rooms[2].devices[1].name == "Kettle";
    assert plan.rooms[0].devices[0].name == "Fan";
    assert plan.rooms[1].devices[0].name == "Fan";
}
