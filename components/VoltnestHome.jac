import from .ui.button { Button }
import from "@jac/runtime" { Link }
import from .ui.card { Card, CardContent, CardHeader, CardTitle, CardDescription }
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

    return <main className="min-h-svh bg-muted/40 text-foreground">
        <header className="border-b bg-background/90">
            <div className="mx-auto flex h-16 max-w-6xl items-center gap-3 px-6">
                <div className="flex size-9 items-center justify-center rounded-xl bg-primary text-primary-foreground shadow-sm"><span className="text-lg font-bold">V</span></div>
                <span className="text-2xl font-bold tracking-tight">Voltnest</span>
                <span className="ml-auto hidden text-sm text-muted-foreground sm:block">Home circuit simulator</span>
            </div>
        </header>
        <section className="mx-auto grid max-w-6xl items-center gap-12 px-6 py-12 md:py-16 lg:grid-cols-2">
            <div className="flex flex-col items-start gap-6">
                <span className="rounded-full border bg-card px-3 py-1 text-sm text-muted-foreground">Made for curious homeowners</span>
                <h1 className="text-balance text-4xl font-semibold leading-[1.1] tracking-tight md:text-5xl">Voltnest home Circuit Simulator</h1>
                <p className="max-w-xl text-lg leading-relaxed text-muted-foreground">Explore how everyday home circuits fit together, explained in clear, simple words.</p>
                <div className="flex flex-wrap items-center gap-3">
                    <span className="rounded-lg bg-primary px-5 py-3 text-sm font-medium text-primary-foreground shadow-sm">Your workspace is ready</span>
                    <span className="text-sm text-muted-foreground">Start with the basics, at your own pace.</span>
                </div>
                <Card className="w-full border-border/70 bg-card shadow-sm">
                    <CardHeader className="pb-3"><CardTitle>Choose appliances</CardTitle><CardDescription>Select appliances. Estimated power and duty-cycle values are editable.</CardDescription></CardHeader>
                    <CardContent className="flex flex-col gap-2">
                        {if loading {
                            <p className="py-4 text-sm text-muted-foreground">Loading appliance choices…</p>
                        } else {
                            for (index, device) in enumerate(library) {
                                <div key={str(index)} className="flex flex-col gap-2 rounded-lg border bg-background px-3 py-2.5">
                                    <button onClick={lambda (_e: MouseEvent) { toggle_device(device.name); }} className="flex w-full items-center justify-between gap-3 text-left">
                                        <span className="flex items-center gap-3">
                                            <span className={"flex size-5 items-center justify-center rounded border text-xs " + ("border-primary bg-primary text-primary-foreground" if is_selected(device.name) else "border-input bg-background")}>{"✓" if is_selected(device.name) else ""}</span>
                                            <span className="text-sm font-medium">{device.name}</span>
                                        </span>
                                        <span className="text-xs text-muted-foreground">{str(device.watts) + " W estimated"}</span>
                                    </button>
                                    {if is_selected(device.name) {
                                        <div className="grid grid-cols-2 gap-2 border-t pt-2">
                                            <label className="flex flex-col gap-1 text-xs text-muted-foreground">Power (W)
                                                <input aria-label={device.name + " estimated power in watts"} type="number" min="1" value={str(watts_for(device))} onChange={lambda (e: ChangeEvent) { handle_watts(device.name, e); }} className="h-9 min-w-0 rounded-md border border-input bg-background px-2 text-sm text-foreground" />
                                            </label>
                                            <label className="flex flex-col gap-1 text-xs text-muted-foreground">Duty cycle (%)
                                                <input aria-label={device.name + " duty cycle percentage"} type="number" min="0" max="100" step="1" value={str(duty_for(device) * 100.0)} onChange={lambda (e: ChangeEvent) { handle_duty(device.name, e); }} className="h-9 min-w-0 rounded-md border border-input bg-background px-2 text-sm text-foreground" />
                                            </label>
                                        </div>
                                    }}
                                </div>
                            }
                        }}
                        <Link to="/simulator" className="mt-2 flex h-10 w-full items-center justify-center rounded-md bg-primary px-4 text-sm font-medium text-primary-foreground shadow-sm hover:bg-primary/90">Build rooms and simulate</Link>
                        <Button onClick={run_simulation} className="w-full">Run 24-hour simulation</Button>
                        {if error_message != "" { <p className="text-sm text-destructive">{error_message}</p> }}
                    </CardContent>
                </Card>
            </div>
            <div className="flex flex-col gap-5">
                <Card className="relative overflow-hidden border-border/70 bg-card shadow-xl">
                    <CardHeader className="border-b bg-background/60"><div className="flex items-center gap-3"><div className="flex size-10 items-center justify-center rounded-xl bg-primary/10 text-primary"><span className="text-lg font-semibold">+</span></div><div><CardTitle>Home circuit</CardTitle><CardDescription>A simple view of how power travels</CardDescription></div></div></CardHeader>
                    <CardContent className="flex flex-col gap-5 p-6">
                        <div className="flex items-center justify-between gap-2"><div className="rounded-xl border bg-background px-4 py-3 text-sm font-medium shadow-sm">Power source</div><div className="h-px flex-1 bg-primary/50" /><div className="rounded-xl border bg-background px-4 py-3 text-sm font-medium shadow-sm">Appliances</div></div>
                        <div className="rounded-xl bg-muted/60 p-4 text-sm leading-relaxed text-muted-foreground">A circuit is a path that lets electricity travel from a power source to something useful, like a light.</div>
                        <div className="flex items-center gap-2 text-xs text-muted-foreground"><span className="size-2 rounded-full bg-primary" />Plain-language learning workspace</div>
                    </CardContent>
                </Card>
                {if result is not None {
                    <Card className="shadow-sm">
                        <CardHeader><CardTitle>Daily energy use</CardTitle><CardDescription>{str(len(selected_names)) + " appliances over 24 hours"}</CardDescription></CardHeader>
                        <CardContent className="flex flex-col gap-3">
                            <p className="text-3xl font-semibold tabular-nums">{f"{result.total_kwh:.3f} kWh"}</p>
                            <p className="text-sm text-muted-foreground">Total electricity used in one day</p>
                            <div className="flex flex-col gap-3 border-t pt-3">
                                <div className="flex items-center justify-between gap-3"><p className="text-sm font-medium">Load by time</p><p className="text-xs text-muted-foreground">Hourly estimate, W</p></div>
                                <div className="rounded-lg border bg-background px-3 pt-3 pb-2">
                                    <svg viewBox="0 0 276 110" role="img" aria-label="Hourly electricity load line graph" className="h-32 w-full overflow-visible">
                                        <path d="M0 100 H276" fill="none" stroke="currentColor" className="text-border" stroke-width="1" />
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
        <footer className="mx-auto max-w-6xl px-6 pb-8 text-xs text-muted-foreground">Learn home circuits with confidence.</footer>
    </main>;
}
