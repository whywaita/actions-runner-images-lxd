# actions-runner-images-lxd

actions-runner-images-lxd build a runner image for [LXD](https://linuxcontainers.org/lxd/introduction/).

[actions/runner-images](https://github.com/actions/runner-images) is source code of [GitHub-hosted Runner](https://docs.github.com/en/actions/reference/specifications-for-github-hosted-runners) in GitHub Actions.

## Workflows

|Build|Build Status|
|:-:|:-:|
|Ubuntu 20.04 nightly build|[![nightly build](https://github.com/whywaita/actions-runner-images-lxd/actions/workflows/nightly-focal.yaml/badge.svg)](https://github.com/whywaita/actions-runner-images-lxd/actions/workflows/nightly-focal.yaml)|
|Ubuntu 22.04 nightly build|[![nightly build](https://github.com/whywaita/actions-runner-images-lxd/actions/workflows/nightly-jammy.yaml/badge.svg)](https://github.com/whywaita/actions-runner-images-lxd/actions/workflows/nightly-jammy.yaml)|
|Ubuntu 24.04 nightly build|[![nightly build](https://github.com/whywaita/actions-runner-images-lxd/actions/workflows/nightly-noble.yaml/badge.svg)](https://github.com/whywaita/actions-runner-images-lxd/actions/workflows/nightly-noble.yaml)|

## How to generate `lxd.patch`

```bash
## Clone original repository
$ git clone https://github.com/actions/runner-images

## Apply lxd.patch
$ cp ${path_to_whywaita/actions-runner-images-lxd}/lxd.patch .
$ patch -p1 < lxd.patch

## Modify files
<snip>

## Check diff
$ git diff
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   images/linux/scripts/installers/configure-environment.sh
        modified:   images/linux/scripts/installers/dotnetcore-sdk.sh
        modified:   images/linux/scripts/installers/homebrew.sh
        modified:   images/linux/ubuntu2004.json

## Generate `lxd.patch`
$ git diff HEAD > lxd.patch
```
