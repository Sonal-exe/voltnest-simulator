import from engine.circuits { Circuit }

obj SimulationResult {
    has circuit_name: str = "";
    has component_count: int = 0;
    has summary: str = "";
}

def simulateCircuit(circuit: Circuit) -> SimulationResult {
    return SimulationResult(
        circuit_name=circuit.name,
        component_count=len(circuit.components),
        summary="Your circuit is ready to explore."
    );
}
