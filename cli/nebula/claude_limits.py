#!/usr/bin/env python3
"""
Claude Code's real rate-limit utilisation, from the same endpoint /usage uses.

The percentages are not stored anywhere on disk — the CLI fetches them from
https://api.anthropic.com/api/oauth/usage on demand. This does the same call
with the OAuth access token Claude Code already keeps in ~/.claude/.credentials.json.

The token is read into memory, sent to Anthropic's own API and nothing else. It
is never logged and never written to the cache; only the response is cached. An
expired token is not refreshed here — Claude Code owns that file and refreshing
behind its back would race it — so a stale token just returns the last good
answer marked stale.

Usage: claude_limits.py [--ttl SECONDS]
Prints one JSON object on stdout.
"""

import json
import os
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path

CREDS = Path.home() / ".claude" / ".credentials.json"
CACHE = Path.home() / ".cache" / "quickshell" / "claude_limits.json"
URL   = "https://api.anthropic.com/api/oauth/usage"
TTL   = 120
TIMEOUT = 12


def _read_cache():
    try:
        return json.loads(CACHE.read_text())
    except Exception:
        return None


def _write_cache(payload):
    try:
        CACHE.parent.mkdir(parents=True, exist_ok=True)
        tmp = CACHE.with_suffix(".tmp")
        tmp.write_text(json.dumps(payload))
        os.replace(tmp, CACHE)
    except OSError:
        pass


def _seconds_left(iso: str) -> int:
    if not iso:
        return 0
    try:
        when = datetime.fromisoformat(iso.replace("Z", "+00:00"))
        return max(0, int(when.timestamp() - time.time()))
    except Exception:
        return 0


def _retime(payload: dict) -> dict:
    """resets_at is absolute, so the countdown is recomputed on every output —
    a cached answer served an hour later must not repeat the old secondsLeft."""
    for item in payload.get("limits") or []:
        item["secondsLeft"] = _seconds_left(item.get("resetsAt") or "")
    return payload


def _shape(raw: dict) -> dict:
    """The `limits` array is the forward-compatible view; the named blocks are the fallback."""
    out = []
    for item in raw.get("limits") or []:
        if not isinstance(item, dict):
            continue
        out.append({
            "kind": item.get("kind", ""),
            "group": item.get("group", ""),
            "percent": item.get("percent") or 0,
            "severity": item.get("severity", "normal"),
            "resetsAt": item.get("resets_at") or "",
            "secondsLeft": _seconds_left(item.get("resets_at") or ""),
            "active": bool(item.get("is_active")),
        })

    if not out:
        for kind, group, key in (("session", "session", "five_hour"),
                                 ("weekly_all", "weekly", "seven_day")):
            block = raw.get(key)
            if not isinstance(block, dict):
                continue
            out.append({
                "kind": kind,
                "group": group,
                "percent": round(block.get("utilization") or 0),
                "severity": "normal",
                "resetsAt": block.get("resets_at") or "",
                "secondsLeft": _seconds_left(block.get("resets_at") or ""),
                "active": True,
            })

    return {"limits": out, "fetchedAt": int(time.time())}


def main() -> int:
    ttl = TTL
    if "--ttl" in sys.argv:
        idx = sys.argv.index("--ttl")
        if idx + 1 < len(sys.argv):
            ttl = max(30, int(sys.argv[idx + 1]))

    cached = _read_cache()
    if cached and time.time() - cached.get("fetchedAt", 0) < ttl:
        cached["stale"] = False
        print(json.dumps(_retime(cached)))
        return 0

    def _fallback(reason):
        if cached:
            cached["stale"] = True
            cached["reason"] = reason
            print(json.dumps(_retime(cached)))
        else:
            print(json.dumps({"limits": [], "stale": True, "reason": reason,
                              "fetchedAt": 0}))
        return 0

    try:
        creds = json.loads(CREDS.read_text())["claudeAiOauth"]
    except Exception:
        return _fallback("no credentials")

    if (creds.get("expiresAt") or 0) / 1000.0 <= time.time():
        return _fallback("token expired")

    request = urllib.request.Request(URL, headers={
        "Authorization": "Bearer " + creds["accessToken"],
        "anthropic-beta": "oauth-2025-04-20",
        "Content-Type": "application/json",
        "User-Agent": "quickshell-claude-widget",
    })

    try:
        with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
            raw = json.load(response)
    except urllib.error.HTTPError as exc:
        return _fallback("http %d" % exc.code)
    except Exception:
        return _fallback("unreachable")

    payload = _shape(raw)
    _write_cache(payload)
    payload["stale"] = False
    print(json.dumps(payload))
    return 0


if __name__ == "__main__":
    sys.exit(main())
