#!/usr/bin/env bash
# Outputs JSON: {ctx_pct, ctx_tokens, ctx_max, model, today_out, today_sessions}
# Caches result for 9s so multiple eww polls stay fast.
set -euo pipefail

CACHE="/tmp/claude_usage.json"

if [ -f "$CACHE" ] && [ $(( $(date +%s) - $(stat -c %Y "$CACHE") )) -lt 9 ]; then
    cat "$CACHE"
    exit 0
fi

python3 - <<'PYEOF'
import json, os, glob
from datetime import datetime, timezone

# Context window sizes per model — all current Claude models are 200K
CONTEXT_LIMITS = {
    "claude-opus-4-7":    200_000,
    "claude-sonnet-4-6":  200_000,
    "claude-haiku-4-5":   200_000,
    "claude-3-7-sonnet":  200_000,
    "claude-3-5-sonnet":  200_000,
    "claude-3-opus":      200_000,
    "claude-3-haiku":     200_000,
}
DEFAULT_LIMIT = 200_000

JSONL_DIR = os.path.expanduser('~/.claude/projects')
CACHE     = '/tmp/claude_usage.json'

def fmt_k(n):
    return f"{n // 1000}K" if n >= 1000 else str(n)

all_jsonl = glob.glob(os.path.join(JSONL_DIR, '**/*.jsonl'), recursive=True)
if not all_jsonl:
    result = {"ctx_pct": 0, "ctx_tokens": "0", "ctx_max": "200K",
              "model": "unknown", "today_out": "0", "today_sessions": 0}
    out = json.dumps(result)
    print(out)
    open(CACHE, 'w').write(out)
    raise SystemExit(0)

# Current context — last real usage entry in the most-recently-modified JSONL.
# After auto-compact, Claude Code resets the context; the last entry reflects
# the post-compact state, so this naturally handles compaction.
most_recent = max(all_jsonl, key=os.path.getmtime)
ctx_tokens = 0
model_name = "unknown"
with open(most_recent) as f:
    last_usage = None
    last_model = None
    for line in f:
        try:
            obj = json.loads(line.strip())
            msg = obj.get('message', {})
            if msg.get('usage') and msg.get('model') and msg['model'] != '<synthetic>':
                last_usage = msg['usage']
                last_model = msg['model']
        except Exception:
            pass
    if last_usage:
        ctx_tokens = (last_usage.get('input_tokens', 0)
                    + last_usage.get('cache_creation_input_tokens', 0)
                    + last_usage.get('cache_read_input_tokens', 0))
    if last_model:
        model_name = last_model

# Look up the exact limit for this model (prefix-match for version flexibility)
ctx_limit = DEFAULT_LIMIT
for key, limit in CONTEXT_LIMITS.items():
    if model_name.startswith(key) or key in model_name:
        ctx_limit = limit
        break

ctx_pct = min(100, ctx_tokens * 100 // ctx_limit)

# Today's totals across all sessions
today = datetime.now(timezone.utc).strftime('%Y-%m-%d')
today_out      = 0
today_sessions = 0
for jsonl in all_jsonl:
    mtime = datetime.fromtimestamp(os.path.getmtime(jsonl), tz=timezone.utc).strftime('%Y-%m-%d')
    if mtime != today:
        continue
    today_sessions += 1
    with open(jsonl) as f:
        for line in f:
            try:
                obj = json.loads(line.strip())
                if obj.get('message', {}).get('usage'):
                    today_out += obj['message']['usage'].get('output_tokens', 0)
            except Exception:
                pass

result = {
    "ctx_pct":        ctx_pct,
    "ctx_tokens":     fmt_k(ctx_tokens),
    "ctx_max":        fmt_k(ctx_limit),
    "model":          model_name,
    "today_out":      fmt_k(today_out),
    "today_sessions": today_sessions,
}
out = json.dumps(result)
print(out)
open(CACHE, 'w').write(out)
PYEOF
