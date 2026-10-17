import ".styles.global.css";
import from engine.circuits { getApplianceLibrary }
import from engine.simulation { simulateHomeDay }
import from .components.VoltnestHome { VoltnestHome }

def:pub app() -> JsxElement {
    return <VoltnestHome />;
}
