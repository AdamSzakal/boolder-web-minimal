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

check "$DIST/en/index.html"
check "$DIST/en/fontainebleau/index.html"
check "$DIST/en/projects/index.html"
check "$DIST/en/fontainebleau/circuits/index.html"
check "$DIST/en/fontainebleau/boulders/index.html"
check "$DIST/en/map/index.html"
check "$DIST/assets/search-index.json"
check "$DIST/assets/map-data.json"
check "$DIST/assets/tailwind.css"
check "$DIST/images/logo.svg"
check "$DIST/icon.png"

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
