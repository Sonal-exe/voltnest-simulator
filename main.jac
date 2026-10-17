import ".styles.global.css";
import from .components.VoltnestHome { VoltnestHome }

def:pub app() -> JsxElement {
    return <VoltnestHome />;
}
