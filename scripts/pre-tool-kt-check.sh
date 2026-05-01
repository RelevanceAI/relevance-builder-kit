#!/usr/bin/env bash
# PreToolUse hook: warn whenever a tool build includes a native KT transformation.
#
# Triggered by .claude/settings.json when relevance_upsert_tool is called.
# Reads the tool call JSON on stdin and greps the transformations blob for
# known KT transformation names. If any match, emits a reminder to stderr so
# the context shows "Read build-kit/tools/knowledge-tables.md first" before
# the agent commits the tool.
#
# Never blocks. Just nudges. Exit 0 always.

set -uo pipefail

INPUT=$(cat)

# Known native KT transformations. Adding more? Just extend the regex.
KT_PATTERN='update_knowledge_set_rows|retrieve_data|upsert_knowledge_set_rows|delete_knowledge_set_rows|bulk_update|multiple_file_upload'

if printf '%s' "$INPUT" | grep -Eq "$KT_PATTERN"; then
  cat >&2 <<'MSG'
Native knowledge-table transformation detected in this tool build.

Before you ship this tool, confirm:

  1. You have read `build-kit/tools/knowledge-tables.md` in this session.
     Specifically the "Filter Types Reference" section. It distinguishes
     Format A (raw API `filters`) vs Format B (native step `raw_filters`).

  2. `raw_filters` on a native step uses the simple-dict shape:
         [{"data.<field>": "<value>"}]
     NOT the verbose /knowledge/list shape. The verbose shape silently
     returns 0 matches. No error, no warning.

  3. You have grepped the project for existing uses of the transformation
     you're about to use. If none exist, be extra careful; that's a
     caution signal, not a green light.

  4. `.claude/rules/PLATFORM_MECHANICS.md` "Knowledge Sets > Filter Syntax
     in Native Steps" has the side-by-side table and worked example.

If you've already done these, ignore this reminder and proceed.
MSG
fi

exit 0
