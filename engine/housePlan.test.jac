test "house plan preserves rooms and appliance counts" {
    room = SuggestedRoom(name="Studio", devices=[]);
    plan = HousePlan(summary="A compact studio.", rooms=[room]);
    assert plan.summary == "A compact studio.";
    assert len(plan.rooms) == 1;
    assert plan.rooms[0].name == "Studio";
}

test "appliance counts are bounded by parser response consumer" {
    suggestion = SuggestedAppliance(name="Fan", count=2);
    assert suggestion.name == "Fan";
    assert suggestion.count == 2;
}

test "local fallback understands multiple rooms and appliance counts" {
    plan = _fallback_house_plan("2 bedrooms with fans and 2 lights, a kitchen with a water heater and 1 light, living room with a tv, 2 lights");
    assert len(plan.rooms) == 4;
    assert plan.rooms[0].name == "Bedroom 1";
    assert plan.rooms[1].name == "Bedroom 2";
    assert plan.rooms[0].devices[0].name == "Fan";
    assert plan.rooms[0].devices[1].name == "Bulb";
    assert plan.rooms[0].devices[1].count == 2;
    assert plan.rooms[1].devices[0].count == 1;
    assert plan.rooms[2].name == "Kitchen";
    assert plan.rooms[2].devices[0].name == "Water heater";
    assert plan.rooms[2].devices[1].count == 1;
    assert plan.rooms[3].name == "Living room";
    assert plan.rooms[3].devices[0].name == "TV";
    assert plan.rooms[3].devices[1].count == 2;
}

test "local fallback asks for recognizable room when input is unclear" {
    plan = _fallback_house_plan("a comfortable place with electricity");
    assert len(plan.rooms) == 0;
    assert "No recognizable rooms" in plan.summary;
}
