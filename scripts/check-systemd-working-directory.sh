#!/usr/bin/env bash
#
# check-systemd-working-directory.sh
#
# Fail if any *.service file shipped in the release packages contains a bare
#   WorkingDirectory=/var/lib/globular/...
# without the '-' prefix that makes the state dir optional.
#
# systemd evaluates WorkingDirectory= BEFORE ExecStartPre, so a bare value
# pointing at a Globular state dir that hasn't been created yet causes
# status=200/CHDIR before the unit's mkdir hook can run. The '-' prefix
# tells systemd to fall back to "/" silently when the dir is missing.
#
# Wired into the Makefile so corrupted units (services repo INC-2026-0018)
# never reach the image. It inspects the STAGED RELEASE, because that is what
# the installer will deploy — the image no longer collects units from the
# build host, and checking host units would prove nothing about the release.
#
# Exit codes:
#   0  no bare WorkingDirectory= lines found
#   1  one or more units have bare WorkingDirectory= under /var/lib/globular
#   2  no .service files found in expected dirs (treat as fatal)

set -euo pipefail

cd "$(dirname "$0")/.."

# Units now ship inside the release packages, not in a units/ directory
# collected from the build host. Check the units that will ACTUALLY be
# installed by unpacking each package's systemd/ entries from the staged
# release tarball.
tarball=$(ls release/globular-*-linux-amd64.tar.gz 2>/dev/null | head -1)
if [ -z "$tarball" ]; then
  echo "check-systemd-working-directory: no release tarball under release/ — run 'make collect' first" >&2
  exit 2
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Pull only the packages/ member out of the release, then each package's units.
tar xzf "$tarball" -C "$work" --strip-components=1 --wildcards '*/packages/*.tgz' 2>/dev/null \
  || { echo "check-systemd-working-directory: could not extract packages/ from $tarball" >&2; exit 2; }

mkdir -p "$work/units"
for pkg in "$work"/packages/*.tgz; do
  [ -f "$pkg" ] || continue
  name=$(basename "$pkg" .tgz)
  mkdir -p "$work/units/$name"
  # Service packages store members as ./systemd/*.service; infra packages
  # carry no systemd/ at all. Both cases are fine — ignore extraction misses.
  tar xzf "$pkg" -C "$work/units/$name" --wildcards '*systemd/*.service' 2>/dev/null || true
done

dirs=("$work/units")

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
  echo "check-systemd-working-directory: no .service files found in $(basename "$tarball")" >&2
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
