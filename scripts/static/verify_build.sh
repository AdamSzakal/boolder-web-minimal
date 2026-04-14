#!/usr/bin/env bash
set -euo pipefail

DIST="dist"
PASS=0
FAIL=0

check() {
  if [ -f "$1" ]; then
    echo "  PASS: $1"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $1 not found"
    FAIL=$((FAIL + 1))
  fi
}

echo "Verifying static build output in $DIST/..."

check "$DIST/index.html"
check "$DIST/areas/index.html"
check "$DIST/projects/index.html"
check "$DIST/areas/circuits/index.html"
check "$DIST/areas/boulders/index.html"
check "$DIST/map/index.html"
check "$DIST/assets/search-index.json"
check "$DIST/assets/map-data.json"
check "$DIST/images/logo.svg"
check "$DIST/icon.png"

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
