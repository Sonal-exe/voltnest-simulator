import from agents.houseDescription { HousePlan, SuggestedRoom, SuggestedAppliance, extractHousePlan }


def _normalized(text: str) -> str {
    value = text.lower().replace(".", " ").replace(";", ",").replace(" and ", ", ");
    while "  " in value { value = value.replace("  ", " "); }
    return value.strip();
}

def _count_before(words: list[str], index: int) -> int {
    if index <= 0 { return 1; }
    previous = words[index - 1];
    if previous == "one" { return 1; }
    if previous == "two" { return 2; }
    if previous == "three" { return 3; }
    if previous == "four" { return 4; }
    if previous == "five" { return 5; }
    try { amount = int(previous); return amount if amount > 0 and amount <= 12 else 1; }
    except ValueError { return 1; }
}

def _fallback_house_plan(description: str) -> HousePlan {
    text = _normalized(description);
    parts = text.split(",");
    room_names: list[str] = [];
    room_devices: list[list[SuggestedAppliance]] = [];
    active_room = -1;
    bedroom_group_end = -1;
    bedroom_group_start = -1;
    bedroom_group_count = 0;
    for part in parts {
        words = part.strip().split(" ");
        if len(words) == 0 { continue; }
        if "bedroom" in part or "bedrooms" in part {
            count = 1;
            for (index, word) in enumerate(words) {
                if word == "bedroom" or word == "bedrooms" { count = _count_before(words, index); }
            }
            if count > 6 { count = 6; }
            bedroom_group_start = len(room_names);
            bedroom_group_count = count;
            for room_index in range(count) {
                room_names.append("Bedroom " + str(room_index + 1));
                room_devices.append([]);
            }
            active_room = len(room_names) - 1;
            bedroom_group_end = active_room;
        } elif "living room" in part {
            room_names.append("Living room");
            room_devices.append([]);
            active_room = len(room_names) - 1;
        } elif "kitchen" in part {
            room_names.append("Kitchen");
            room_devices.append([]);
            active_room = len(room_names) - 1;
        } elif "bathroom" in part or "bathrooms" in part {
            room_names.append("Bathroom");
            room_devices.append([]);
            active_room = len(room_names) - 1;
        } elif "room" in part and active_room < 0 {
            room_names.append("Room");
            room_devices.append([]);
            active_room = len(room_names) - 1;
        }
        if active_room < 0 { continue; }
        appliances: list[list[str]] = [
            ["water heater", "Water heater"], ["washing machine", "Washing machine"],
            ["fridge", "Fridge"], ["refrigerator", "Fridge"], ["kettle", "Kettle"],
            ["vacuum", "Vacuum"], ["air conditioner", "AC"], [" ac ", "AC"],
            ["television", "TV"], [" tv ", "TV"], ["fans", "Fan"], ["fan", "Fan"],
            ["bulbs", "Bulb"], ["bulb", "Bulb"], ["lights", "Bulb"], ["light", "Bulb"], ["socket device", "Socket device"]
        ];
        for entry in appliances {
            phrase = entry[0];
            device_name = entry[1];
            search_part = " " + part + " ";
            if phrase in search_part and not (phrase == "fan" and "fans" in part) and not (phrase == "light" and "lights" in part) and not (phrase == "bulb" and "bulbs" in part) {
                phrase_words = phrase.strip().split(" ");
                phrase_index = -1;
                for (index, word) in enumerate(words) {
                    if word == phrase_words[0] { phrase_index = index; }
                }
                amount = _count_before(words, phrase_index);
                is_bedroom_group = bedroom_group_end >= active_room and bedroom_group_start >= 0 and not ("kitchen" in part or "living room" in part or "bathroom" in part);
                start_room = active_room;
                end_room = active_room;
                if is_bedroom_group { start_room = bedroom_group_start; end_room = bedroom_group_end; }
                for room_index in range(start_room, end_room + 1) {
                    existing_count = 0;
                    for existing in room_devices[room_index] {
                        if existing.name == device_name { existing_count = existing.count; }
                    }
                    if existing_count == 0 {
                        room_devices[room_index].append(SuggestedAppliance(name=device_name, count=1 if is_bedroom_group and device_name == "Fan" else amount));
                    } else {
                        updated: list[SuggestedAppliance] = [];
                        for existing in room_devices[room_index] {
                            if existing.name == device_name { updated.append(SuggestedAppliance(name=device_name, count=existing_count + amount)); }
                            else { updated.append(existing); }
                        }
                        room_devices[room_index] = updated;
                    }
                }
            }
        }
    }
    if len(room_names) == 0 {
        return HousePlan(summary="No recognizable rooms were found. Name rooms such as bedroom, kitchen, or living room.", rooms=[]);
    }
    rooms: list[SuggestedRoom] = [];
    for (index, room_name) in enumerate(room_names) {
        devices = room_devices[index];
        if "bedroom" in room_name.lower() and len(devices) == 0 {
            for part in parts {
                if "bedroom" in part and "fan" in part {
                    devices.append(SuggestedAppliance(name="Fan", count=1));
                }
            }
        }
        rooms.append(SuggestedRoom(name=room_name, devices=devices));
    }
    return HousePlan(summary="Room and appliance estimates parsed from your description.", rooms=rooms);
}

def:pub parseHouseDescription(description: str) -> HousePlan {
    local_plan = _fallback_house_plan(description);
    if len(local_plan.rooms) > 0 { return local_plan; }
    allowed_devices: list[str] = [device.name for device in APPLIANCE_LIBRARY];
    try {
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
        if len(safe_rooms) > 0 { return HousePlan(summary=plan.summary, rooms=safe_rooms); }
    } except Exception { }
    return local_plan;
}
