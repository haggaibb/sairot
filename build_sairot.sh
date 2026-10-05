#!/bin/bash
set -e  # Exit on any error

# apk | aab | web, plus optional rt9 / --rt9 for an arm64-only tablet APK
BUILD_TYPE="apk"
PLATFORM_FLAG=""
PLATFORM_SUFFIX=""

for arg in "$@"; do
  case $arg in
    --rt9|--tr9|rt9)
      PLATFORM_FLAG="--target-platform android-arm64"
      PLATFORM_SUFFIX="_rt9"
      export BUILD_RT9=true
      ;;
    apk|aab|web)
      BUILD_TYPE="$arg"
      ;;
    --help|-h)
      echo "Usage: $0 [apk|aab|web] [rt9|--rt9]"
      echo "  rt9, --rt9, --tr9   arm64-only APK for the RT9 tablet (smaller than the universal APK)"
      exit 0
      ;;
    *)
      echo "❌ Unknown option: $arg"
      echo "Usage: $0 [apk|aab|web] [rt9|--rt9]"
      exit 1
      ;;
  esac
done

if [ -n "$PLATFORM_SUFFIX" ] && [ "$BUILD_TYPE" != "apk" ]; then
  echo "❌ rt9 only applies to an APK build"
  exit 1
fi

# 📁 Ensure we're at the Flutter project root
cd "$(dirname "$0")"

# 🎯 Extract project name and version from pubspec.yaml
PROJECT_NAME=$(grep '^name:' pubspec.yaml | awk '{print $2}')
APP_VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')

# 🔖 Git version (tag or short commit hash)
GIT_VERSION=$(git describe --tags --always 2>/dev/null || echo "unknown")

# 🌿 Git branch name
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

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

if [ -n "$PLATFORM_SUFFIX" ]; then
  echo "📱 Platform: arm64-v8a only (RT9)"
fi

echo "🚀 Building $PROJECT_NAME ($GIT_BRANCH → $GIT_VERSION) as $BUILD_TYPE..."

if [ "$BUILD_TYPE" = "apk" ]; then
  flutter build apk --release $PLATFORM_FLAG
  ORIGINAL_OUTPUT="build/app/outputs/flutter-apk/app-release.apk"
  NAMED_APK="${PROJECT_NAME}_${APP_VERSION}${PLATFORM_SUFFIX}.apk"
  FINAL_OUTPUT="build/app/outputs/flutter-apk/${NAMED_APK}"
  # Flutter always writes app-release.apk. Replace that file with the versioned name.
  mv "$ORIGINAL_OUTPUT" "$FINAL_OUTPUT"
  cp "$FINAL_OUTPUT" "$NAMED_APK"
  echo ""
  echo "📦 APK ready: $NAMED_APK"
elif [ "$BUILD_TYPE" = "aab" ]; then
  flutter build appbundle --release
  ORIGINAL_OUTPUT="build/app/outputs/bundle/release/app-release.aab"
  FINAL_OUTPUT="${PROJECT_NAME}_${GIT_BRANCH}_${GIT_VERSION}.aab"
  echo "📦 Output: $FINAL_OUTPUT"
  cp "$ORIGINAL_OUTPUT" "$FINAL_OUTPUT"
elif [ "$BUILD_TYPE" = "web" ]; then
  flutter build web --release
  WEB_OUTPUT_DIR="build/web"
  echo "📦 Web build output: $WEB_OUTPUT_DIR/"
  echo "✅ Web build available in: $WEB_OUTPUT_DIR/"
  echo "   Firebase hosting expects build in: $WEB_OUTPUT_DIR/"
else
  echo "❌ Invalid build type: $BUILD_TYPE"
  echo "   Supported types: apk, aab, web"
  exit 1
fi

echo "✅ Build complete!"
