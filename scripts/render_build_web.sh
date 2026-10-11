#!/usr/bin/env bash
# Compila la app Flutter web en Render (el entorno de Render no trae Flutter).
# Variables: API_URL (obligatoria), FLUTTER_CHANNEL (opcional, por defecto stable)
set -euo pipefail

: "${API_URL:?Define API_URL en Render (p. ej. https://lacarta-api.onrender.com)}"
FLUTTER_DIR="${HOME}/flutter-sdk"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"

if [ ! -x "${FLUTTER_DIR}/bin/flutter" ]; then
  echo ">> Descargando Flutter (${FLUTTER_CHANNEL})..."
  git clone --depth 1 -b "${FLUTTER_CHANNEL}" https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
fi
export PATH="${FLUTTER_DIR}/bin:${PATH}"

flutter --version
flutter config --no-analytics --enable-web >/dev/null
flutter pub get
# DEFAULT_SLUG vacío: en producción la raíz no abre ningún restaurante por defecto
flutter build web --release \
  --dart-define=API_URL="${API_URL}" \
  --dart-define=DEFAULT_SLUG=

echo ">> Listo: build/web"
