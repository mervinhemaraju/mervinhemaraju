#!/usr/bin/env python3
# ~/.claude/statusline.sh  (chmod +x this file)
# Claude Code custom status line
#
# Line 1: [model]  cwd  branch (clickable OSC-8 link to remote)
# Line 2: ████░░░░ xx%  xxx / xxxk tokens
#
# Requires: Python 3 (standard on macOS/Linux), git

import json, sys, subprocess, os

# ── Read JSON from stdin ────────────────────────────────────────────────────────
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

def get(obj, *keys, default=""):
    for k in keys:
        if not isinstance(obj, dict):
            return default
        obj = obj.get(k)
        if obj is None:
            return default
    return obj if obj is not None else default

model    = get(data, "model",    "display_name") or "unknown"
cwd      = get(data, "workspace", "current_dir") or get(data, "cwd") or ""
pct      = int(float(get(data, "context_window", "used_percentage") or 0))
tokens   = int(float(get(data, "context_window", "total_input_tokens") or 0))
cw_size  = int(float(get(data, "context_window", "context_window_size") or 200000))

repo_host  = get(data, "workspace", "repo", "host")
repo_owner = get(data, "workspace", "repo", "owner")
repo_name  = get(data, "workspace", "repo", "name")

# ── ANSI colours ────────────────────────────────────────────────────────────────
RED    = "\033[31m"
CYAN   = "\033[36m"
GREY   = "\033[90m"
GREEN  = "\033[32m"
YELLOW = "\033[33m"
RESET  = "\033[0m"

# ── Helpers ─────────────────────────────────────────────────────────────────────

def fmt_tokens(n):
    if n >= 1_000_000:
        v = n / 1_000_000
        return f"{v:.0f}M" if v == int(v) else f"{v:.1f}M"
    if n >= 1_000:
        v = n / 1_000
        return f"{v:.0f}k" if v == int(v) else f"{v:.1f}k"
    return str(n)

def osc8(url, label):
    """OSC 8 clickable hyperlink. Cmd+click macOS, Ctrl+click Linux/Win."""
    return f"\033]8;;{url}\007{label}\033]8;;\007"

# ── Git branch ──────────────────────────────────────────────────────────────────
branch = ""
if cwd:
    try:
        subprocess.check_output(
            ["git", "-C", cwd, "rev-parse", "--git-dir"],
            stderr=subprocess.DEVNULL
        )
        branch = subprocess.check_output(
            ["git", "-C", cwd, "branch", "--show-current"],
            stderr=subprocess.DEVNULL, text=True
        ).strip()
    except Exception:
        branch = ""

# ── Line 1 ──────────────────────────────────────────────────────────────────────
dirname = os.path.basename(cwd) or cwd

# [model] in red
parts1 = [f"{RED}[{model}]{RESET}"]

# current dir in cyan
parts1.append(f"{CYAN}{dirname}{RESET}")

# git branch in grey, linked if possible
if branch:
    if repo_host and repo_owner and repo_name:
        branch_url = f"https://{repo_host}/{repo_owner}/{repo_name}/tree/{branch}"
        # colour inside the link: grey text
        linked = osc8(branch_url, f"{GREY}{branch}{RESET}")
        parts1.append(linked)
    else:
        parts1.append(f"{GREY}{branch}{RESET}")

line1 = "  ".join(parts1)

# ── Line 2 ──────────────────────────────────────────────────────────────────────
BAR_WIDTH = 20
filled = round(pct * BAR_WIDTH / 100)
empty  = BAR_WIDTH - filled

bar_color = GREEN
if pct >= 70: bar_color = YELLOW
if pct >= 90: bar_color = RED

bar = "█" * filled + "░" * empty

tokens_str = fmt_tokens(tokens)
cw_str     = fmt_tokens(cw_size)

line2 = f"{bar_color}{bar}{RESET} {pct:3d}%  {GREY}{tokens_str} / {cw_str} tokens{RESET}"

# ── Output ──────────────────────────────────────────────────────────────────────
print(line1)
print()        # blank spacer row between the two lines
print(line2)