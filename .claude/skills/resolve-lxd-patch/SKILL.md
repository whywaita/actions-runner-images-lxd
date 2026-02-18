---
name: resolve-lxd-patch
description: Resolve conflicts when lxd.patch cannot be applied to the latest upstream actions/runner-images. Regenerates a clean patch while preserving all LXD-specific modifications.
allowed-tools: Bash(git:*), Bash(git worktree:*), Bash(patch:*), Bash(mktemp:*), Bash(cp:*), Bash(rm -rf:*), Read, Edit, Glob, Grep
---

# Resolve lxd.patch Conflicts

## Step 1: Verify Repository State

Check the current repository state before starting:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
git status
```

- Ensure no uncommitted changes exist that could interfere.
- Confirm `lxd.patch` exists at the repository root.

## Step 2: Clean Up Merged Worktrees

Clean up any previously created worktrees whose branches have already been merged to master:

```bash
# List resolve-lxd-patch worktrees
git worktree list | grep 'resolve-lxd-patch-'

# Find branches that are merged to master
git branch --merged master | grep 'fix/resolve-lxd-patch-'

# For each merged branch, remove the worktree and branch
# git worktree remove .worktrees/<name>
# git branch -d fix/<name>

# Prune stale worktree references
git worktree prune
```

For each worktree matching `resolve-lxd-patch-*`:
1. Check if the corresponding branch `fix/resolve-lxd-patch-*` is merged to master.
2. If merged, run `git worktree remove` and `git branch -d` to clean up.
3. If not merged, leave it as-is (it may contain in-progress work).

## Step 3: Create Worktree and Set Up Working Environment

Create a date-stamped worktree for the patch update, then set up a temporary upstream clone:

```bash
DATE=$(date +%Y%m%d)
BRANCH_NAME="fix/resolve-lxd-patch-${DATE}"
WORKTREE_NAME="resolve-lxd-patch-${DATE}"
WORKTREE_DIR=$REPO_ROOT/.worktrees/$WORKTREE_NAME
```

If the worktree already exists (same-day re-run), reuse it. Otherwise create it:

```bash
if [ ! -d "$WORKTREE_DIR" ]; then
  git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" origin/master
fi
```

Then clone upstream into a temporary directory:

```bash
TEMP_DIR=$(mktemp -d)
echo "Repository root: $REPO_ROOT"
echo "Worktree directory: $WORKTREE_DIR"
echo "Temp directory: $TEMP_DIR"

cd $TEMP_DIR
git clone https://github.com/actions/runner-images.git
cd runner-images
git checkout main
```

## Step 4: Attempt Patch Application

Copy and apply the current patch from the worktree:

```bash
cp $WORKTREE_DIR/lxd.patch .
patch -p1 < lxd.patch
```

**If patch applies cleanly (exit code 0):** Skip to Step 7 (no conflicts to resolve).

**If patch fails:** Proceed to Step 5.

## Step 5: Analyze Conflicts

Identify and read all `.rej` files to understand what failed:

```bash
find . -name "*.rej" -type f
```

For each `.rej` file:
1. Read the `.rej` file to see the intended changes.
2. Read the corresponding upstream file to understand the new structure.
3. Determine why the hunk failed (context mismatch, file restructure, removed code, etc.).

## Step 6: Resolve Conflicts

For each conflicting file, manually apply the intended LXD changes to the upstream file.

### LXD-Specific Changes to Preserve

These modifications are critical and must be maintained in the updated patch:

- **Runner user creation**: `runner` user identification and setup
- **LXD-specific provisioners**: LXD source blocks replacing Azure-ARM provisioners
- **Azure waagent disabling**: Commenting out Azure-specific configurations
- **fuse-overlayfs enablement**: Container-specific storage configuration
- **Homebrew installation**: Running as `runner` user
- **File provisioner adjustments**: Trailing slashes and separate destination paths
- **Docker group membership**: Adding `runner` to docker group
- **Test execution**: Running as `runner` user with proper environment
- **Variable cleanup**: Removing Azure-specific variables

### When to Ask the User

Use `AskUserQuestion` in these situations:

- **Structural changes**: Upstream has significantly restructured files/directories that our patch modifies.
- **Logic conflicts**: Upstream logic changes conflict with LXD modifications and the right precedence is unclear.
- **New Azure-specific features**: New Azure features appear that may need to be disabled/adapted for LXD.
- **Removed files**: Upstream removed files that our patch modifies.
- **Dependency changes**: Upstream changed dependencies that may affect LXD modifications.

## Step 7: Generate and Validate New Patch

Generate the new patch from the resolved changes:

```bash
git add -A
git diff HEAD > $TEMP_DIR/lxd-new.patch
```

If changes are unstaged (e.g., from manual edits without `git add`):

```bash
git diff > $TEMP_DIR/lxd-new.patch
```

Validate by applying to a fresh clone:

```bash
cd $TEMP_DIR
git clone https://github.com/actions/runner-images.git runner-images-verify
cd runner-images-verify
git checkout main
patch -p1 < $TEMP_DIR/lxd-new.patch
echo "Exit code: $?"
```

Validation must pass all of:
- Exit code is 0
- No `.rej` files created (`find . -name "*.rej" -type f` returns nothing)
- All expected files are modified

If validation fails, return to Step 6 and fix remaining issues.

## Step 8: Update Worktree and Confirm

Copy the validated patch to the worktree and verify:

```bash
cp $TEMP_DIR/lxd-new.patch $WORKTREE_DIR/lxd.patch
cd $WORKTREE_DIR
git status
git diff lxd.patch
```

Confirm the diff looks correct and all LXD-specific modifications are present.

The updated patch is now in the worktree at `$WORKTREE_DIR`. From here, the user can commit and create a PR using the worktree branch.

## Step 9: Cleanup and Report

Remove the temporary directory (keep the worktree):

```bash
rm -rf $TEMP_DIR
```

Produce a summary report in this format:

```
## Upstream Changes Summary

**Worktree**: $WORKTREE_DIR
**Branch**: $BRANCH_NAME

### <filename>
- **Upstream change**: <what upstream modified>
- **Old structure**: <previous code structure>
- **New structure**: <new code structure>
- **Resolution**: <how the LXD patch was adapted>

(Repeat for each conflicting file)
```

The worktree is ready for commit and PR creation. The user can `cd $WORKTREE_DIR` to review, commit, and push.
