#!/bin/bash
# Setup now runs inside Claude Code via the /setup skill.
# This stub redirects callers of the legacy `bash setup.sh` flow.
# The skill is the single source of truth: folder naming, .mcp.json server
# name, statusline walk-through, build folder scaffold, and verification.

cat <<'EOF'

  Relevance Builder Kit setup is now done inside Claude Code.

  1. Install Claude Code:    https://claude.com/claude-code
  2. Start it from here:     claude
  3. Inside Claude Code:     /setup

  Then run /mcp to authenticate with Relevance AI (OAuth).

  Why the change: the old bash flow drifted out of sync with /setup
  (folder naming and the statusline walk-through). /setup is now the
  canonical path so there is one source of truth.

EOF

exit 0
