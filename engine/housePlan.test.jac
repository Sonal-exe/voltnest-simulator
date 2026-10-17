test "house plan response schema keeps supplied room names" {
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
