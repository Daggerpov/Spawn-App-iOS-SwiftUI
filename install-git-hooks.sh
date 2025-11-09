#!/bin/bash

# Script to install git hooks for automatic Swift code formatting
# Run this script once after cloning the repository

set -e

echo "Installing git hooks for Swift formatting..."

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOOKS_DIR="$SCRIPT_DIR/.git/hooks"

# Check if we're in a git repository
if [ ! -d "$SCRIPT_DIR/.git" ]; then
    echo "Error: Not in a git repository root"
    exit 1
fi

# Check if swift-format is available
if ! command -v xcrun swift-format &> /dev/null; then
    echo "Warning: swift-format not found. Please ensure Xcode is installed."
    echo "Continuing with hook installation anyway..."
fi

# Create pre-commit hook
echo "Creating pre-commit hook..."
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/sh

# Pre-commit hook to format Swift files
# This hook will automatically format staged Swift files before committing

echo "Running Swift format on staged files..."

# Get the root directory of the git repository
ROOT_DIR=$(git rev-parse --show-toplevel)

# Path to swift-format configuration
CONFIG_FILE="$ROOT_DIR/.swift-format"

# Check if swift-format is available
if ! command -v xcrun swift-format &> /dev/null; then
    echo "Warning: swift-format not found. Skipping formatting."
    exit 0
fi

# Get list of staged Swift files
STAGED_SWIFT_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.swift$')

if [ -z "$STAGED_SWIFT_FILES" ]; then
    echo "No Swift files to format."
    exit 0
fi

# Format each staged Swift file
for file in $STAGED_SWIFT_FILES; do
    if [ -f "$ROOT_DIR/$file" ]; then
        xcrun swift-format format --configuration "$CONFIG_FILE" --in-place "$ROOT_DIR/$file"
        git add "$ROOT_DIR/$file"
    fi
done

echo "✓ Staged Swift files have been formatted and re-staged."
exit 0
EOF

# Create pre-push hook
echo "Creating pre-push hook..."
cat > "$HOOKS_DIR/pre-push" << 'EOF'
#!/bin/sh

# Pre-push hook to format Swift files
# This hook will automatically format all Swift files before pushing

echo "Running Swift format on all files..."

# Get the root directory of the git repository
ROOT_DIR=$(git rev-parse --show-toplevel)

# Path to swift-format configuration
CONFIG_FILE="$ROOT_DIR/.swift-format"

# Check if swift-format is available
if ! command -v xcrun swift-format &> /dev/null; then
    echo "Warning: swift-format not found. Skipping formatting."
    exit 0
fi

# Format all Swift files
find "$ROOT_DIR/Spawn-App-iOS-SwiftUI" -name "*.swift" -type f -not -path "*/Preview Content/*" -exec xcrun swift-format format --configuration "$CONFIG_FILE" --in-place {} \;
find "$ROOT_DIR/Spawn-App-iOS-SwiftUITests" "$ROOT_DIR/Spawn-App-iOS-SwiftUIUITests" -name "*.swift" -type f -exec xcrun swift-format format --configuration "$CONFIG_FILE" --in-place {} \; 2>/dev/null

# Check if any files were modified
if ! git diff --quiet; then
    echo ""
    echo "✓ Swift files have been formatted."
    echo ""
    echo "The following files were modified:"
    git diff --name-only
    echo ""
    echo "These changes have NOT been staged or committed."
    echo "Please review, stage, and commit them before pushing again."
    echo ""
    exit 1
fi

echo "✓ All Swift files are properly formatted."
exit 0
EOF

# Make hooks executable
chmod +x "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-push"

echo ""
echo "✓ Git hooks installed successfully!"
echo ""
echo "The following hooks are now active:"
echo "  - pre-commit: Formats staged Swift files"
echo "  - pre-push: Formats all Swift files"
echo ""
echo "See docs/git-formatting-hooks.md for more information."

