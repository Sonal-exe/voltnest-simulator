import from .ui.button { Button }
import from "@jac/runtime" { Link }
import from .ui.card { Card, CardContent, CardHeader, CardTitle, CardDescription }
import from .EnergyShell { EnergyShell }
sv import from ..engine.circuits { Device, getApplianceLibrary }
sv import from ..engine.simulation { ScheduleSimulationResult, StepLoad, simulateApplianceData }

def:pub VoltnestHome() -> JsxElement {
    has library: list[Device] = [];
    has selected_names: list[str] = [];
    has watt_values: dict = {};
    has duty_values: dict = {};
    has result: ScheduleSimulationResult | None = None;
    has error_message: str = "";
    has loading: bool = True;

    async can with entry {
        library = await getApplianceLibrary();
        loading = False;
    }

    def is_selected(device_name: str) -> bool {
        for selected_name in selected_names {
            if selected_name == device_name { return True; }
        }
        return False;
    }

    def watts_for(device: Device) -> float {
        if device.name in watt_values { return watt_values[device.name] as float; }
        return device.watts;
    }

    def duty_for(device: Device) -> float {
        if device.name in duty_values { return duty_values[device.name] as float; }
        return device.duty_cycle;
    }

    def handle_watts(device_name: str, e: ChangeEvent) {
        watts = float(e.target.value);
        watt_values = {**watt_values, device_name: watts};
        result = None;
    }

    def handle_duty(device_name: str, e: ChangeEvent) {
        duty = float(e.target.value) / 100.0;
        duty_values = {**duty_values, device_name: duty};
        result = None;
    }

    def load_points(loads: list[StepLoad]) -> str {
        peak_watts: float = 1.0;
        for load in loads {
            if load.watts > peak_watts { peak_watts = load.watts; }
        }
        points = "";
        for hour in range(24) {
            load = loads[hour * 4];
            x = hour * 12;
            y = 100.0 - (load.watts / peak_watts * 80.0);
            point = str(x) + "," + f"{y:.1f}";
            points = points + (" " if hour > 0 else "") + point;
        }
        return points;
    }

    def toggle_device(device_name: str) {
        exists = False;
        for selected_name in selected_names {
            if selected_name == device_name { exists = True; }
        }
        if exists {
            selected_names = [item for item in selected_names if item != device_name];
        } else {
            selected_names = selected_names + [device_name];
        }
        result = None;
        error_message = "";
    }

    async def run_simulation {
        if len(selected_names) == 0 {
            error_message = "Choose at least one appliance to run the simulation.";
            result = None;
        } else {
            appliances: list[dict] = [];
            for device in library {
                if is_selected(device.name) {
                    appliances.append({"name": device.name, "watts": watts_for(device), "duty_cycle": duty_for(device)});
                }
            }
            result = await simulateApplianceData(appliances);
            error_message = "";
        }
    }

    return <EnergyShell current="home">
        <section className="mx-auto grid max-w-6xl items-start gap-8 px-5 py-8 md:px-8 md:py-12 lg:grid-cols-2">
            <div className="mb-1 flex flex-col gap-2 lg:col-span-2">
                <p className="text-xs font-semibold uppercase tracking-[0.24em] text-cyan-200/70">Energy predictor</p>
                <h1 className="text-3xl font-semibold tracking-tight text-white md:text-4xl">Understand your home’s energy</h1>
                <p className="text-sm text-slate-400">Choose appliances, adjust estimates, and explore a full day of electricity use.</p>
            </div>
            <div className="flex flex-col items-start gap-6">
                <div className="flex flex-wrap items-center gap-3">
                    <span className="rounded-full border border-cyan-300/20 bg-cyan-300/10 px-3 py-1 text-xs font-medium text-cyan-100">Live energy workspace</span>
                    <span className="text-sm text-slate-400">Plain-language predictions for everyday homes.</span>
                </div>
                <Card className="w-full border-violet-200/15 bg-[#140d22]/90 shadow-2xl shadow-violet-950/30 backdrop-blur-xl">
                    <CardHeader className="pb-3"><CardTitle className="text-slate-100">Energy predictor</CardTitle><CardDescription className="text-slate-400">Estimated power and duty cycle are editable for each appliance.</CardDescription></CardHeader>
                    <CardContent className="flex flex-col gap-2">
                        {if loading {
                            <p className="py-4 text-sm text-muted-foreground">Loading appliance choices…</p>
                        } else {
                            for (index, device) in enumerate(library) {
                                <div key={str(index)} className="flex flex-col gap-2 rounded-xl border border-violet-200/10 bg-[#0d0917]/80 px-3 py-2.5 shadow-md shadow-black/20 transition-all duration-300 hover:border-cyan-200/30 hover:bg-violet-950/30">
                                    <button onClick={lambda (_e: MouseEvent) { toggle_device(device.name); }} className="flex w-full items-center justify-between gap-3 text-left">
                                        <span className="flex items-center gap-3">
                                            <span className={"flex size-5 items-center justify-center rounded border text-xs " + ("border-cyan-200 bg-cyan-300 text-[#10091d] shadow-[0_0_14px_rgba(103,232,249,0.45)]" if is_selected(device.name) else "border-violet-200/20 bg-[#0a0711]")}>{"✓" if is_selected(device.name) else ""}</span>
                                            <span className="text-sm font-medium text-slate-100">{device.name}</span>
                                        </span>
                                        <span className="text-xs text-cyan-100/60">{str(device.watts) + " W estimated"}</span>
                                    </button>
                                    {if is_selected(device.name) {
                                        <div className="grid grid-cols-2 gap-2 border-t pt-2">
                                            <label className="flex flex-col gap-1 text-xs text-muted-foreground">Power (W)
                                                <input aria-label={device.name + " estimated power in watts"} type="number" min="1" value={str(watts_for(device))} onChange={lambda (e: ChangeEvent) { handle_watts(device.name, e); }} className="h-9 min-w-0 rounded-md border border-violet-200/15 bg-[#0a0711] px-2 text-sm text-slate-100 focus:border-cyan-300/50 focus:outline-none" />
                                            </label>
                                            <label className="flex flex-col gap-1 text-xs text-muted-foreground">Duty cycle (%)
                                                <input aria-label={device.name + " duty cycle percentage"} type="number" min="0" max="100" step="1" value={str(duty_for(device) * 100.0)} onChange={lambda (e: ChangeEvent) { handle_duty(device.name, e); }} className="h-9 min-w-0 rounded-md border border-violet-200/15 bg-[#0a0711] px-2 text-sm text-slate-100 focus:border-cyan-300/50 focus:outline-none" />
                                            </label>
                                        </div>
                                    }}
                                </div>
                            }
                        }}
                        <Link to="/simulator" className="mt-2 flex h-10 w-full items-center justify-center rounded-md bg-primary px-4 text-sm font-medium text-primary-foreground shadow-sm hover:bg-primary/90">Build rooms and simulate</Link>
                        <Button onClick={run_simulation} className="w-full border border-cyan-200/20 bg-gradient-to-r from-violet-700 via-violet-600 to-cyan-700 text-white shadow-lg shadow-violet-950/30 transition-all duration-300 hover:-translate-y-0.5 hover:from-violet-600 hover:to-cyan-600">Run 24-hour simulation</Button>
                        {if error_message != "" { <p className="text-sm text-destructive">{error_message}</p> }}
                    </CardContent>
                </Card>
            </div>
            <div className="flex flex-col gap-5">
                <Card className="relative overflow-hidden border-violet-200/15 bg-[#140d22]/90 shadow-2xl shadow-violet-950/30 backdrop-blur-xl">
                    <CardHeader className="border-b border-white/10 bg-white/[0.03]"><div className="flex items-center gap-3"><div className="flex size-10 items-center justify-center rounded-xl border border-cyan-200/20 bg-gradient-to-br from-violet-400/20 to-cyan-300/10 text-cyan-200"><span className="text-lg font-semibold">⌁</span></div><div><CardTitle className="text-slate-100">Energy pathway</CardTitle><CardDescription className="text-slate-400">A simple view of estimated energy flow</CardDescription></div></div></CardHeader>
                    <CardContent className="flex flex-col gap-5 p-6">
                        <div className="flex items-center justify-between gap-2"><div className="rounded-xl border border-violet-200/15 bg-[#0d0917] px-4 py-3 text-sm font-medium text-slate-100 shadow-sm">Power source</div><div className="h-px flex-1 bg-gradient-to-r from-violet-400 to-cyan-300" /><div className="rounded-xl border border-cyan-200/20 bg-[#0d0917] px-4 py-3 text-sm font-medium text-slate-100 shadow-sm">Appliances</div></div>
                        <div className="rounded-xl border border-white/5 bg-white/[0.04] p-4 text-sm leading-relaxed text-slate-300">Your energy estimate follows power from its source through the appliances in your home.</div>
                        <div className="flex items-center gap-2 text-xs text-slate-400"><span className="size-2 rounded-full bg-cyan-300 shadow-[0_0_10px_#67e8f9]" />Energy estimates use your appliance settings</div>
                    </CardContent>
                </Card>
                {if result is not None {
                    <Card className="border border-violet-200/15 bg-[#140d22]/90 shadow-2xl shadow-violet-950/30 backdrop-blur-xl">
                        <CardHeader><CardTitle className="text-slate-100">Daily energy use</CardTitle><CardDescription className="text-slate-400">{str(len(selected_names)) + " appliances over 24 hours"}</CardDescription></CardHeader>
                        <CardContent className="flex flex-col gap-3">
                            <p className="text-3xl font-semibold tabular-nums">{f"{result.total_kwh:.3f} kWh"}</p>
                            <p className="text-sm text-muted-foreground">Total electricity used in one day</p>
                            <div className="flex flex-col gap-3 border-t pt-3">
                                <div className="flex items-center justify-between gap-3"><p className="text-sm font-medium">Load by time</p><p className="text-xs text-cyan-100/60">Hourly estimate, W</p></div>
                                <div className="rounded-xl border border-violet-200/15 bg-[#0b0813]/90 px-3 pt-3 pb-2">
                                    <svg viewBox="0 0 276 110" role="img" aria-label="Hourly electricity load line graph" className="h-32 w-full overflow-visible">
                                        <path d="M0 100 H276" fill="none" stroke="currentColor" className="text-violet-200/25" stroke-width="1" />
                                        <path d="M0 55 H276" fill="none" stroke="currentColor" className="text-border/60" stroke-width="1" stroke-dasharray="3 4" />
                                        <path d={"M" + load_points(result.step_loads).replace(" ", " L")} fill="none" stroke="currentColor" className="text-primary" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" pathLength="100" style={{"strokeDasharray": "100", "strokeDashoffset": "0", "transition": "stroke-dashoffset 900ms ease-out"}} />
                                    </svg>
                                    <div className="flex justify-between px-1 text-[10px] text-muted-foreground"><span>00:00</span><span>06:00</span><span>12:00</span><span>18:00</span><span>24:00</span></div>
                                </div>
                            </div>
                        </CardContent>
                    </Card>
                }}
            </div>
        </section>
        <footer className="mx-auto max-w-6xl px-6 pb-8 text-xs text-slate-500">Learn home circuits with confidence.</footer>
    </EnergyShell>;
}
