import from .ui.card { Card, CardContent, CardHeader, CardTitle, CardDescription }
import from .EnergyShell { EnergyShell }
sv import from ..engine.simulation { ScheduleSimulationResult, CircuitAdvice, simulateRoomData }

def:pub CircuitDesigner() -> JsxElement {
    has circuits: list[CircuitAdvice] = [];
    has message: str = "Set up rooms and appliances in Energy Predictor, then load your layout here.";
    has room_names: list[str] = ["Kitchen", "Bedroom"];
    has room_devices: list[list[dict]] = [
        [
            {"name": "Bulb", "watts": 10.0, "start_minute": 1080, "run_minutes": 300, "duty_cycle": 1.0, "lights_only": True},
            {"name": "Fridge", "watts": 150.0, "start_minute": 0, "run_minutes": 1440, "duty_cycle": 0.4, "lights_only": False},
            {"name": "Kettle", "watts": 1500.0, "start_minute": 720, "run_minutes": 20, "duty_cycle": 1.0, "lights_only": False}
        ],
        [
            {"name": "Bulb", "watts": 10.0, "start_minute": 1080, "run_minutes": 300, "duty_cycle": 1.0, "lights_only": True},
            {"name": "Fan", "watts": 60.0, "start_minute": 0, "run_minutes": 1440, "duty_cycle": 1.0, "lights_only": False},
            {"name": "AC", "watts": 1200.0, "start_minute": 0, "run_minutes": 1440, "duty_cycle": 1.0, "lights_only": False}
        ]
    ];

    async def build_diagram {
        saved = localStorage.getItem("voltnest_circuit_rooms");
        if saved {
            parsed = JSON.parse(saved);
            room_names = parsed["names"] as list[str];
            room_devices = parsed["devices"] as list[list[dict]];
            simulation = await simulateRoomData(room_names, room_devices);
            circuits = simulation.circuits;
            message = "Circuit diagram refreshed from your saved room loads.";
        } else {
            simulation = await simulateRoomData(room_names, room_devices);
            circuits = simulation.circuits;
            message = "Showing an example layout. Set up rooms and appliances in Energy Predictor, then refresh.";
        }
    }

    return <EnergyShell current="circuits">
        <section className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-5 py-8 md:px-8 md:py-10">
            <div className="flex flex-col gap-2">
                <p className="text-xs font-semibold uppercase tracking-[0.24em] text-cyan-200/70">Electrical planning</p>
                <h1 className="text-3xl font-semibold tracking-tight text-white md:text-4xl">Circuit Designer</h1>
                <p className="text-sm text-slate-400">See how each room’s loads are grouped and which MCB rating is suggested.</p>
            </div>
            <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-violet-200/15 bg-[#140d22]/80 p-4">
                <div><p className="font-medium text-slate-100">Circuit diagram</p><p className="text-xs text-slate-400">Lights share one circuit per room, sockets share one circuit, and heavy appliances have dedicated circuits.</p></div>
                <button onClick={build_diagram} className="rounded-lg border border-cyan-200/20 bg-gradient-to-r from-violet-700 to-cyan-700 px-4 py-2 text-sm font-medium text-white transition-all hover:-translate-y-0.5">Refresh diagram</button>
            </div>
            {if message != "" { <p className="text-sm text-cyan-200">{message}</p> }}
            {if len(circuits) == 0 {
                <Card className="border border-violet-200/15 bg-[#140d22]/90"><CardContent className="py-12 text-center"><p className="font-medium text-slate-100">No circuits to draw yet</p><p className="mt-2 text-sm text-slate-400">Load a saved home setup using Refresh diagram.</p></CardContent></Card>
            } else {
                <div className="grid gap-5 xl:grid-cols-2">
                    {for (circuit_index, circuit) in enumerate(circuits) {
                        <Card key={str(circuit_index)} className="overflow-hidden border border-violet-200/15 bg-[#140d22]/90 shadow-xl shadow-violet-950/20">
                            <CardHeader className="border-b border-white/10 bg-white/[0.03]">
                                <div className="flex flex-wrap items-start justify-between gap-3">
                                    <div><CardTitle className="text-slate-100">{circuit.room_name + " · " + circuit.circuit_name}</CardTitle><CardDescription className="text-slate-400">Peak {f"{circuit.peak_watts:.0f}"} W · {f"{circuit.peak_current:.2f}"} A at 230 V</CardDescription></div>
                                    <span className="rounded-full border border-cyan-200/20 bg-cyan-300/10 px-3 py-1 text-sm font-semibold text-cyan-100">MCB {str(circuit.suggested_rating)} A</span>
                                </div>
                            </CardHeader>
                            <CardContent className="flex flex-col gap-4 p-4">
                                <div className="overflow-x-auto rounded-xl border border-violet-200/10 bg-[#0b0813]/90 p-3">
                                    <svg viewBox="0 0 620 190" role="img" aria-label={circuit.room_name + " " + circuit.circuit_name + " circuit diagram"} className="h-44 min-w-[500px] w-full">
                                        <path d="M110 92 H205 M310 92 H380 M450 92 H500" fill="none" stroke="#a78bfa" strokeWidth="4" strokeLinecap="round" />
                                        <circle cx="62" cy="92" r="38" fill="#211436" stroke="#a78bfa" strokeWidth="3" />
                                        <text x="62" y="88" fill="#e9d5ff" textAnchor="middle" fontSize="13">SUPPLY</text>
                                        <text x="62" y="106" fill="#c4b5fd" textAnchor="middle" fontSize="12">230 V</text>
                                        <rect x="205" y="55" width="105" height="74" rx="12" fill="#211436" stroke="#67e8f9" strokeWidth="3" />
                                        <text x="257" y="82" fill="#e0f2fe" textAnchor="middle" fontSize="13">MCB</text>
                                        <text x="257" y="105" fill="#67e8f9" textAnchor="middle" fontSize="17" fontWeight="700">{str(circuit.suggested_rating) + " A"}</text>
                                        <rect x="380" y="48" width="145" height="88" rx="14" fill="#171126" stroke="#7c3aed" strokeWidth="2" />
                                        <text x="452" y="78" fill="#f5f3ff" textAnchor="middle" fontSize="13">{circuit.circuit_name}</text>
                                        <text x="452" y="101" fill="#c4b5fd" textAnchor="middle" fontSize="12">{circuit.room_name}</text>
                                        <text x="452" y="120" fill="#94a3b8" textAnchor="middle" fontSize="11">{f"{circuit.peak_watts:.0f} W peak"}</text>
                                        <circle cx="565" cy="92" r="20" fill="#0d0917" stroke="#67e8f9" strokeWidth="3" />
                                        <path d="M555 92 H575 M565 82 V102" stroke="#67e8f9" strokeWidth="2" />
                                    </svg>
                                </div>
                                <p className="text-sm text-slate-300">{circuit.reason}</p>
                                {if circuit.trips {
                                    <div className="rounded-lg border border-rose-300/30 bg-rose-500/10 px-3 py-2 text-sm font-medium text-rose-200">Warning: switch trips at peak load. The peak current exceeds the suggested MCB rating.</div>
                                } else {
                                    <div className="rounded-lg border border-cyan-300/20 bg-cyan-400/5 px-3 py-2 text-sm text-cyan-100">Within suggested MCB rating at the estimated peak.</div>
                                }}
                            </CardContent>
                        </Card>
                    }}
                </div>
            }}
        </section>
    </EnergyShell>;
}
