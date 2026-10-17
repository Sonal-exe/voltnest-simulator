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
sem SuggestedAppliance.count = "How many of this appliance are in the room; default to 1 when implied.";
sem SuggestedRoom.name = "A clear room name based on the house description.";
sem SuggestedRoom.devices = "Appliances explicitly mentioned or naturally required in the room, using only catalog items.";
sem HousePlan.summary = "One short plain-language sentence restating what was understood about the house.";
sem HousePlan.rooms = "Rooms described by the user, each with appliances from the supplied catalog.";

def extractHousePlan(description: str, allowed_devices: list[str]) -> HousePlan by llm(temperature=0.1, max_tokens=500);
sem extractHousePlan = "Turn a plain-English home description into rooms and appliances. Only use exact names in allowed_devices; omit any appliance not present in that list. Do not infer arbitrary electrical components.";
sem extractHousePlan.description = "The homeowner's description of rooms and appliances.";
sem extractHousePlan.allowed_devices = "The complete allowlist of appliance names that may appear in the plan.";
