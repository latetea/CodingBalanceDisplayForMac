#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="CodingBalanceDisplayMac"
BUNDLE_ID="${BUNDLE_ID:-com.ximing.coding-balance-display-mac}"
APP_VERSION="${APP_VERSION:-1.0.0}"
APP_BUILD="${APP_BUILD:-$(date +%Y%m%d%H%M%S)}"
ICON_SVG_PATH="$ROOT_DIR/icon.svg"
ICON_NAME="AppIcon"

DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

render_svg_png() {
  local size output_path density
  size="$1"
  output_path="$2"
  density=$((size * 8))

  if command -v magick >/dev/null 2>&1; then
    magick \
      -background none \
      -density "$density" \
      "$ICON_SVG_PATH" \
      -filter LanczosSharp \
      -define filter:blur=0.92 \
      -resize "${size}x${size}" \
      -gravity center \
      -extent "${size}x${size}" \
      "$output_path"
  else
    echo "error: ImageMagick is required to render sharp SVG app icons." >&2
    exit 1
  fi
}

generate_app_icon() {
  local temp_dir iconset_dir icon_icns
  temp_dir="$(mktemp -d /tmp/${APP_NAME}-icon.XXXXXX)"
  iconset_dir="$temp_dir/${ICON_NAME}.iconset"
  icon_icns="$RESOURCES_DIR/${ICON_NAME}.icns"

  mkdir -p "$iconset_dir"

  echo "Rendering SVG app icon..."

  for size in 16 32 128 256 512; do
    render_svg_png "$size" "$iconset_dir/icon_${size}x${size}.png"
    local retina_size=$((size * 2))
    render_svg_png "$retina_size" "$iconset_dir/icon_${size}x${size}@2x.png"
  done

  iconutil -c icns "$iconset_dir" -o "$icon_icns"
  rm -rf "$temp_dir"
}

echo "Building release binary..."
swift build -c release --product "$APP_NAME"

BIN_DIR="$(swift build -c release --show-bin-path)"
EXECUTABLE_PATH="$BIN_DIR/$APP_NAME"

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  echo "error: executable not found at $EXECUTABLE_PATH" >&2
  exit 1
fi

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$FRAMEWORKS_DIR" "$RESOURCES_DIR"

cp "$EXECUTABLE_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

if [[ -f "$ICON_SVG_PATH" ]]; then
  generate_app_icon
fi

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIconFile</key>
  <string>${ICON_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${APP_VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${APP_BUILD}</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

if xcrun --find swift-stdlib-tool >/dev/null 2>&1; then
  echo "Embedding Swift runtime libraries..."
  xcrun swift-stdlib-tool \
    --copy \
    --platform macosx \
    --scan-executable "$MACOS_DIR/$APP_NAME" \
    --destination "$FRAMEWORKS_DIR"
fi

echo "Signing app bundle..."
codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo
echo "Created app bundle:"
echo "  $APP_DIR"
echo
echo "You can drag this app into /Applications and launch it directly."
