from pathlib import Path

HOME = Path.home()
PACKAGE_DIR = Path(__file__).resolve().parent
SHELL_DIR = PACKAGE_DIR.parents[1]
SH_DIR = PACKAGE_DIR / "sh"
CACHE_DIR = HOME / ".cache" / "quickshell"
SETTINGS = CACHE_DIR / "settings.json"
COLORS = CACHE_DIR / "colors.json"
