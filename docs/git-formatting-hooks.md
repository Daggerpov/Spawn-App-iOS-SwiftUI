# Git Formatting Hooks

This repository uses Git hooks to automatically format Swift code before commits and pushes.

## Overview

Two git hooks are configured to maintain consistent code formatting:

1. **pre-commit hook** - Formats staged Swift files before each commit
2. **pre-push hook** - Formats all Swift files before pushing

## Configuration

The formatting uses Apple's `swift-format` tool with settings defined in `.swift-format` at the project root.

### Formatting Settings:
- **Indentation**: Tabs (not spaces)
- **Tab width**: 4 spaces (for display)
- **Line length**: 120 characters
- **Style**: Apple Swift standard conventions

## How It Works

### Pre-Commit Hook
- Runs automatically when you execute `git commit`
- Only formats the Swift files you're about to commit
- Automatically re-stages formatted files
- Commits proceed with formatted code

### Pre-Push Hook
- Runs automatically when you execute `git push`
- Formats ALL Swift files in the project
- If files are modified:
  - Push is blocked
  - You're notified of changes
  - You must review, stage, commit, and push again
- If no changes needed, push proceeds normally

## Usage

The hooks run automatically - no action needed! Just commit and push as usual.

```bash
# Make changes to Swift files
git add .
git commit -m "Your commit message"  # Pre-commit hook formats staged files
git push                              # Pre-push hook ensures all files are formatted
```

## Bypassing Hooks (Not Recommended)

If you need to bypass the hooks temporarily:

```bash
# Skip pre-commit hook
git commit --no-verify -m "Your message"

# Skip pre-push hook
git push --no-verify
```

**Warning**: Only bypass hooks if absolutely necessary, as it may introduce inconsistent formatting.

## Troubleshooting

### Hook not running?

Check if hooks are executable:
```bash
ls -la .git/hooks/pre-commit
ls -la .git/hooks/pre-push
```

Both should show `rwx` permissions. If not:
```bash
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-push
```

### swift-format not found?

Ensure you have Xcode installed. The hooks use `xcrun swift-format` which comes with Xcode.

### Want to manually format all files?

```bash
find Spawn-App-iOS-SwiftUI -name "*.swift" -type f -not -path "*/Preview Content/*" -exec xcrun swift-format format --configuration .swift-format --in-place {} \;
```

## Hook Locations

- Pre-commit: `.git/hooks/pre-commit`
- Pre-push: `.git/hooks/pre-push`
- Configuration: `.swift-format`

## Notes

- Hooks are local to each clone (not tracked in git)
- Each team member needs to set up hooks manually
- The `.swift-format` configuration file IS tracked in git

