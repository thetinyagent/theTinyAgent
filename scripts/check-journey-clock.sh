#!/usr/bin/env bash
# Journey-clock gate: fails if any journey/decisions entry is dated at or
# near/after wall clock. Hugo skips future-dated pages at build time, and
# Pages builds fire seconds after push — a post stamped ahead of reality
# ships green but renders nowhere until the next push after its timestamp.
# Twice-caught failure mode; this makes it structurally impossible.
#
# Margin (default 120s, override: JOURNEY_CLOCK_MARGIN=<seconds>): a fresh
# entry must sit at least this far behind whatever clock checks it. Guards
# both the instant the author misjudged and the commit→push→build lag.
# Missing dates are check-personas.sh territory; we only judge values
# present, and present-but-unparsable is a hard fail (nothing verifiable,
# nothing ships). Scope mirrors check-personas: content/journey +
# content/decisions, _index.md exempt (no ByDate listing).
set -uo pipefail
cd "$(dirname "$0")/.."

margin=${JOURNEY_CLOCK_MARGIN:-120}
now=$(date -u +%s)
floor=$((now - margin))

fails=0
for f in $(find content/journey content/decisions -type f -name '*.md' ! -name '_index.md'); do
  d=$(awk '/^date:/{print $2; exit}' "$f")
  [ -z "$d" ] && continue

  if ! epoch=$(date -u -d "$d" +%s 2>/dev/null); then
    echo "journey-clock: UNPARSABLE date '$d' in $f (want RFC3339, e.g. 2026-08-27T13:30:00Z)" >&2
    fails=1
    continue
  fi

  if [ "$epoch" -gt "$floor" ]; then
    ahead=$((epoch - floor))
    echo "journey-clock: TOO CLOSE TO NOW (> ${margin}s ahead/present) in $f: $d (${ahead}s over floor)" >&2
    echo "  stamp the true moment you wrote it; a post must be visibly past" >&2
    echo "  by the time Pages builds it" >&2
    fails=1
  fi
done

if [ "$fails" -ne 0 ]; then
  echo "" >&2
  echo "journey-clock FAILED — future-leaning timestamps cannot reach a build." >&2
  exit 1
fi

echo "journey-clock: ok (margin ${margin}s)"
