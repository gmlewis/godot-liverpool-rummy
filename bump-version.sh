#!/bin/bash

# bump-version.sh - Automatically bump version numbers in export_presets.cfg and global.gd

set -e  # Exit on error

EXPORT_PRESETS="export_presets.cfg"
GLOBAL_GD="global.gd"

# Check if required files exist
if [[ ! -f "$EXPORT_PRESETS" ]]; then
    echo "Error: $EXPORT_PRESETS not found" >&2
    exit 1
fi

if [[ ! -f "$GLOBAL_GD" ]]; then
    echo "Error: $GLOBAL_GD not found" >&2
    exit 1
fi

# Extract current version/code from export_presets.cfg
OLDVERSION=$(grep "^version/code=" "$EXPORT_PRESETS" | head -1 | cut -d'=' -f2)

if [[ -z "$OLDVERSION" ]]; then
    echo "Error: Could not find version/code in $EXPORT_PRESETS" >&2
    exit 1
fi

if ! [[ "$OLDVERSION" =~ ^[0-9]+$ ]]; then
    echo "Error: version/code is not a valid integer: $OLDVERSION" >&2
    exit 1
fi

# Calculate new version
NEWVERSION=$((OLDVERSION + 1))
NEW_VERSION_STRING="0.${NEWVERSION}.0"

echo "Bumping version from $OLDVERSION to $NEWVERSION" >&2
echo "New version string: $NEW_VERSION_STRING" >&2

# Update version/code in export_presets.cfg
if ! sed -i.bak "s/^version\/code=${OLDVERSION}$/version\/code=${NEWVERSION}/" "$EXPORT_PRESETS"; then
    echo "Error: Failed to update version/code in $EXPORT_PRESETS" >&2
    exit 1
fi
echo "Updated version/code in $EXPORT_PRESETS: $OLDVERSION -> $NEWVERSION" >&2

# Update version/name in export_presets.cfg
if ! sed -i.bak "s/^version\/name=\".*\"$/version\/name=\"${NEW_VERSION_STRING}\"/" "$EXPORT_PRESETS"; then
    echo "Error: Failed to update version/name in $EXPORT_PRESETS" >&2
    exit 1
fi
echo "Updated version/name in $EXPORT_PRESETS: -> \"$NEW_VERSION_STRING\"" >&2

# Update const VERSION in global.gd
if ! sed -i.bak "s/^const VERSION = '.*'$/const VERSION = '${NEW_VERSION_STRING}'/" "$GLOBAL_GD"; then
    echo "Error: Failed to update VERSION in $GLOBAL_GD" >&2
    exit 1
fi
echo "Updated const VERSION in $GLOBAL_GD: -> '$NEW_VERSION_STRING'" >&2

# Remove backup files
rm -f "${EXPORT_PRESETS}.bak" "${GLOBAL_GD}.bak"

echo "Version bump completed successfully!" >&2
exit 0
