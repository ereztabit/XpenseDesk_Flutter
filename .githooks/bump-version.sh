#!/bin/sh
#
# Bump the MINOR component of pubspec.yaml's version and stage the change so it
# lands in the next commit. This is how we tell which build reached production
# (the version is shown at the bottom of the app menu).
#
# Format: version: MAJOR.MINOR.PATCH+BUILD  ->  MINOR is incremented.
# The displayed version is v{MAJOR}.{MINOR} (see lib/providers/app_version_provider.dart).
#
# Run ONLY at feature finish (the `finish-feature` skill calls this), NOT on every
# commit. Mid-feature commits must not bump the version.
#
#   sh .githooks/bump-version.sh
#
set -e

PUBSPEC="pubspec.yaml"
[ -f "$PUBSPEC" ] || { echo "bump-version: $PUBSPEC not found"; exit 1; }

current=$(grep -E '^version: ' "$PUBSPEC" | head -n1 | sed -E 's/^version:[[:space:]]*//')
[ -n "$current" ] || { echo "bump-version: no version line in $PUBSPEC"; exit 1; }

verpart=${current%%+*}            # MAJOR.MINOR.PATCH
build=""
case "$current" in
  *+*) build=${current##*+} ;;    # BUILD (if present)
esac

major=$(echo "$verpart" | cut -d'.' -f1)
minor=$(echo "$verpart" | cut -d'.' -f2)
patch=$(echo "$verpart" | cut -d'.' -f3)
[ -n "$patch" ] || patch=0

newminor=$((minor + 1))
if [ -n "$build" ]; then
  newver="$major.$newminor.$patch+$build"
else
  newver="$major.$newminor.$patch"
fi

# Portable in-place edit (works with both GNU and BSD sed).
sed -i.bak -E "s/^version:[[:space:]]*.*/version: $newver/" "$PUBSPEC"
rm -f "$PUBSPEC.bak"

git add "$PUBSPEC"
echo "bump-version: $current -> $newver"
