obj HomeFix {
    has action: str;
    has room_name: str;
    has device_name: str;
    has explanation: str;
}
sem HomeFix.action = "Exactly one of: move device to own circuit, swap bulbs to LED, shorten run time by 20%. Return the exact listed action text.";
sem HomeFix.room_name = "Room containing the target device; use the supplied room with the highest-priority issue.";
sem HomeFix.device_name = "Exact device name to adjust, selected only from the supplied candidates.";
sem HomeFix.explanation = "One short plain-language explanation of the selected safe fix.";

def:pub recommendHomeFix(issues: list[str]) -> HomeFix by llm(temperature=0.1, max_tokens=180);
sem recommendHomeFix = "First classify every listed appliance as LIGHTS or SOCKETS: lights include only lamps/bulbs used for illumination; all other appliances plugged into receptacles, including heaters and fridges, are SOCKETS. Then choose one useful change. If any circuit is overloaded prioritize it; otherwise choose the highest-kWh device. Select only an exact supported action: move device to own circuit (only a device on a shared circuit), swap bulbs to LED (10 W to 5 W, only for a Bulb), or shorten run time by 20%. Never invent changes. Do not calculate energy totals.";
sem recommendHomeFix.issues = "Appliance candidates with room, existing circuit label, wattage, run time, and engine-provided daily kWh. Use the appliance kind rules to identify lights versus socket loads; overloaded circuits are listed first.";
