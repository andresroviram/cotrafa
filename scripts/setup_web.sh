#!/usr/bin/env bash

set -euo pipefail

readonly SQLITE3_VERSION="3.1.7"
readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly APP_DIR="$ROOT_DIR/apps/cotrafa-app"
readonly SQLITE3_URL="https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-$SQLITE3_VERSION/sqlite3.wasm"

mkdir -p "$APP_DIR/web"

echo "Installing SQLite WASM $SQLITE3_VERSION..."
curl --fail --location "$SQLITE3_URL" --output "$APP_DIR/web/sqlite3.wasm"

echo "Compiling the Drift web worker..."
(
  cd "$APP_DIR"
  fvm dart compile js -O1 -o web/drift_worker.dart.js web/drift_worker.dart
)

echo "Cotrafa web support is ready."
