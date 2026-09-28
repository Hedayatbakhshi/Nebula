#!/usr/bin/env python3
import collections
import datetime as dt
import glob
import json
import os
import re
import subprocess
import sys

HOME = os.path.expanduser("~")
WEEKS = 26


def git_identity():
    ids = []
    for key in ("user.email", "user.name"):
        try:
            v = subprocess.run(["git", "config", "--global", key], capture_output=True, text=True, timeout=5).stdout.strip()
            if v:
                ids.append(v)
        except Exception:
            pass
    return ids


def find_repos():
    pats = [HOME + "/*/.git", HOME + "/*/*/.git", HOME + "/.config/*/.git", HOME + "/*/*/*/.git"]
    seen = set()
    for p in pats:
        for g in glob.glob(p):
            if "/node_modules/" in g or "/.cache/" in g:
                continue
            seen.add(os.path.dirname(g))
    return sorted(seen)


def git_stats():
    ids = git_identity()
    since = (dt.date.today() - dt.timedelta(days=7 * WEEKS)).isoformat()
    days = collections.Counter()
    per = collections.Counter()
    for repo in find_repos():
        cmd = ["git", "-C", repo, "log", "--all", "--since=" + since, "--format=%ad", "--date=short"]
        for i in ids:
            cmd.append("--author=" + i)
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=15).stdout.split()
        except Exception:
            continue
        for d in out:
            days[d] += 1
        if out:
            per[os.path.basename(repo)] += len(out)
    return {"days": dict(days), "repos": per.most_common(5), "total": sum(days.values())}


def shell_stats():
    path = HOME + "/.zsh_history"
    if not os.path.exists(path):
        return {"total": 0, "top": [], "timed": False}
    raw = open(path, "rb").read().decode("utf-8", "ignore").splitlines()
    names = collections.Counter()
    timed = 0
    for line in raw:
        m = re.match(r"^: (\d+):\d+;(.*)$", line)
        if m:
            timed += 1
            line = m.group(2)
        words = line.strip().split()
        if not words:
            continue
        n = words[0]
        if n in ("sudo", "doas") and len(words) > 1:
            n = words[1]
        if "=" in n or n.startswith(("#", "\\", "-")):
            continue
        names[os.path.basename(n)] += 1
    return {"total": len(raw), "top": names.most_common(6), "timed": timed > 0}


def vaults():
    out = []
    for cfg in glob.glob(HOME + "/*/.obsidian/app.json") + glob.glob(HOME + "/*/*/.obsidian/app.json"):
        root = os.path.dirname(os.path.dirname(cfg))
        notes = []
        words = 0
        for f in glob.glob(root + "/**/*.md", recursive=True):
            if "/." in f[len(root):]:
                continue
            notes.append(f)
        notes.sort(key=os.path.getmtime, reverse=True)
        for f in notes[:400]:
            try:
                words += len(open(f, errors="ignore").read().split())
            except Exception:
                pass
        daily = {}
        try:
            daily = json.load(open(root + "/.obsidian/daily-notes.json"))
        except Exception:
            pass
        out.append({
            "name": os.path.basename(root),
            "path": root,
            "count": len(notes),
            "words": words,
            "mtime": os.path.getmtime(notes[0]) if notes else 0,
            "dailyFolder": daily.get("folder", ""),
            "recent": [{"title": os.path.basename(f)[:-3], "path": f, "mtime": os.path.getmtime(f)} for f in notes[:4]],
        })
    out.sort(key=lambda v: v["mtime"], reverse=True)
    return out


def year_ago():
    pics = []
    for pat in ("/Pictures/*", "/Pictures/Screenshots/*", "/Pictures/*/*"):
        for f in glob.glob(HOME + pat):
            if f.lower().endswith((".png", ".jpg", ".jpeg", ".webp")):
                pics.append(f)
    pics = sorted(set(pics))
    today = dt.date.today()
    try:
        target = today.replace(year=today.year - 1)
    except ValueError:
        target = today - dt.timedelta(days=365)
    dated = []
    for f in pics:
        m = re.match(r"(\d{4})-(\d\d)-(\d\d)", os.path.basename(f))
        if not m:
            continue
        try:
            d = dt.date(int(m.group(1)), int(m.group(2)), int(m.group(3)))
        except ValueError:
            continue
        dated.append((d, f))
    best = None
    for window in (0, 3, 7, 14):
        hits = [(d, f) for d, f in dated if abs((d - target).days) <= window]
        if hits:
            day = min({d for d, _ in hits}, key=lambda d: abs((d - target).days))
            same = [f for d, f in hits if d == day]
            best = {"date": day.isoformat(), "count": len(same), "path": same[today.toordinal() % len(same)]}
            break
    since = sum(1 for d, _ in dated if best and d > dt.date.fromisoformat(best["date"]))
    return {"total": len(pics), "pick": best, "since": since}


def main():
    data = {"generated": dt.datetime.now().isoformat(timespec="seconds")}
    for key, fn in (("git", git_stats), ("shell", shell_stats), ("vaults", vaults), ("photos", year_ago)):
        try:
            data[key] = fn()
        except Exception as e:
            data[key] = {"error": str(e)}
    json.dump(data, sys.stdout)


if __name__ == "__main__":
    main()
