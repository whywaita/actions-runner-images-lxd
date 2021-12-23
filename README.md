# virtual-environments-lxd

virtual-environments-lxd build a runner image for [LXD](https://linuxcontainers.org/lxd/introduction/).

[actions/virtual-environments](https://github.com/actions/virtual-environments) is source code of [GitHub-hosted Runner](https://docs.github.com/en/actions/reference/specifications-for-github-hosted-runners) in GitHub Actions.

## Workflows

|Build|Build Status|
|:-:|:-:|
|Ubuntu 20.04 nightly build|[![nightly build](https://github.com/whywaita/virtual-environments-lxd/actions/workflows/nightly_build_lxd_image.yaml/badge.svg)](https://github.com/whywaita/virtual-environments-lxd/actions/workflows/nightly_build_lxd_image.yaml)|

## How to generate `lxd.patch`

```bash
## Clone original repository
$ git clone https://github.com/actions/virtual-environments

## Apply lxd.patch
$ cp ${path_to_whywaita/virtual-environments-lxd}/lxd.patch .
$ patch -p1 < lxd.patch

## Modify files
<snip>

## Check diff
$ git status                                                                                                                                                                                                                                                                                     [~/go/src/github.com/actions/virtual-environments]
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
