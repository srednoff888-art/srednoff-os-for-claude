#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
Claude MD OS reminder:
- Did you run relevant tests/build/lint?
- Did you check security and data-loss risks?
- Did you report assumptions and validation commands?
EOF

exit 0
