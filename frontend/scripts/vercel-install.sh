#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR=".vercel/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  git clone https://github.com/flutter/flutter.git \
    --depth 1 \
    --branch stable \
    "$FLUTTER_DIR"
fi

"$FLUTTER_DIR/bin/flutter" config --enable-web
"$FLUTTER_DIR/bin/flutter" pub get
