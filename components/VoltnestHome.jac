import from .ui.card { Card, CardContent, CardHeader, CardTitle, CardDescription }
import from .ui.button { Button }
import from "@jac/runtime" { Link }
sv import from ..engine.circuits { Device, getApplianceLibrary }
sv import from ..engine.simulation { ScheduleSimulationResult, simulateApplianceNames }

def:pub VoltnestHome() -> JsxElement {
    has library: list[Device] = [];
    has selected_names: list[str] = [];
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
            result = await simulateApplianceNames(selected_names);
            error_message = "";
        }
    }

    return <main className="min-h-svh bg-muted/40 text-foreground">
        <header className="border-b bg-background/90">
            <div className="mx-auto flex h-16 max-w-6xl items-center gap-3 px-6">
                <div className="flex size-9 items-center justify-center rounded-xl bg-primary text-primary-foreground shadow-sm">
                    <span className="text-lg font-bold">V</span>
                </div>
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
                    <CardHeader className="pb-3">
                        <CardTitle>Choose appliances</CardTitle>
                        <CardDescription>Select the appliances used in your home.</CardDescription>
                    </CardHeader>
                    <CardContent className="flex flex-col gap-2">
                        {if loading {
                            <p className="py-4 text-sm text-muted-foreground">Loading appliance choices…</p>
                        } else {
                            for (index, device) in enumerate(library) {
                                <button key={str(index)} onClick={lambda (_e: MouseEvent) { toggle_device(device.name); }} className="flex w-full items-center justify-between gap-3 rounded-lg border bg-background px-3 py-2.5 text-left transition-colors hover:bg-muted/50">
                                    <span className="flex items-center gap-3">
                                        <span className={"flex size-5 items-center justify-center rounded border text-xs " + ("border-primary bg-primary text-primary-foreground" if is_selected(device.name) else "border-input bg-background")}>
                                            {"✓" if is_selected(device.name) else ""}
                                        </span>
                                        <span className="text-sm font-medium">{device.name}</span>
                                    </span>
                                    <span className="text-xs text-muted-foreground">{str(device.watts) + " W"}</span>
                                </button>
                            }
                        }}
                        <Link to="/simulator" className="mt-2 flex h-10 w-full items-center justify-center rounded-md bg-primary px-4 text-sm font-medium text-primary-foreground shadow-sm hover:bg-primary/90">Build rooms and simulate</Link>
                    <Button onClick={run_simulation} className="w-full">{"Run 24-hour simulation"}</Button>
                        {if error_message != "" {
                            <p className="text-sm text-destructive">{error_message}</p>
                        }}
                    </CardContent>
                </Card>
            </div>
            <div className="flex flex-col gap-5">
                <Card className="relative overflow-hidden border-border/70 bg-card shadow-xl">
                    <CardHeader className="border-b bg-background/60">
                        <div className="flex items-center gap-3">
                            <div className="flex size-10 items-center justify-center rounded-xl bg-primary/10 text-primary"><span className="text-lg font-semibold">+</span></div>
                            <div><CardTitle>Home circuit</CardTitle><CardDescription>A simple view of how power travels</CardDescription></div>
                        </div>
                    </CardHeader>
                    <CardContent className="flex flex-col gap-5 p-6">
                        <div className="flex items-center justify-between gap-2">
                            <div className="rounded-xl border bg-background px-4 py-3 text-sm font-medium shadow-sm">Power source</div>
                            <div className="h-px flex-1 bg-primary/50" />
                            <div className="rounded-xl border bg-background px-4 py-3 text-sm font-medium shadow-sm">Appliances</div>
                        </div>
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
                            <div className="flex flex-col gap-1 border-t pt-3">
                                <p className="text-sm font-medium">Load by time</p>
                                {for (index, load) in enumerate(result.step_loads) {
                                    if load.watts > 0.0 {
                                        <div key={str(index)} className="flex items-center justify-between text-xs text-muted-foreground">
                                            <span>{f"{load.minute // 60:02d}:{load.minute % 60:02d}"}</span>
                                            <span>{f"{load.watts:.0f} W"}</span>
                                        </div>
                                    }
                                }}
                            </div>
                        </CardContent>
                    </Card>
                }}
            </div>
        </section>
        <footer className="mx-auto max-w-6xl px-6 pb-8 text-xs text-muted-foreground">Learn home circuits with confidence.</footer>
    </main>;
}
