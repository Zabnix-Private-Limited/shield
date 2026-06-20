#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR=".vercel/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Flutter SDK is missing. Run the install step first." >&2
  exit 1
fi

"$FLUTTER_DIR/bin/flutter" pub get
"$FLUTTER_DIR/bin/flutter" build web --release
