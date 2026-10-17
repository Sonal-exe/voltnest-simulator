import from .ui.card { Card, CardContent, CardHeader, CardTitle, CardDescription }
import from .ui.button { Button }
import from .EnergyShell { EnergyShell }
sv import from ..engine.circuits { Device }
sv import from ..engine.simulation { ScheduleSimulationResult, simulateRoomData }
sv import from ..agents.circuitAgent { HomeFix, recommendHomeFix }

def:pub ImproveMyHome() -> JsxElement {
    has room_names: list[str] = ["Room 1", "Room 2", "Room 3"];
    has room_devices: list[list[dict]] = [
        [
            {"name": "Bulb", "watts": 10.0, "start_minute": 1080, "run_minutes": 300, "duty_cycle": 1.0, "lights_only": True},
            {"name": "Fan", "watts": 60.0, "start_minute": 0, "run_minutes": 600, "duty_cycle": 1.0, "lights_only": False},
            {"name": "Kettle", "watts": 1500.0, "start_minute": 720, "run_minutes": 45, "duty_cycle": 1.0, "lights_only": False}
        ],
        [
            {"name": "Bulb", "watts": 10.0, "start_minute": 1080, "run_minutes": 300, "duty_cycle": 1.0, "lights_only": True},
            {"name": "Fridge", "watts": 150.0, "start_minute": 0, "run_minutes": 1440, "duty_cycle": 0.4, "lights_only": False}
        ],
        [
            {"name": "Bulb", "watts": 10.0, "start_minute": 1080, "run_minutes": 300, "duty_cycle": 1.0, "lights_only": True},
            {"name": "Fan", "watts": 60.0, "start_minute": 0, "run_minutes": 720, "duty_cycle": 1.0, "lights_only": False}
        ]
    ];
    has result: ScheduleSimulationResult | None = None;
    has before_kwh: float = 0.0;
    has after_kwh: float = 0.0;
    has rounds: int = 0;
    has fixes: list[HomeFix] = [];
    has running: bool = False;
    has message: str = "Run the improvement loop to simulate the sample home.";
    has error_message: str = "";

    def copy_rooms(source: list[list[dict]]) -> list[list[dict]] {
        copied: list[list[dict]] = [];
        for room in source {
            devices: list[dict] = [];
            for device in room {
                devices.append({"name": device["name"], "watts": device["watts"], "start_minute": device["start_minute"], "run_minutes": device["run_minutes"], "duty_cycle": device["duty_cycle"], "lights_only": device["lights_only"]});
            }
            copied.append(devices);
        }
        return copied;
    }

    def allowed_action(action: str) -> bool {
        return action == "move device to own circuit" or action == "swap bulbs to LED" or action == "shorten run time by 20%";
    }

    async def improve_home {
        running = True;
        error_message = "";
        message = "Simulating the current room loads…";
        fixes = [];
        rounds = 0;
        working = copy_rooms(room_devices);
        current = await simulateRoomData(room_names, working);
        before_kwh = current.total_kwh;
        after_kwh = current.total_kwh;
        result = current;
        while rounds < 3 {
            has_any_device = False;
            for room in working { if len(room) > 0 { has_any_device = True; } }
            if not has_any_device { message = "Add a device before running improvements."; break; }
            overloaded_room = "";
            overloaded_circuit = "";
            for circuit in current.circuits {
                if circuit.trips and overloaded_circuit == "" {
                    overloaded_room = circuit.room_name;
                    overloaded_circuit = circuit.circuit_name;
                }
            }
            candidates: list[str] = [];
            if overloaded_circuit != "" {
                candidates.append("PRIORITY: overloaded circuit in " + overloaded_room + " named " + overloaded_circuit + ".");
            }
            for (room_index, devices) in enumerate(working) {
                for device in devices {
                    watts = device["watts"] as float;
                    run_minutes = device["run_minutes"] as int;
                    duty = device["duty_cycle"] as float;
                    daily_kwh = watts * duty * run_minutes / 60.0 / 1000.0;
                    candidates.append("Room=" + room_names[room_index] + "; device=" + str(device["name"]) + "; daily kWh=" + f"{daily_kwh:.3f}" + "; watts=" + str(watts) + "; run minutes=" + str(run_minutes) + "; shared group only if lights or sockets.");
                }
            }
            if len(candidates) == 0 { message = "No appliances found to improve."; break; }
            suggestion: HomeFix;
            try {
                suggestion = await recommendHomeFix(candidates);
            } except Exception {
                error_message = "The recommendation service could not respond. Add your LLM key in Settings and try again.";
                break;
            }
            action = suggestion.action.strip().lower();
            if not allowed_action(action) {
                error_message = "The recommendation was outside the allowed fixes, so no change was applied.";
                break;
            }
            target_room = -1;
            for (room_index, room_name) in enumerate(room_names) {
                if room_name == suggestion.room_name { target_room = room_index; }
            }
            target_device = -1;
            if target_room >= 0 {
                for (device_index, device) in enumerate(working[target_room]) {
                    if str(device["name"]) == suggestion.device_name { target_device = device_index; }
                }
            }
            if target_device < 0 {
                error_message = "The recommendation did not identify an available device; no change was applied.";
                break;
            }
            chosen = working[target_room][target_device];
            applied = False;
            if action == "swap bulbs to led" and str(chosen["name"]) == "Bulb" and (chosen["watts"] as float) == 10.0 {
                chosen["watts"] = 5.0;
                applied = True;
            } elif action == "shorten run time by 20%" and (chosen["run_minutes"] as int) > 1 {
                chosen["run_minutes"] = int((chosen["run_minutes"] as int) * 0.8);
                applied = True;
            } elif action == "move device to own circuit" {
                is_shared = str(chosen["name"]) == "Bulb" or str(chosen["name"]) == "Fan" or str(chosen["name"]) == "Socket device" or str(chosen["name"]) == "TV" or str(chosen["name"]) == "Fridge";
                if is_shared {
                    chosen["name"] = str(chosen["name"]) + " (dedicated)";
                    applied = True;
                }
            }
            if not applied {
                error_message = "That fix does not apply to the selected device, so it was not changed.";
                break;
            }
            fixes.append(HomeFix(action=action, room_name=suggestion.room_name, device_name=suggestion.device_name, explanation=suggestion.explanation));
            rounds += 1;
            current = await simulateRoomData(room_names, working);
            after_kwh = current.total_kwh;
            result = current;
        }
        message = "Finished " + str(rounds) + " of 3 possible improvement rounds. Energy totals are recalculated by the simulator.";
        running = False;
    }

    return <EnergyShell current="improve">
        <section className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-5 py-8 md:px-8 md:py-10">
            <div className="flex flex-col gap-2"><p className="text-xs font-semibold uppercase tracking-[0.24em] text-cyan-200/70">Home improvements</p><h1 className="text-3xl font-semibold tracking-tight text-white">Improve my home</h1><p className="text-sm text-slate-400">Simulate, apply up to three practical changes, then compare the engine’s daily energy totals.</p></div>
            <Card className="border border-violet-200/15 bg-[#140d22]/90 shadow-xl shadow-violet-950/20">
                <CardHeader><CardTitle className="text-slate-100">Three-round improvement check</CardTitle><CardDescription className="text-slate-400">Overloaded circuits come first. Recommendations are limited to the approved fixes.</CardDescription></CardHeader>
                <CardContent className="flex flex-col gap-4">
                    <div className="flex flex-wrap items-center gap-3"><Button onClick={improve_home} disabled={running}>{"Simulating…" if running else "Run improvement loop"}</Button><p className="text-sm text-slate-300">{message}</p></div>
                    {if error_message != "" { <p role="alert" className="text-sm text-rose-300">{error_message}</p> }}
                    {if result is not None {
                        <div className="grid gap-3 sm:grid-cols-2">
                            <div className="rounded-xl border border-violet-200/15 bg-[#0d0917]/80 p-4"><p className="text-xs uppercase tracking-wide text-slate-400">Before changes · daily</p><p className="mt-2 text-3xl font-semibold tabular-nums text-white">{f"{before_kwh:.3f} kWh"}</p></div>
                            <div className="rounded-xl border border-cyan-200/20 bg-cyan-300/5 p-4"><p className="text-xs uppercase tracking-wide text-slate-400">After changes · daily</p><p className="mt-2 text-3xl font-semibold tabular-nums text-cyan-100">{f"{after_kwh:.3f} kWh"}</p></div>
                        </div>
                    }}
                    {if len(fixes) > 0 {
                        <div className="flex flex-col gap-2 border-t border-violet-200/10 pt-4"><h2 className="font-medium text-slate-100">Applied suggestions</h2>{for (index, fix) in enumerate(fixes) { <div key={str(index)} className="rounded-lg border border-violet-200/10 bg-[#0d0917]/80 p-3"><p className="text-sm font-medium text-cyan-100">{fix.room_name + " · " + fix.device_name + " · " + fix.action}</p><p className="mt-1 text-sm text-slate-400">{fix.explanation}</p></div> }}</div>
                    }}
                </CardContent>
            </Card>
            <div className="flex flex-col gap-3"><div><h2 className="text-xl font-semibold text-white">Whole-home circuit sketch</h2><p className="text-sm text-slate-400">230 V supply branches to each room. MCB ratings and load warnings come from the simulator.</p></div>
                {if result is None { <Card className="border border-violet-200/15 bg-[#140d22]/90"><CardContent className="py-10 text-center"><p className="font-medium text-slate-100">Circuit sketch is ready</p><p className="mt-1 text-sm text-slate-400">Run the improvement loop to calculate each room’s lights and sockets circuits.</p></CardContent></Card> } else {
                    circuits = result.circuits;
                    <Card className="border border-violet-200/15 bg-[#140d22]/90"><CardContent className="overflow-x-auto p-4">
                        <svg viewBox="0 0 900 500" role="img" aria-label="Whole-home circuit sketch with 230 volt supply branching to rooms, lights and sockets" className="h-auto min-w-[680px] w-full">
                            <path d="M120 250 H225 M225 250 V100 H340 M225 250 H340 M225 250 V400 H340" fill="none" stroke="#67e8f9" strokeWidth="4" strokeLinecap="round" />
                            <circle cx="75" cy="250" r="48" fill="#211436" stroke="#67e8f9" strokeWidth="3"/><text x="75" y="244" fill="#e0f2fe" textAnchor="middle" fontSize="15">230 V</text><text x="75" y="266" fill="#c4b5fd" textAnchor="middle" fontSize="13">SUPPLY</text>
                            {for (room_index, room_name) in enumerate(room_names) {
                                y = 25 + room_index * 150;
                                lights_rating = "—";
                                sockets_rating = "—";
                                lights_warning = False;
                                sockets_warning = False;
                                for circuit in circuits {
                                    if circuit.room_name == room_name and circuit.circuit_name == "Lights" { lights_rating = str(circuit.suggested_rating) + " A"; lights_warning = circuit.trips; }
                                    if circuit.room_name == room_name and circuit.circuit_name == "Sockets" { sockets_rating = str(circuit.suggested_rating) + " A"; sockets_warning = circuit.trips; }
                                }
                                <g key={str(room_index)}>
                                    <rect x="340" y={str(y)} width="520" height="135" rx="10" fill="#10091d" stroke="#8b7aa8" strokeWidth="2"/>
                                    <text x="365" y={str(y + 23)} fill="#f5f3ff" fontSize="16" fontWeight="700">{room_name}</text>
                                    <path d={"M225 " + str(y + 67) + " H375 M375 " + str(y + 67) + " V" + str(y + 56) + " H410 M375 " + str(y + 67) + " V" + str(y + 102) + " H410"} fill="none" stroke="#a78bfa" strokeWidth="2"/>
                                    <rect x="410" y={str(y + 37)} width="185" height="42" rx="7" fill="#211436" stroke="#67e8f9" strokeWidth="2"/><text x="425" y={str(y + 55)} fill="#e0f2fe" fontSize="13">LIGHTS · MCB {lights_rating}</text><text x="425" y={str(y + 70)} fill={"#fda4af" if lights_warning else "#94a3b8"} fontSize="10">{"Overload warning" if lights_warning else "Suggested circuit"}</text>
                                    <rect x="625" y={str(y + 37)} width="205" height="42" rx="7" fill="#211436" stroke="#a78bfa" strokeWidth="2"/><text x="640" y={str(y + 55)} fill="#f5f3ff" fontSize="13">SOCKETS · MCB {sockets_rating}</text><text x="640" y={str(y + 70)} fill={"#fda4af" if sockets_warning else "#94a3b8"} fontSize="10">{"Overload warning" if sockets_warning else "Suggested circuit"}</text>
                                </g>
                            }}
                        </svg>
                    </CardContent></Card>
                }}
            </div>
            <p className="text-xs text-slate-500">Planning estimate only. Have a qualified electrician verify circuit design and protective-device sizing.</p>
        </section>
    </EnergyShell>;
}
