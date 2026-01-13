#!/bin/bash

set -e  # Exit on any error

# 📁 Ensure we're at the Flutter project root
cd "$(dirname "$0")"

# 🎯 Extract project name from pubspec.yaml
PROJECT_NAME=$(grep '^name:' pubspec.yaml | awk '{print $2}')

# 🔖 Git version (tag or short commit hash)
GIT_VERSION=$(git describe --tags --always)

# 🌿 Git branch name
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# 📄 Generate Dart file with version and branch
echo "⚙️ Generating lib/git_version.dart..."
mkdir -p lib
cat <<EOF > lib/git_version.dart
/// Auto-generated Git version and branch info
const String gitVersion = '$GIT_VERSION';
const String gitBranch = '$GIT_BRANCH';
EOF

# 🧼 Clean and get dependencies
echo "🧹 Cleaning project..."
flutter clean
flutter pub get

# 🛠️ Choose build type: apk, aab, or web
BUILD_TYPE=${1:-apk}  # default = apk
ARCHITECTURE=${2:-}   # optional: rt9 for arm64-v8a only

# Check if RT9 build is requested
if [ "$ARCHITECTURE" = "rt9" ]; then
  export BUILD_RT9=true
  echo "📱 RT9 build enabled: Building only for arm64-v8a architecture"
fi

echo "🚀 Building $PROJECT_NAME ($GIT_BRANCH → $GIT_VERSION) as $BUILD_TYPE..."

if [ "$BUILD_TYPE" = "apk" ]; then
  if [ "$ARCHITECTURE" = "rt9" ]; then
    flutter build apk --release --target-platform android-arm64
    ORIGINAL_OUTPUT="build/app/outputs/flutter-apk/app-release.apk"
    echo "📦 RT9 APK (arm64-v8a only) available at: $ORIGINAL_OUTPUT"
  else
    flutter build apk --release
    ORIGINAL_OUTPUT="build/app/outputs/flutter-apk/app-release.apk"
    echo "📦 APK available at: $ORIGINAL_OUTPUT"
  fi
elif [ "$BUILD_TYPE" = "aab" ]; then
  if [ "$ARCHITECTURE" = "rt9" ]; then
    flutter build appbundle --release --target-platform android-arm64
    ORIGINAL_OUTPUT="build/app/outputs/bundle/release/app-release.aab"
    echo "📦 RT9 AAB (arm64-v8a only) available at: $ORIGINAL_OUTPUT"
  else
    flutter build appbundle --release
    ORIGINAL_OUTPUT="build/app/outputs/bundle/release/app-release.aab"
    echo "📦 AAB available at: $ORIGINAL_OUTPUT"
  fi
elif [ "$BUILD_TYPE" = "web" ]; then
  # Flutter 3.10+ automatically selects the renderer (HTML by default)
  # The --web-renderer flag was removed in newer Flutter versions
  flutter build web --release
  WEB_OUTPUT_DIR="build/web"
  # ✅ Build output is in build/web as expected by firebase.json
  echo "📦 Web build output: $WEB_OUTPUT_DIR/"
  echo "✅ Web build available in: $WEB_OUTPUT_DIR/"
  echo "   Firebase hosting expects build in: $WEB_OUTPUT_DIR/"
  echo "   Renderer is automatically selected by Flutter"
else
  echo "❌ Invalid build type: $BUILD_TYPE"
  echo "   Supported types: apk, aab, web"
  echo "   Optional: Add 'rt9' as second parameter for arm64-v8a only build"
  exit 1
fi

echo "✅ Build complete!"