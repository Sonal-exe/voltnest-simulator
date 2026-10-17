import from agents.houseDescription { HousePlan, SuggestedRoom, SuggestedAppliance, extractHousePlan }
import from engine.circuits { APPLIANCE_LIBRARY }

def _simpleHousePlan(description: str) -> HousePlan | None {
    text = description.lower();
    room_count = 0;
    if "2 bedroom" in text { room_count = 2; }
    elif "3 bedroom" in text { room_count = 3; }
    elif "4 bedroom" in text { room_count = 4; }
    elif "bedroom" in text { room_count = 1; }

    rooms: list[SuggestedRoom] = [];
    if room_count > 0 {
        room_devices: list[SuggestedAppliance] = [];
        if ("fan" in text) and ("bedroom" in text) { room_devices.append(SuggestedAppliance(name="Fan", count=1)); }
        if ("bulb" in text or "light" in text) and ("bedroom" in text) { room_devices.append(SuggestedAppliance(name="Bulb", count=1)); }
        for index in range(room_count) {
            rooms.append(SuggestedRoom(name="Bedroom " + str(index + 1), devices=room_devices));
        }
    }

    if "kitchen" in text {
        kitchen_devices: list[SuggestedAppliance] = [];
        if "fridge" in text { kitchen_devices.append(SuggestedAppliance(name="Fridge", count=1)); }
        if "kettle" in text { kitchen_devices.append(SuggestedAppliance(name="Kettle", count=1)); }
        if "kitchen with fan" in text or "kitchen fan" in text { kitchen_devices.append(SuggestedAppliance(name="Fan", count=1)); }
        if "water heater" in text { kitchen_devices.append(SuggestedAppliance(name="Water heater", count=1)); }
        rooms.append(SuggestedRoom(name="Kitchen", devices=kitchen_devices));
    }

    if len(rooms) == 0 { return None; }
    return HousePlan(summary="I found " + str(len(rooms)) + " rooms and matched the appliances you mentioned.", rooms=rooms);
}

def:pub parseHouseDescription(description: str) -> HousePlan {
    simple_plan = _simpleHousePlan(description);
    if simple_plan is not None { return simple_plan; }
    allowed_devices: list[str] = [device.name for device in APPLIANCE_LIBRARY];
    plan = extractHousePlan(description, allowed_devices);
    safe_rooms: list[SuggestedRoom] = [];
    for room in plan.rooms {
        safe_devices: list[SuggestedAppliance] = [];
        for suggested in room.devices {
            allowed = False;
            for known in APPLIANCE_LIBRARY {
                if known.name == suggested.name { allowed = True; }
            }
            if allowed and suggested.count > 0 and suggested.count <= 12 {
                safe_devices.append(SuggestedAppliance(name=suggested.name, count=suggested.count));
            }
        }
        safe_rooms.append(SuggestedRoom(name=room.name, devices=safe_devices));
    }
    return HousePlan(summary=plan.summary, rooms=safe_rooms);
}
