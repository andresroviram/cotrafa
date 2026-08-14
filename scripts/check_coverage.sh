#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly THRESHOLD="${1:-60}"

if [[ ! "$THRESHOLD" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Coverage threshold must be numeric." >&2
  exit 2
fi

cd "$ROOT_DIR"

if [[ "${COVERAGE_SKIP_TESTS:-false}" != "true" ]]; then
  fvm dart run melos run test:coverage
fi

COVERAGE_FILES=()
while IFS= read -r report; do
  COVERAGE_FILES+=("$report")
done < <(find apps packages -type f -path '*/coverage/lcov.info' | sort)

if [[ ${#COVERAGE_FILES[@]} -eq 0 ]]; then
  echo "No LCOV reports were found." >&2
  exit 1
fi

read -r LINES_FOUND LINES_HIT < <(
  awk -F: '
    /^SF:/ {
      included = $2 !~ /\.(g|freezed|config)\.dart$/
      next
    }
    included && /^LF:/ { found += $2 }
    included && /^LH:/ { hit += $2 }
    END { printf "%d %d\n", found, hit }
  ' "${COVERAGE_FILES[@]}"
)

if [[ "$LINES_FOUND" -eq 0 ]]; then
  echo "LCOV reports contain no measurable lines." >&2
  exit 1
fi

COVERAGE="$(awk -v hit="$LINES_HIT" -v found="$LINES_FOUND" 'BEGIN { printf "%.2f", (hit / found) * 100 }')"

printf 'Workspace line coverage: %s%% (%s/%s)\n' "$COVERAGE" "$LINES_HIT" "$LINES_FOUND"
printf 'Required threshold: %s%%\n' "$THRESHOLD"

if awk -v coverage="$COVERAGE" -v threshold="$THRESHOLD" 'BEGIN { exit !(coverage < threshold) }'; then
  echo "Coverage is below the required threshold." >&2
  exit 1
fi

mkdir -p coverage
: > coverage/lcov.info
for report in "${COVERAGE_FILES[@]}"; do
  package_directory="${report%/coverage/lcov.info}"
  awk -v prefix="$package_directory/" '
    /^SF:/ {
      source = substr($0, 4)
      included = source !~ /\.(g|freezed|config)\.dart$/
      if (included && source !~ /^\//) {
        print "SF:" prefix source
        next
      }
    }
    included { print }
    /^end_of_record$/ { included = 1 }
  ' "$report" >> coverage/lcov.info
done

if command -v genhtml >/dev/null 2>&1; then
  genhtml coverage/lcov.info --output-directory coverage/html >/dev/null
  echo "HTML report: coverage/html/index.html"
fi

echo "Coverage threshold satisfied."
