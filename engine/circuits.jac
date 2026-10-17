obj CircuitComponent {
    has name: str = "Component";
    has kind: str = "part";
}

obj Circuit {
    has name: str = "Untitled circuit";
    has components: list[CircuitComponent] = [];
}
