#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGES=(
  "examples/deep-link"
  "examples/subscription-state"
  "examples/async-policy"
  "examples/survey-flow"
)

echo "Running tests for ${#PACKAGES[@]} packages..."
echo

for package in "${PACKAGES[@]}"; do
  echo "==> ${package}"
  (cd "${ROOT}/${package}" && swift test)
  echo
done

echo "All packages passed."
