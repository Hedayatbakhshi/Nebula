import json

from nebula.paths import SETTINGS


def load() -> dict:
    try:
        return json.loads(SETTINGS.read_text())
    except Exception:
        return {}


def section(name: str) -> dict:
    return load().get(name) or {}


def update(name: str, patch: dict) -> None:
    data = load()
    sec = dict(data.get(name) or {})
    for k, v in patch.items():
        if v is None:
            sec.pop(k, None)
        else:
            sec[k] = v
    data[name] = sec
    text = json.dumps(data, indent=4)
    SETTINGS.parent.mkdir(parents=True, exist_ok=True)
    mode = "r+" if SETTINGS.exists() else "w"
    with open(SETTINGS, mode) as f:
        f.seek(0)
        f.write(text)
        f.truncate()
