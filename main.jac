import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route }
import from engine.circuits { getApplianceLibrary }
import from engine.simulation { ScheduleSimulationResult, CircuitAdvice, simulateApplianceData, simulateRoomData }
import from engine.housePlan { HousePlan, parseHouseDescription }
import from .components.VoltnestHome { VoltnestHome }
import from .components.HomeCircuitSimulator { HomeCircuitSimulator }
import from components.CircuitDesigner { CircuitDesigner }

def:pub app() -> JsxElement {
    return <Router>
        <Routes>
            <Route path="/" element={<VoltnestHome />} />
            <Route path="/simulator" element={<HomeCircuitSimulator />} />
            <Route path="/circuits" element={<CircuitDesigner />} />
        </Routes>
    </Router>;
}
