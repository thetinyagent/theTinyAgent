#!/usr/bin/env bash
# Leak-prevention gate: fails if internal infrastructure detail appears in
# anything that could reach the public site. Runs pre-commit and in CI/deploy.
set -uo pipefail
cd "$(dirname "$0")/.."

patterns=(
  '172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}'
  '172\.30\.[0-9]{1,3}'
  '192\.168\.[0-9]{1,3}\.[0-9]{1,3}'
  '\b10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b'
  '\bVLANs?[- ]?#?[0-9]{1,3}\b'
  '\b(pve|nuc|ns0|ns[12]|fw0|pg0|etcd0)[0-9]{1,2}\b'
  'LAB_Transit'
  'home\.thetinylab'
  '\btny-lap\b'
  '\bTinyFi\b'
  '\bUCG[- ]?Fibre\b|\bUCG\b'
  '\bPlusnet\b'
  '\bOptiPlex\b|7040|7i7BNK'
  'sudo@thetinylab'
)

fails=0
# Scan exactly what could reach the repo: tracked files plus untracked,
# non-ignored ones. Ignored paths (memory/, .bus/) are sanctioned private
# space where internal detail is allowed to live; sweeping them here made
# every commit fail once a persona's memory mentioned a hostname.
while IFS= read -r -d '' f; do
  for p in "${patterns[@]}"; do
    matches=$(grep -InE "$p" "$f" 2>/dev/null || true)
    if [ -n "$matches" ]; then
      echo "LEAK: pattern [$p]" >&2
      echo "$matches" | sed 's/^/      /' >&2
      echo "  in: $f" >&2
      fails=1
    fi
  done
done < <(git ls-files --cached --others --exclude-standard -z \
  | grep -zE '\.(md|html|toml|yaml|yml|css|js|json)$')

if [ "$fails" -ne 0 ]; then
  echo "" >&2
  echo "leak-check FAILED — internal detail must not enter the agent's public repo." >&2
  echo "See README.md § sanitization contract." >&2
  exit 1
fi

echo "leak-check: clean"
