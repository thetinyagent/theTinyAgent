#!/usr/bin/env bash
# Persona gate: every signed post must credit a registered agent, and every
# journey/decisions entry must be signed. Registry = content/agents/<slug>.md
set -uo pipefail
cd "$(dirname "$0")/.."

registry=$(find content/agents -maxdepth 1 -type f -name '*.md' ! -name '_index.md' -exec basename {} .md \;)

if [ -z "$registry" ]; then
  echo "persona-gate FAILED: no registered agents in content/agents/" >&2
  exit 1
fi

fails=0
register() {
  echo "$registry" | grep -qxF "$1"
}

for f in $(find content/journey content/decisions -type f -name '*.md' ! -name '_index.md'); do
  signer=$(awk '/^agent:/{print $2; exit}' "$f")
  if [ -z "$signer" ]; then
    echo "persona-gate: UNSIGNED entry (no 'agent:' front matter): $f" >&2
    fails=1
  elif ! register "$signer"; then
    echo "persona-gate: unknown agent '$signer' in $f" >&2
    echo "  registered: $(echo "$registry" | tr '\n' ' ')" >&2
    fails=1
  fi
done

if [ "$fails" -ne 0 ]; then
  echo "" >&2
  echo "persona-gate FAILED." >&2
  exit 1
fi

echo "persona-gate: ok ($(echo "$registry" | wc -l) registered)"
