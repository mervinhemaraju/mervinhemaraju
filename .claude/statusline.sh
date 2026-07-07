#!/usr/bin/env python3
# ~/.claude/statusline.sh  (chmod +x this file)
# Claude Code custom status line
#
# Line 1: [model]  cwd  branch (clickable OSC-8 link to remote)
# Line 2: ████░░░░ xx%  xxx / xxxk tokens
#
# Requires: Python 3 (standard on macOS/Linux), git

import json, sys, subprocess, os, time

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

def get_pct(*keys):
    """Return an int percentage for the nested keys, or None when absent."""
    obj = data
    for k in keys:
        if not isinstance(obj, dict):
            return None
        obj = obj.get(k)
        if obj is None:
            return None
    try:
        return int(float(obj))
    except (TypeError, ValueError):
        return None

model    = get(data, "model",    "display_name") or "unknown"
effort   = get(data, "effort", "level")          # "" when model has no effort param
cwd      = get(data, "workspace", "current_dir") or get(data, "cwd") or ""
pct      = int(float(get(data, "context_window", "used_percentage") or 0))
tokens   = int(float(get(data, "context_window", "total_input_tokens") or 0))
cw_size  = int(float(get(data, "context_window", "context_window_size") or 200000))

repo_host  = get(data, "workspace", "repo", "host")
repo_owner = get(data, "workspace", "repo", "owner")
repo_name  = get(data, "workspace", "repo", "name")

session_pct   = get_pct("rate_limits", "five_hour", "used_percentage")
allmodels_pct = get_pct("rate_limits", "seven_day", "used_percentage")

session_reset_at   = get(data, "rate_limits", "five_hour", "resets_at")
allmodels_reset_at = get(data, "rate_limits", "seven_day", "resets_at")

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

def fmt_remaining(resets_at):
    """Human-readable time left until resets_at (unix epoch seconds), or "" when absent."""
    try:
        remaining = float(resets_at) - time.time()
    except (TypeError, ValueError):
        return ""
    if remaining <= 0:
        return "0m left"
    d, rem = divmod(int(remaining), 86400)
    h, rem = divmod(rem, 3600)
    m, _   = divmod(rem, 60)
    if d:
        return f"{d}d {h}h left"
    if h:
        return f"{h}h {m}m left"
    return f"{m}m left"

def osc8(url, label):
    """OSC 8 clickable hyperlink. Cmd+click macOS, Ctrl+click Linux/Win."""
    return f"\033]8;;{url}\007{label}\033]8;;\007"

def kube_segment():
    """Current kube context (namespace), or "" when no context is active."""
    try:
        ctx = subprocess.check_output(
            ["kubectl", "config", "current-context"],
            stderr=subprocess.DEVNULL, text=True
        ).strip()
    except Exception:
        return ""
    if not ctx:
        return ""
    try:
        ns = subprocess.check_output(
            ["kubectl", "config", "view", "--minify", "-o", "jsonpath={..namespace}"],
            stderr=subprocess.DEVNULL, text=True
        ).strip()
    except Exception:
        ns = ""
    return f"☸️  {YELLOW}{ctx} ({ns or 'default'}){RESET}"

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

# [model] in red — append "- effort" when the model supports it
model_label = f"{model} - {effort}" if effort else model
parts1 = [f"🤖 {RED}[{model_label}]{RESET}"]

# current dir in cyan
parts1.append(f"📁 {CYAN}{dirname}{RESET}")

# git branch in grey, linked if possible
if branch:
    if repo_host and repo_owner and repo_name:
        branch_url = f"https://{repo_host}/{repo_owner}/{repo_name}/tree/{branch}"
        # colour inside the link: grey text
        linked = osc8(branch_url, f"{GREY}{branch}{RESET}")
        parts1.append(f"🌿 {linked}")
    else:
        parts1.append(f"🌿 {GREY}{branch}{RESET}")

# kube context (namespace) — only when a context is active
kube = kube_segment()
if kube:
    parts1.append(kube)

line1 = "  ".join(parts1)

# ── Line 2 ──────────────────────────────────────────────────────────────────────
pct_color = GREEN
if pct >= 70: pct_color = YELLOW
if pct >= 90: pct_color = RED

tokens_str = fmt_tokens(tokens)
cw_str     = fmt_tokens(cw_size)

line2 = f"📊 {GREY}context{RESET} {pct_color}{pct:3d}%{RESET}  {GREY}{tokens_str} / {cw_str} tokens{RESET}"

# ── Line 3: subscription usage (Pro/Max only, after first API response) ───────────
USAGE_BAR_WIDTH = 10

def usage_segment(label, upct, remaining=""):
    color = GREEN
    if upct >= 70: color = YELLOW
    if upct >= 90: color = RED
    filled = round(upct * USAGE_BAR_WIDTH / 100)
    seg_bar = "█" * filled + "░" * (USAGE_BAR_WIDTH - filled)
    seg = f"{label} {color}{seg_bar}{RESET} {upct:3d}%"
    if remaining:
        seg += f"  {GREY}({remaining}){RESET}"
    return seg

usage_parts = []
if session_pct is not None:
    usage_parts.append(usage_segment(f"⏳ {GREY}session{RESET}", session_pct, fmt_remaining(session_reset_at)))
if allmodels_pct is not None:
    usage_parts.append(usage_segment(f"🌐 {GREY}all models{RESET}", allmodels_pct, fmt_remaining(allmodels_reset_at)))

line3 = f"{GREY}  ·  {RESET}".join(usage_parts) if usage_parts else ""

# ── Output ──────────────────────────────────────────────────────────────────────
print(line1)
print()        # blank spacer row between the two lines
print(line2)
if line3:
    print()
    print(line3)