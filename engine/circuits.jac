obj CircuitComponent {
    has name: str = "Component";
    has kind: str = "part";
}

obj Circuit {
    has name: str = "Untitled circuit";
    has components: list[CircuitComponent] = [];
}

obj Device {
    has name: str;
    has watts: float;
    has start_minute: int = 0;
    has run_minutes: int = 1440;
    has duty_cycle: float = 1.0;
    has lights_only: bool = False;
}

obj Room {
    has name: str;
    has devices: list[Device] = [];
}

glob APPLIANCE_LIBRARY: list[Device] = [
    Device(name="Bulb", watts=10.0, start_minute=1080, run_minutes=300, lights_only=True),
    Device(name="Fan", watts=60.0),
    Device(name="Socket device", watts=100.0),
    Device(name="Fridge", watts=150.0, duty_cycle=0.4),
    Device(name="TV", watts=100.0, start_minute=1080, run_minutes=300),
    Device(name="Washing machine", watts=500.0, start_minute=600, run_minutes=60),
    Device(name="AC", watts=1200.0),
    Device(name="Kettle", watts=1500.0, start_minute=720, run_minutes=20),
    Device(name="Water heater", watts=2000.0),
    Device(name="Vacuum", watts=1000.0, start_minute=900, run_minutes=30)
];
