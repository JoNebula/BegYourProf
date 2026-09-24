#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$project_dir/.build"
dist_dir="$project_dir/dist"
app="$dist_dir/BegYourProf.app"
version="${VERSION:-0.3.1}"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "VERSION must be in major.minor.patch format" >&2
  exit 1
fi

mkdir -p "$build_dir" "$dist_dir" "$app/Contents/MacOS" "$app/Contents/Resources"

for arch in arm64 x86_64; do
  swiftc -parse-as-library -O \
    -target "${arch}-apple-macos13.0" \
    -framework AppKit -framework SwiftUI \
    "$project_dir/Sources/BegYourProf.swift" \
    -o "$build_dir/BegYourProf-$arch"
done
lipo -create "$build_dir/BegYourProf-arm64" "$build_dir/BegYourProf-x86_64" \
  -output "$app/Contents/MacOS/BegYourProf"

cp "$project_dir/Assets/default-avatar.png" "$app/Contents/Resources/default-avatar.png"
sips -c 1024 1024 "$project_dir/Assets/default-avatar.png" --out "$build_dir/AppIcon.png" >/dev/null
iconset="$build_dir/AppIcon.iconset"
mkdir -p "$iconset"
for points in 16 32 128 256 512; do
  sips -z "$points" "$points" "$build_dir/AppIcon.png" \
    --out "$iconset/icon_${points}x${points}.png" >/dev/null
  double=$((points * 2))
  sips -z "$double" "$double" "$build_dir/AppIcon.png" \
    --out "$iconset/icon_${points}x${points}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"

cat > "$app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>ko</string>
  <key>CFBundleDisplayName</key><string>BegYourProf</string>
  <key>CFBundleExecutable</key><string>BegYourProf</string>
  <key>CFBundleIconFile</key><string>AppIcon.icns</string>
  <key>CFBundleIdentifier</key><string>io.github.jonebula.BegYourProf</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>BegYourProf</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$version</string>
  <key>CFBundleVersion</key><string>$version</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
</dict>
</plist>
EOF

codesign --force --deep --sign - "$app"
codesign --verify --deep --strict "$app"
echo "Built $app"
