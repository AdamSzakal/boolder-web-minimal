#!/bin/bash
# Smoke-test the static build output

set -e

DIST="dist"
ERRORS=0

check_file() {
  if [ -f "$DIST/$1" ]; then
    echo "  ✓ $1"
  else
    echo "  ✗ $1 MISSING"
    ERRORS=$((ERRORS + 1))
  fi
}

echo "Verifying static build output in $DIST/..."
echo

echo "Core pages:"
check_file "en/index.html"
check_file "fr/index.html"

echo
echo "Assets:"
check_file "assets/search-index.json"
check_file "assets/map-data.json"

echo
if [ $ERRORS -eq 0 ]; then
  echo "All checks passed ✓"
else
  echo "$ERRORS check(s) failed ✗"
  exit 1
fi
