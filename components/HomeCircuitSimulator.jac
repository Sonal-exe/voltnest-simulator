import from "@jac/runtime" { Link }
import from .ui.card { Card, CardContent, CardHeader, CardTitle, CardDescription }
import from .ui.button { Button }
import from .EnergyShell { EnergyShell }
sv import from ..engine.circuits { Device, getApplianceLibrary }
sv import from ..engine.simulation { simulatePeriod }
sv import from ..engine.housePlan { HousePlan, parseHouseDescription }

def:pub HomeCircuitSimulator() -> JsxElement {
    has library: list[Device] = [];
    has room_names: list[str] = ["Living room"];
    has room_devices: list[list[dict]] = [[]];
    has room_name_input: str = "";
    has simulation_mode: str = "day";
    has price_input: str = "";
    has house_description: str = "";
    has plan: HousePlan | None = None;
    has plan_error: str = "";
    has parsing: bool = False;
    has watts_input: str = "";
    has hours_input: str = "";
    has pending_device: Device | None = None;
    has simulation_result: dict = {};
    has has_result: bool = False;
    has error_message: str = "";
    has loading: bool = True;

    async can with entry {
        library = await getApplianceLibrary();
        loading = False;
    }

    async def understand_house {
        if house_description.strip() == "" {
            plan_error = "Describe your rooms and appliances first.";
            plan = None;
        } else {
            parsing = True;
            plan_error = "";
            try {
                plan = await parseHouseDescription(house_description);
            } except Exception {
                plan = None;
                plan_error = "I could not understand that description. Try a sample house below.";
            }
            parsing = False;
        }
    }

    def edit_plan {
        if plan is not None {
            editable_text = "";
            for room in plan.rooms {
                editable_text = editable_text + room.name + " with ";
                for (index, item) in enumerate(room.devices) {
                    if index > 0 { editable_text = editable_text + ", "; }
                    editable_text = editable_text + str(item.count) + " " + item.name;
                }
                editable_text = editable_text + ". ";
            }
            house_description = editable_text.strip();
            plan = None;
        }
    }

    def accept_plan {
        if plan is not None {
            new_names: list[str] = [];
            new_devices: list[list[dict]] = [];
            for room in plan.rooms {
                new_names.append(room.name);
                devices: list[dict] = [];
                for item in room.devices {
                    for estimate in library {
                        if estimate.name == item.name {
                            for copy_index in range(item.count) {
                                devices.append({"name": estimate.name, "watts": estimate.watts, "start_minute": estimate.start_minute, "run_minutes": estimate.run_minutes, "duty_cycle": estimate.duty_cycle, "lights_only": estimate.lights_only});
                            }
                        }
                    }
                }
                new_devices.append(devices);
            }
            if len(new_names) > 0 {
                room_names = new_names;
                room_devices = new_devices;
                simulation_result = {};
                has_result = False;
                plan = None;
                plan_error = "";
            }
        }
    }

    def use_sample(description: str) { house_description = description; plan_error = ""; plan = None; }

    def add_room {
        name = room_name_input.strip();
        if name == "" { error_message = "Enter a room name first."; }
        else {
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
        if pending_device is None { error_message = "Choose an appliance from the library first."; }
        else {
            watts = float(watts_input);
            hours = float(hours_input);
            if watts <= 0.0 or hours <= 0.0 or hours > 24.0 { error_message = "Enter a wattage above zero and hours from 0 to 24."; }
            else {
                configured = {"name": pending_device.name, "watts": watts, "start_minute": pending_device.start_minute, "run_minutes": int(hours * 60.0), "duty_cycle": pending_device.duty_cycle, "lights_only": pending_device.lights_only};
                updated_rooms: list[list[dict]] = [];
                for (index, devices) in enumerate(room_devices) {
                    if index == room_index { updated_rooms = updated_rooms + [devices + [configured]]; }
                    else { updated_rooms = updated_rooms + [devices]; }
                }
                room_devices = updated_rooms;
                simulation_result = {};
                has_result = False;
                error_message = "";
            }
        }
    }

    async def run_simulation {
        has_devices = False;
        for devices in room_devices { if len(devices) > 0 { has_devices = True; } }
        if not has_devices { error_message = "Add an appliance to a room before simulating."; simulation_result = {};
                has_result = False; }
        else {
            unit_price = float(price_input) if price_input.strip() != "" else 0.0;
            simulation_result = await simulatePeriod(room_names, room_devices, simulation_mode, unit_price);
            has_result = True;
            error_message = "";
        }
    }

    def chart_bars() -> JsxElement {
        if simulation_mode == "day" {
            return <div className="flex h-48 w-full min-w-0 items-center justify-center overflow-hidden rounded-xl border border-violet-200/15 bg-[#0b0813]/90 p-2"><p className="text-xs text-slate-400">Daily load timeline is in the 24-hour view above.</p></div>;
        }
        bars: list[dict] = simulation_result["bars"] as list[dict];
        return <div className="grid grid-cols-3 gap-2 sm:grid-cols-6">
            {for (index, bar) in enumerate(bars) {
                kwh = bar["kwh"] as float;
                <div key={str(index)} className="rounded-lg border border-violet-200/10 bg-[#0d0917]/80 p-2 text-center">
                    <p className="text-[10px] text-slate-400">{str(bar["label"])}</p>
                    <p className="text-xs font-semibold text-cyan-200">{f"{kwh:.1f} kWh"}</p>
                </div>
            }}
        </div>;
    }

    def circuit_rows() -> JsxElement {
        circuits: list[dict] = simulation_result["circuits"] as list[dict];
        return <div className="flex flex-col gap-3 border-t border-violet-200/10 pt-4">
            <h3 className="font-medium text-slate-100">Suggested circuits</h3>
            {for (idx, circuit) in enumerate(circuits) {
                <div key={str(idx)} className="rounded-lg border border-violet-200/10 bg-[#0d0917]/80 p-3">
                    <p className="font-medium text-slate-100">{str(circuit["room_name"]) + " · " + str(circuit["circuit_name"])}</p>
                    <p className="text-sm text-cyan-200">{str(circuit["suggested_rating"]) + " A"}</p>
                    <p className="text-xs text-slate-400">{str(circuit["reason"])}</p>
                    {if circuit["trips"] as bool { <p className="text-xs font-semibold text-rose-300">Warning: switch trips at peak load.</p> }}
                </div>
            }}
        </div>;
    }

    def handle_house_description(e: ChangeEvent) { house_description = e.target.value; plan_error = ""; }
    def handle_room_name(e: ChangeEvent) { room_name_input = e.target.value; }
    def handle_watts(e: ChangeEvent) { watts_input = e.target.value; }
    def handle_hours(e: ChangeEvent) { hours_input = e.target.value; }
    def handle_price(e: ChangeEvent) { price_input = e.target.value; }
    def handle_mode(e: ChangeEvent) { simulation_mode = e.target.value; simulation_result = {};
                has_result = False; }

    return <EnergyShell current="simulator">
        <section className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-5 py-8 md:px-8 md:py-10">
            <div className="flex flex-col gap-2"><p className="text-xs font-semibold uppercase tracking-[0.24em] text-cyan-200/70">Energy predictor</p><h1 className="text-3xl font-semibold tracking-tight text-white">Build your home prediction</h1><p className="text-sm text-slate-400">Add rooms, choose appliances, and estimate a full day of electricity use.</p></div>
            <div className="grid gap-5 lg:grid-cols-2">
                <Card className="border border-violet-200/15 bg-[#140d22]/90 shadow-2xl shadow-violet-950/30 backdrop-blur-xl">
                    <CardHeader><CardTitle className="text-slate-100">Rooms and appliances</CardTitle><CardDescription className="text-slate-400">Appliance values begin as estimates. Adjust them to match your home.</CardDescription></CardHeader>
                    <CardContent className="flex flex-col gap-5">
                        <div className="flex flex-col gap-3 rounded-xl border border-violet-200/15 bg-gradient-to-br from-violet-500/10 to-cyan-400/5 p-4">
                            <label className="text-sm font-medium text-slate-100" htmlFor="house-description">Describe your home in plain English</label>
                            <textarea id="house-description" value={house_description} onChange={handle_house_description} placeholder="For example: 2 bedrooms with fans, kitchen with fridge and kettle" className="min-h-24 w-full resize-y rounded-lg border border-violet-200/15 bg-[#0a0711] p-3 text-sm text-slate-100 placeholder:text-slate-500" />
                            <Button onClick={understand_house} disabled={parsing} className="border border-cyan-200/20 bg-gradient-to-r from-violet-700 to-cyan-700 text-white">{"Understand my home" if not parsing else "Understanding…"}</Button>
                            {if plan_error != "" {
                                <p className="text-sm text-rose-300">{plan_error}</p><p className="text-xs text-slate-300">Try a sample house:</p>
                                <div className="flex flex-wrap gap-2">
                                    <Button variant="outline" onClick={lambda (_e: MouseEvent) { use_sample("2 bedrooms with fans, kitchen with fridge and kettle"); }}>Two bedrooms and kitchen</Button>
                                    <Button variant="outline" onClick={lambda (_e: MouseEvent) { use_sample("Living room with a TV and fan, kitchen with a fridge"); }}>Living room and kitchen</Button>
                                    <Button variant="outline" onClick={lambda (_e: MouseEvent) { use_sample("One bedroom with a fan and bulb, kitchen with a fridge and kettle"); }}>One bedroom home</Button>
                                </div>
                            }}
                            {if plan is not None {
                                <div className="flex flex-col gap-3 rounded-lg border border-cyan-200/20 bg-[#0a0711]/80 p-3">
                                    <p className="text-sm font-semibold text-cyan-100">{"I understood: " + plan.summary}</p>
                                    {for (room_index, room) in enumerate(plan.rooms) { <div key={str(room_index)} className="text-sm text-slate-200"><span className="font-medium">{room.name}</span><span className="text-slate-400">{": " + ", ".join([str(item.count) + " " + item.name for item in room.devices])}</span></div> }}
                                    <div className="flex gap-2"><Button onClick={accept_plan}>Accept</Button><Button variant="outline" onClick={edit_plan}>Edit</Button></div>
                                </div>
                            }}
                        </div>
                        <div className="flex flex-col gap-2 sm:flex-row"><input aria-label="New room name" value={room_name_input} onChange={handle_room_name} placeholder="Room name, for example Kitchen" className="h-10 min-w-0 flex-1 rounded-md border border-violet-200/15 bg-[#0a0711] px-3 text-sm text-slate-100" /><Button variant="outline" onClick={add_room}>Add room</Button></div>
                        {if loading { <p className="text-sm text-slate-400">Loading appliance library…</p> } else {
                            <div className="flex flex-col gap-2"><p className="text-sm font-medium text-slate-200">Appliance library</p><div className="grid grid-cols-2 gap-2 sm:grid-cols-3">{for (index, device) in enumerate(library) { <button key={str(index)} onClick={lambda (_e: MouseEvent) { choose_device(device); }} className="rounded-xl border border-violet-200/10 bg-[#0d0917]/80 px-3 py-2 text-left text-sm text-slate-100"><span className="block font-medium">{device.name}</span><span className="text-xs text-slate-400">{str(device.watts) + " W estimated"}</span></button> }}</div></div>
                        }}
                        {if pending_device is not None { <div className="flex flex-col gap-3 rounded-xl border border-violet-200/15 bg-violet-500/10 p-4"><p className="text-sm font-medium text-slate-100">{pending_device.name} values (Estimated)</p><div className="grid grid-cols-2 gap-3"><label className="flex flex-col gap-1 text-xs text-slate-400">Wattage (W)<input type="number" min="1" value={watts_input} onChange={handle_watts} /></label><label className="flex flex-col gap-1 text-xs text-slate-400">Hours each day<input type="number" min="0.25" max="24" step="0.25" value={hours_input} onChange={handle_hours} /></label></div></div> }}
                        {for (index, room_name) in enumerate(room_names) { <div key={str(index)} className="flex flex-col gap-2 rounded-xl border border-violet-200/10 bg-[#0d0917]/80 p-3"><h2 className="font-medium text-slate-100">{room_name}</h2>{if len(room_devices[index]) == 0 { <p className="text-sm text-slate-400">No appliances added yet.</p> } else { for device in room_devices[index] { <p key={str(device["name"])} className="text-sm text-slate-200">{str(device["name"]) + " · " + str(device["watts"]) + " W"}</p> } }}<Button variant="outline" onClick={lambda (_e: MouseEvent) { add_device(index); }}>Add selected appliance here</Button></div> }}
                        {if error_message != "" { <p className="text-sm text-rose-300">{error_message}</p> }}
                        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2"><label className="flex flex-col gap-1 text-xs text-slate-400">Time period<select value={simulation_mode} onChange={handle_mode} className="h-10 rounded-md border border-violet-200/15 bg-[#0a0711] px-3 text-sm text-slate-100"><option value="day">Day</option><option value="month">Month (30 days)</option><option value="year">Year</option></select></label><label className="flex flex-col gap-1 text-xs text-slate-400">Price per kWh (optional)<input type="number" min="0" step="0.01" value={price_input} onChange={handle_price} placeholder="Leave blank to skip cost" /></label></div>
                        <Button onClick={run_simulation}>Simulate</Button>
                    </CardContent>
                </Card>
                <Card className="border border-violet-200/15 bg-[#140d22]/90 shadow-2xl shadow-violet-950/30">
                    <CardHeader><CardTitle className="text-slate-100">{"Energy prediction · " + ("Day" if simulation_mode == "day" else "30-day month" if simulation_mode == "month" else "Year")}</CardTitle><CardDescription className="text-slate-400">{"15-minute load across one day" if simulation_mode == "day" else "Daily kWh across the 30-day month" if simulation_mode == "month" else "Monthly kWh across the year"}</CardDescription></CardHeader>
                    <CardContent className="flex flex-col gap-4">
                        {if not has_result { <div className="rounded-xl border border-dashed border-violet-200/20 bg-[#0d0917]/70 px-5 py-10 text-center"><p className="font-medium text-slate-100">No simulation yet</p><p className="mt-1 text-sm text-slate-400">Add an appliance and select Simulate to see your estimate.</p></div> } else {
                            total_kwh = simulation_result["total_kwh"] as float;
                            total_label = f"{total_kwh:.3f} kWh";
                            <p className="text-3xl font-semibold tabular-nums text-white">{total_label}</p>
                            chart_bars();
                            <p className="text-xs text-slate-400">{"Daily load in 15-minute steps" if simulation_mode == "day" else "Each bar is one " + ("day" if simulation_mode == "month" else "month") + " of estimated energy."}</p>
                            if simulation_result["estimated_cost"] { <p className="text-sm text-cyan-100">Estimated cost: {str(simulation_result["estimated_cost"])}</p> }
                            circuit_rows();
                        }}
                    </CardContent>
                </Card>
            </div>
        </section>
    </EnergyShell>;
}
