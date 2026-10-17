import from engine.circuits { APPLIANCE_LIBRARY }
import from agents.houseDescription { HousePlan, SuggestedRoom, SuggestedAppliance, extractHousePlan }

def:pub parseHouseDescription(description: str) -> HousePlan {
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
