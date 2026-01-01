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

echo "🚀 Building $PROJECT_NAME ($GIT_BRANCH → $GIT_VERSION) as $BUILD_TYPE..."

if [ "$BUILD_TYPE" = "apk" ]; then
  flutter build apk --release
  ORIGINAL_OUTPUT="build/app/outputs/flutter-apk/app-release.apk"
  echo "📦 APK available at: $ORIGINAL_OUTPUT"
elif [ "$BUILD_TYPE" = "aab" ]; then
  flutter build appbundle --release
  ORIGINAL_OUTPUT="build/app/outputs/bundle/release/app-release.aab"
  echo "📦 AAB available at: $ORIGINAL_OUTPUT"
elif [ "$BUILD_TYPE" = "web" ]; then
  flutter build web --release
  WEB_OUTPUT_DIR="build/web"
  FINAL_OUTPUT_DIR="${PROJECT_NAME}_web_${GIT_BRANCH}_${GIT_VERSION}"
  # ✅ Copy the web build to a versioned directory
  echo "📦 Web build output: $FINAL_OUTPUT_DIR/"
  cp -r "$WEB_OUTPUT_DIR" "$FINAL_OUTPUT_DIR"
  echo "✅ Web build available in: $FINAL_OUTPUT_DIR/"
  echo "   Deploy the contents of this directory to your web server"
else
  echo "❌ Invalid build type: $BUILD_TYPE"
  echo "   Supported types: apk, aab, web"
  exit 1
fi

echo "✅ Build complete!"