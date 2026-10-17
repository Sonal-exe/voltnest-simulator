obj SuggestedAppliance {
    has name: str;
    has count: int = 1;
}

obj SuggestedRoom {
    has name: str;
    has devices: list[SuggestedAppliance] = [];
}

obj HousePlan {
    has summary: str;
    has rooms: list[SuggestedRoom] = [];
}

sem SuggestedAppliance.name = "Exact appliance name from the supplied built-in catalog only. Never invent another device type.";
sem SuggestedAppliance.count = "How many instances the homeowner describes or implies for that room. Use 1 when a singular item is described.";
sem SuggestedRoom.name = "A clear room name inferred from the homeowner's description. Preserve room types and quantities such as bedrooms.";
sem SuggestedRoom.devices = "Assign each appliance to the room the homeowner associates it with. Infer suitable appliances from the room description only when reasonable, using only allowed catalog types. Do not copy one room's appliance into other rooms unless the description implies it.";
sem HousePlan.summary = "One short plain-language sentence explaining the rooms and appliance needs you inferred.";
sem HousePlan.rooms = "Every room the homeowner describes or clearly implies, with suitable catalog appliances assigned to the correct room.";

def extractHousePlan(description: str, allowed_devices: list[str]) -> HousePlan by llm(temperature=0.2, max_tokens=700);
sem extractHousePlan = "Act as a thoughtful home-energy planning agent. Understand the whole house description semantically, not by matching keywords. Identify and name rooms, interpret quantities, and determine which appliances belong in each room. For example, '2 bedrooms with fans, kitchen with fridge and kettle' means two separate bedroom rooms each with one Fan, and a Kitchen with one Fridge and one Kettle. Only choose exact names from allowed_devices. If room intent is clear but no appliance is specified, return the room with an empty devices list. Never invent appliance types or add unrelated rooms.";
sem extractHousePlan.description = "The complete plain-English description of the home. Interpret its intent and room-to-appliance relationships.";
sem extractHousePlan.allowed_devices = "The strict list of built-in appliance names available to assign. Use these exact names only.";
