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
sem recommendHomeFix = "Choose a single useful change for this simulated home. If any circuit is overloaded, prioritize it; otherwise choose the device with highest daily kWh. Select only one supported exact action: move device to own circuit (use only if that device is on a shared circuit), swap bulbs to LED (10 W to 5 W, only for a Bulb), or shorten run time by 20%. Never invent other changes. The application validates and applies the change; do not calculate or claim energy totals.";
sem recommendHomeFix.issues = "Candidate issues, each including room, circuit/load status, and device names with simulated individual kWh. Overloaded circuits appear first.";
