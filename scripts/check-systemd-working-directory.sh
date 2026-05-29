#!/usr/bin/env bash
#
# check-systemd-working-directory.sh
#
# Fail if any *.service file under units/ or units-extra/ contains a bare
#   WorkingDirectory=/var/lib/globular/...
# without the '-' prefix that makes the state dir optional.
#
# systemd evaluates WorkingDirectory= BEFORE ExecStartPre, so a bare value
# pointing at a Globular state dir that hasn't been created yet causes
# status=200/CHDIR before the unit's mkdir hook can run. The '-' prefix
# tells systemd to fall back to "/" silently when the dir is missing.
#
# Wired into Makefile after the `collect` step so corrupted units coming
# from a host with pre-c529310e systemd files (services repo INC-2026-0018)
# never get baked into the Docker image.
#
# Exit codes:
#   0  no bare WorkingDirectory= lines found
#   1  one or more units have bare WorkingDirectory= under /var/lib/globular
#   2  no .service files found in expected dirs (treat as fatal)

set -euo pipefail

cd "$(dirname "$0")/.."

dirs=()
[ -d units ]       && dirs+=(units)
[ -d units-extra ] && dirs+=(units-extra)

if [ ${#dirs[@]} -eq 0 ]; then
  echo "check-systemd-working-directory: no units/ or units-extra/ dir found — run 'make collect' first" >&2
  exit 2
fi

# Bare line pattern: starts with WorkingDirectory=, value points at /var/lib/globular/, no '-' prefix.
pattern='^WorkingDirectory=/var/lib/globular/'

bad=()
total=0
while IFS= read -r f; do
  total=$((total+1))
  if grep -qE "$pattern" "$f"; then
    bad+=("$f")
  fi
done < <(find "${dirs[@]}" -type f -name "*.service")

if [ "$total" -eq 0 ]; then
  echo "check-systemd-working-directory: no .service files found under ${dirs[*]}" >&2
  exit 2
fi

if [ ${#bad[@]} -gt 0 ]; then
  echo "check-systemd-working-directory: FAIL — ${#bad[@]} of $total units have bare WorkingDirectory=/var/lib/globular/..." >&2
  echo "" >&2
  for f in "${bad[@]}"; do
    line=$(grep -nE "$pattern" "$f" | head -1)
    echo "  $f: $line" >&2
  done
  echo "" >&2
  echo "Fix: change 'WorkingDirectory=/var/lib/globular/<name>' to 'WorkingDirectory=-/var/lib/globular/<name>'" >&2
  echo "Background: services repo INC-2026-0018, commit c529310e, golang/systemdutil.NormalizeUnitWorkingDirectory" >&2
  exit 1
fi

echo "check-systemd-working-directory: OK — $total units checked, all WorkingDirectory= lines under /var/lib/globular use '-' prefix"
exit 0
