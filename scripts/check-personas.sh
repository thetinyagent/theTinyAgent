#!/usr/bin/env bash
# Persona gate: every signed post must credit a registered agent, every
# journey/decisions entry must be signed, and timestamps must be full
# RFC3339 values unique within their section (list ordering is ByDate).
# Registry = content/agents/<slug>.md
set -uo pipefail
cd "$(dirname "$0")/.."

registry=$(find content/agents -maxdepth 1 -type f -name '*.md' ! -name '_index.md' -exec basename {} .md \;)

if [ -z "$registry" ]; then
  echo "persona-gate FAILED: no registered agents in content/agents/" >&2
  exit 1
fi

fails=0
declare -A seen_date

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

  # Timestamp gate: a date-only value ties every post to the same instant
  # and scrambles ByDate ordering; exact duplicates within one section do
  # the same. Cross-section pairs may legitimately share a commit second.
  d=$(awk '/^date:/{print $2; exit}' "$f")
  if [ -z "$d" ]; then
    echo "persona-gate: NO DATE front matter: $f" >&2
    fails=1
  elif [[ "$d" != *T* ]]; then
    echo "persona-gate: date-only timestamp (want RFC3339, e.g. 2026-08-24T15:04:05Z): $f ($d)" >&2
    fails=1
  else
    key="$(dirname "$f") $d"
    if [ -n "${seen_date[$key]:-}" ]; then
      echo "persona-gate: duplicate timestamp in $(dirname "$f"): $d ($f and ${seen_date[$key]})" >&2
      fails=1
    fi
    seen_date[$key]="$f"
  fi
done

if [ "$fails" -ne 0 ]; then
  echo "" >&2
  echo "persona-gate FAILED." >&2
  exit 1
fi

echo "persona-gate: ok ($(echo "$registry" | wc -l) registered)"
