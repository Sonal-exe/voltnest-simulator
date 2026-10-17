import from "@jac/runtime" { Link }
import from .ui.card { Card, CardContent, CardHeader, CardTitle, CardDescription }
import from .ui.button { Button }
sv import from ..engine.circuits { Device, getApplianceLibrary }
sv import from ..engine.simulation { ScheduleSimulationResult, simulateRoomData }

def:pub HomeCircuitSimulator() -> JsxElement {
    has library: list[Device] = [];
    has room_names: list[str] = ["Living room"];
    has room_devices: list[list[dict]] = [[]];
    has room_name_input: str = "";
    has watts_input: str = "";
    has hours_input: str = "";
    has pending_device: Device | None = None;
    has result: ScheduleSimulationResult | None = None;
    has error_message: str = "";
    has loading: bool = True;

    async can with entry {
        library = await getApplianceLibrary();
        loading = False;
    }

    def add_room {
        name = room_name_input.strip();
        if name == "" {
            error_message = "Enter a room name first.";
        } else {
            room_names = room_names + [name];
            room_devices = room_devices + [[]];
            room_name_input = "";
            error_message = "";
        }
    }

    def choose_device(device: Device) {
        pending_device = device;
        watts_input = str(device.watts);
        hours_input = "5.0" if device.lights_only else str(device.run_minutes / 60.0);
        error_message = "";
    }

    def add_device(room_index: int) {
        if pending_device is None {
            error_message = "Choose an appliance from the library first.";
        } else {
            watts = float(watts_input);
            hours = float(hours_input);
            if watts <= 0.0 or hours <= 0.0 or hours > 24.0 {
                error_message = "Enter a wattage above zero and hours from 0 to 24.";
            } else {
                configured = {
                    "name": pending_device.name,
                    "watts": watts,
                    "start_minute": pending_device.start_minute,
                    "run_minutes": int(hours * 60.0),
                    "duty_cycle": pending_device.duty_cycle,
                    "lights_only": pending_device.lights_only
                };
                updated_rooms: list[list[dict]] = [];
                for (index, devices) in enumerate(room_devices) {
                    if index == room_index {
                        updated_rooms = updated_rooms + [devices + [configured]];
                    } else {
                        updated_rooms = updated_rooms + [devices];
                    }
                }
                room_devices = updated_rooms;
                result = None;
                error_message = "";
            }
        }
    }

    async def run_simulation {
        has_devices = False;
        for devices in room_devices {
            if len(devices) > 0 { has_devices = True; }
        }
        if not has_devices {
            error_message = "Add an appliance to a room before simulating.";
            result = None;
        } else {
            result = await simulateRoomData(room_names, room_devices);
            error_message = "";
        }
    }

    def handle_room_name(e: ChangeEvent) { room_name_input = e.target.value; }
    def handle_watts(e: ChangeEvent) { watts_input = e.target.value; }
    def handle_hours(e: ChangeEvent) { hours_input = e.target.value; }

    return <main className="min-h-svh bg-muted/40 text-foreground">
        <header className="border-b bg-background/90">
            <div className="mx-auto flex h-16 max-w-6xl items-center gap-3 px-6">
                <div className="flex size-9 items-center justify-center rounded-xl bg-primary text-primary-foreground shadow-sm"><span className="text-lg font-bold">V</span></div>
                <span className="text-2xl font-bold tracking-tight">Voltnest</span>
                <Link to="/" className="ml-auto text-sm text-muted-foreground hover:text-foreground">Home</Link>
            </div>
        </header>
        <section className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-6 py-10">
            <div className="flex flex-col gap-2">
                <h1 className="text-3xl font-semibold tracking-tight">Build your home simulation</h1>
                <p className="text-sm text-muted-foreground">Add rooms, choose appliances, and estimate a full day's electricity use.</p>
            </div>
            <div className="grid gap-5 lg:grid-cols-2">
                <Card className="shadow-sm">
                    <CardHeader><CardTitle>Rooms and appliances</CardTitle><CardDescription>Appliance values begin as estimates. Adjust them to match your home.</CardDescription></CardHeader>
                    <CardContent className="flex flex-col gap-5">
                        <div className="flex flex-col gap-2 sm:flex-row">
                            <input aria-label="New room name" value={room_name_input} onChange={handle_room_name} placeholder="Room name, for example Kitchen" className="h-10 min-w-0 flex-1 rounded-md border border-input bg-background px-3 text-sm" />
                            <Button variant="outline" onClick={add_room}>Add room</Button>
                        </div>
                        {if loading {
                            <p className="text-sm text-muted-foreground">Loading appliance library…</p>
                        } else {
                            <div className="flex flex-col gap-2">
                                <p className="text-sm font-medium">Appliance library</p>
                                <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
                                    {for (index, device) in enumerate(library) {
                                        <button key={str(index)} onClick={lambda (_e: MouseEvent) { choose_device(device); }} className="rounded-lg border bg-background px-3 py-2 text-left text-sm transition-colors hover:bg-muted/60">
                                            <span className="block font-medium">{device.name}</span>
                                            <span className="text-xs text-muted-foreground">{str(device.watts) + " W estimated"}</span>
                                        </button>
                                    }}
                                </div>
                            </div>
                        }}
                        {if pending_device is not None {
                            <div className="flex flex-col gap-3 rounded-lg border bg-muted/30 p-4">
                                <p className="text-sm font-medium">{pending_device.name} values (Estimated)</p>
                                <div className="grid grid-cols-2 gap-3">
                                    <label className="flex flex-col gap-1 text-xs text-muted-foreground">Wattage (W)
                                        <input type="number" min="1" value={watts_input} onChange={handle_watts} className="h-10 rounded-md border border-input bg-background px-3 text-sm text-foreground" />
                                    </label>
                                    <label className="flex flex-col gap-1 text-xs text-muted-foreground">Hours each day
                                        <input type="number" min="0.25" max="24" step="0.25" value={hours_input} onChange={handle_hours} className="h-10 rounded-md border border-input bg-background px-3 text-sm text-foreground" />
                                    </label>
                                </div>
                            </div>
                        }}
                        {for (index, room_name) in enumerate(room_names) {
                            <div key={str(index)} className="flex flex-col gap-2 rounded-lg border bg-background p-3">
                                <h2 className="font-medium">{room_name}</h2>
                                {if len(room_devices[index]) == 0 {
                                    <p className="text-sm text-muted-foreground">No appliances added yet.</p>
                                } else {
                                    for device in room_devices[index] {
                                        <p key={str(device["name"])} className="text-sm">{str(device["name"]) + " · " + str(device["watts"]) + " W · " + str(device["run_minutes"]) + " minutes (Estimated)"}</p>
                                    }
                                }}
                                <Button variant="outline" onClick={lambda (_e: MouseEvent) { add_device(index); }}>Add selected appliance here</Button>
                            </div>
                        }}
                        {if error_message != "" { <p className="text-sm text-destructive">{error_message}</p> }}
                        <Button onClick={run_simulation}>Simulate</Button>
                    </CardContent>
                </Card>
                <Card className="shadow-sm">
                    <CardHeader><CardTitle>Daily load</CardTitle><CardDescription>Estimated power use in each 15-minute step</CardDescription></CardHeader>
                    <CardContent className="flex flex-col gap-4">
                        {if result is None {
                            <div className="rounded-xl border border-dashed bg-background px-5 py-10 text-center">
                                <p className="font-medium">No simulation yet</p>
                                <p className="mt-1 text-sm text-muted-foreground">Add an appliance and select Simulate to see daily load.</p>
                            </div>
                        } else {
                            <p className="text-3xl font-semibold tabular-nums">{f"{result.total_kwh:.3f} kWh"}</p>
                            <div className="flex h-48 items-end gap-1 overflow-x-auto rounded-lg border bg-background p-3">
                                {for (index, load) in enumerate(result.step_loads) {
                                    max_watts = 1.0;
                                    for each_load in result.step_loads {
                                        if each_load.watts > max_watts { max_watts = each_load.watts; }
                                    }
                                    bar_height = 100.0 * load.watts / max_watts;
                                    <div key={str(index)} title={f"{load.minute // 60:02d}:{load.minute % 60:02d} · {load.watts:.0f} W"} className="min-w-1 flex-1 rounded-t-sm bg-primary/80" style={{"height": f"{bar_height:.0f}%"}} />
                                }}
                            </div>
                            <div className="flex justify-between text-xs text-muted-foreground"><span>00:00</span><span>06:00</span><span>12:00</span><span>18:00</span><span>24:00</span></div>
                            <p className="text-xs text-muted-foreground">Each bar shows the estimated load for 15 minutes.</p>
                        }}
                    </CardContent>
                </Card>
            </div>
        </section>
    </main>;
}
