# Task: Resolve lxd.patch Conflicts with Upstream

## Overview

This document provides instructions for resolving conflicts when the `lxd.patch` file cannot be applied to the latest upstream `actions/runner-images` repository. This task should be executed by an Agent when upstream updates cause patch application failures.

## Objective

Update `lxd.patch` to be compatible with the latest upstream changes from `github.com/actions/runner-images` (main branch).

## Prerequisites

- Git installed and configured
- Sufficient disk space for temporary repository clone
- `patch` command available
- Current working directory: repository root

## Task Steps

### 1. Verify Current State

Before starting, verify the current repository state:

```bash
git status
```

Ensure there are no uncommitted changes that might interfere with the process.

### 2. Create Temporary Working Directory

Create a temporary directory for upstream clone and save the current repository path:

```bash
REPO_ROOT=$(pwd)
TEMP_DIR=$(mktemp -d)
echo "Repository root: $REPO_ROOT"
echo "Working directory: $TEMP_DIR"
```

### 3. Clone Upstream Repository

Clone the upstream `actions/runner-images` repository:

```bash
cd $TEMP_DIR
git clone https://github.com/actions/runner-images.git
cd runner-images
git checkout main
```

### 4. Attempt to Apply Current Patch

Copy the current `lxd.patch` and attempt to apply it:

```bash
cp $REPO_ROOT/lxd.patch .
patch -p1 < lxd.patch
```

**Expected outcomes:**
- **Success**: Patch applies cleanly � No action needed, cleanup and exit
- **Failure**: Conflicts detected � Proceed to conflict resolution

### 5. Analyze Conflicts

If the patch fails, identify which files have conflicts:

```bash
# The patch command will output failed hunks
# Review the .rej files created for each failed file
find . -name "*.rej" -type f
```

Read each `.rej` file to understand what changes failed to apply.

### 6. Resolve Conflicts

For each conflicting file:

1. **Read the original file** in the upstream repository
2. **Read the corresponding .rej file** to see what changes were intended
3. **Manually apply the changes** from the .rej file to the upstream file
4. **Verify the changes** make sense in the new context

**Key changes to preserve from lxd.patch:**

- **Runner user creation**: Changes to ensure `runner` user is correctly identified
- **LXD-specific provisioners**: Addition of LXD source blocks instead of Azure-ARM
- **Azure waagent disabling**: Commenting out Azure-specific configurations
- **fuse-overlayfs enablement**: Container-specific storage configuration
- **Homebrew installation**: Running as `runner` user
- **File provisioner adjustments**: Adding trailing slashes and separate destination paths
- **Docker group membership**: Adding `runner` to docker group
- **Test execution**: Running as `runner` user with proper environment
- **Variable cleanup**: Removing Azure-specific variables

### 7. Generate New Patch

After resolving all conflicts and applying changes manually:

```bash
# Stage all changes
git add -A

# Create the new patch in TEMP_DIR
git diff HEAD > $TEMP_DIR/lxd-new.patch
```

If you used `patch --merge` or manually edited files, create a diff from the modified files:

```bash
# Compare modified working directory to HEAD
git diff > $TEMP_DIR/lxd-new.patch
```

### 8. Validate New Patch

Test the newly generated patch on a fresh clone:

```bash
cd $TEMP_DIR
rm -rf actions-runner-images
git clone https://github.com/actions/runner-images.git
cd actions-runner-images
git checkout main

# Apply the new patch
patch -p1 < ../lxd-new.patch
echo "Exit code: $?"
```

**Validation criteria:**
- Exit code should be 0
- No `.rej` files created
- All expected files are modified

### 9. Update lxd.patch in Repository

If validation succeeds, update the patch file:

```bash
cp $TEMP_DIR/lxd-new.patch $REPO_ROOT/lxd.patch
```

### 10. Verify in Repository Context

Return to the repository and verify:

```bash
cd $REPO_ROOT

# Check git status
git status

# Review the diff
git diff lxd.patch
```

### 11. Cleanup

Remove temporary directory:

```bash
rm -rf $TEMP_DIR
```

### 12. Report Upstream Changes

In your final task completion report, include a summary of what changes were made in the upstream repository that required patch updates. This helps maintain project documentation and understanding of upstream evolution.

**Report should include:**

1. **List of files where conflicts occurred**
   - Example: `images/ubuntu/scripts/build/install-dotnetcore-sdk.sh`

2. **Nature of upstream changes**
   - Describe what the upstream modified (e.g., "Removed conditional branch for .NET 6.0", "Restructured provisioner blocks", etc.)
   - Explain the original upstream code structure vs. the new structure

3. **How conflicts were resolved**
   - Explain what adjustments were made to adapt the LXD patch to the new upstream structure
   - Note any functional changes or behavior modifications

4. **Example format:**
   ```
   ## Upstream Changes Summary

   ### install-dotnetcore-sdk.sh
   - **Upstream change**: Removed `if [[ $version == "6.0" ]]` conditional branch, simplifying SDK collection logic
   - **Old structure**: Separate handling for .NET 6.0 vs other versions
   - **New structure**: Unified SDK collection for all versions
   - **Resolution**: Applied `release-date >= "YYYY-MM-DD"` filter to the simplified code structure (2 lines instead of 3)
   ```

## Success Criteria

- `lxd.patch` file is updated in the repository
- The new patch applies cleanly to the latest upstream main branch
- No `.rej` files are created during patch application
- All LXD-specific modifications are preserved

## Questions to Ask Human If Needed

If the Agent encounters situations requiring human judgment:

1. **Structural changes in upstream**: "The upstream has significantly restructured [file/directory]. Should I adapt our LXD modifications to the new structure, or maintain compatibility with the old structure?"

2. **Conflicting logic**: "The upstream has changed [specific functionality] in a way that conflicts with our LXD modifications. Which approach should take precedence?"

3. **New Azure-specific features**: "The upstream has added new Azure-specific features in [file]. Should these be disabled/adapted for LXD, or left as-is?"

4. **Removed files**: "The upstream has removed [file] that our patch modifies. Should I remove these changes from the patch, or find an alternative location?"

5. **Dependency changes**: "The upstream has changed dependencies/prerequisites for [component]. Our LXD modifications may need adjustment. Should I investigate further or preserve existing behavior?"

## Troubleshooting

### Patch Command Returns Non-Zero Exit Code

- Check if files mentioned in the patch exist in upstream
- Review `.rej` files for specific hunk failures
- Consider if upstream has renamed or moved files

### Git Diff Produces Empty Patch

- Ensure changes were actually made to tracked files
- Use `git status` to verify modified files
- Try `git diff HEAD` instead of `git diff`

### Validation Fails After Generating New Patch

- Review the changes in the new patch file
- Ensure all intended modifications are present
- Check for syntax errors or incomplete changes

## Notes

- This process may take 30-60 minutes depending on the extent of upstream changes
- Always preserve the core LXD-specific modifications (see section 6)
- When in doubt, ask the human for clarification rather than making assumptions
- Document any significant changes or decisions made during conflict resolution

## Related Files

- `lxd.patch` - The patch file to be updated
- `CLAUDE.md` - Project overview and architecture
- `.github/workflows/*.jsonnet` - Workflow definitions that use the patched images
- `gen-workflow.sh` - Workflow generation script
