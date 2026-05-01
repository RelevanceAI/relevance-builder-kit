#!/bin/bash
# Sets up the Claude Code statusline for this project.
# The statusline config lives in the project-level .claude/settings.json
# so that everyone gets it automatically on pull -- no per-user setup needed.
#
# This script is kept for backward compatibility / manual re-setup.
# It ensures the project-level settings file has the statusline entry.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SETTINGS="$REPO_DIR/.claude/settings.json"

STATUSLINE_CMD='bash "$CLAUDE_PROJECT_DIR/scripts/statusline.sh"'

if [ ! -f "$SETTINGS" ]; then
  # Create project-level settings.json with just the statusline
  python3 -c "
import json
d = {'statusLine': {'type': 'command', 'command': '$STATUSLINE_CMD'}}
with open('$SETTINGS', 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
"
  echo "Created $SETTINGS with statusline configured."
else
  # Update existing project-level settings.json, preserving other fields
  python3 -c "
import json, sys
try:
    with open('$SETTINGS') as f:
        d = json.load(f)
except (json.JSONDecodeError, ValueError):
    print('WARNING: $SETTINGS has invalid JSON, recreating with statusline only.', file=sys.stderr)
    d = {}
d['statusLine'] = {'type': 'command', 'command': '$STATUSLINE_CMD'}
with open('$SETTINGS', 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
"
  echo "Updated $SETTINGS with statusline."
fi

# Remove statusline from user-level settings if it points to this repo
USER_SETTINGS="$HOME/.claude/settings.json"
if [ -f "$USER_SETTINGS" ]; then
  python3 -c "
import json, re, sys
try:
    with open('$USER_SETTINGS') as f:
        d = json.load(f)
except (json.JSONDecodeError, ValueError):
    # JSON is broken -- try regex removal of statusLine block as a fallback
    with open('$USER_SETTINGS') as f:
        raw = f.read()
    if 'statusline.sh' in raw:
        # Remove the statusLine object and any trailing comma
        cleaned = re.sub(r',?\s*\"statusLine\"\s*:\s*\{[^}]*\}\s*,?', '', raw)
        # Fix double commas or trailing commas before closing brace
        cleaned = re.sub(r',(\s*[}\]])', r'\1', cleaned)
        with open('$USER_SETTINGS', 'w') as f:
            f.write(cleaned)
        print('WARNING: $USER_SETTINGS had invalid JSON. Removed statusline via text cleanup.')
    else:
        print('WARNING: $USER_SETTINGS has invalid JSON but no statusline to remove. Skipping.', file=sys.stderr)
    sys.exit(0)
if 'statusLine' in d:
    cmd = d['statusLine'].get('command', '')
    if 'statusline.sh' in cmd:
        del d['statusLine']
        with open('$USER_SETTINGS', 'w') as f:
            json.dump(d, f, indent=2)
            f.write('\n')
        print('Removed stale statusline from user-level settings.')
"
fi

echo "Done! Restart Claude Code to see the statusline."
