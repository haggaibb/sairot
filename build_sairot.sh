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

# 🛠️ Choose build type: apk or aab
BUILD_TYPE=${1:-apk}  # default = apk

echo "🚀 Building $PROJECT_NAME ($GIT_BRANCH → $GIT_VERSION) as $BUILD_TYPE..."

if [ "$BUILD_TYPE" = "apk" ]; then
  flutter build apk --release
  ORIGINAL_OUTPUT="build/app/outputs/flutter-apk/app-release.apk"
  FINAL_OUTPUT="${PROJECT_NAME}_${GIT_BRANCH}_${GIT_VERSION}.apk"
elif [ "$BUILD_TYPE" = "aab" ]; then
  flutter build appbundle --release
  ORIGINAL_OUTPUT="build/app/outputs/bundle/release/app-release.aab"
  FINAL_OUTPUT="${PROJECT_NAME}_${GIT_BRANCH}_${GIT_VERSION}.aab"
else
  echo "❌ Invalid build type: $BUILD_TYPE"
  exit 1
fi

# ✅ Copy and rename the output file
echo "📦 Output: $FINAL_OUTPUT"
cp "$ORIGINAL_OUTPUT" "$FINAL_OUTPUT"

echo "✅ Build complete!"