# How to Use

This document explains how to use LXD images built by actions-runner-images-lxd.

## Table of Contents

- [Building Images Yourself](#building-images-yourself)
- [Getting Pre-built Images](#getting-pre-built-images)
- [Launching Containers](#launching-containers)
- [Integration with myshoes](#integration-with-myshoes)
- [Troubleshooting](#troubleshooting)
- [References](#references)

## Building Images Yourself

If you want to customize the image or build it yourself, you can build images locally using Packer.

### Prerequisites

- LXD installed and configured
- Packer installed
- Sufficient disk space (at least 50GB free)

### Setup

Install required tools:

```bash
# Install LXD (if not already installed)
sudo snap install lxd
sudo lxd init --auto

# Install Packer
# See https://developer.hashicorp.com/packer/downloads
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install packer
```

### Build Process

#### 1. Clone and Prepare

Clone both repositories:

```bash
# Clone actions-runner-images-lxd
git clone https://github.com/whywaita/actions-runner-images-lxd.git
cd actions-runner-images-lxd

# Clone actions/runner-images
git clone --depth 1 https://github.com/actions/runner-images
cd runner-images
```

#### 2. Apply LXD Patch

Apply the LXD-specific patch:

```bash
# Copy and apply the patch
cp ../lxd.patch .
patch -p1 < lxd.patch
```

#### 3. Doing packer

```bash
packer init ./images/ubuntu/templates/
packer validate -syntax-only -only ubuntu-24_04.lxd.build_image_24_04 ./images/ubuntu/templates/

# Build the image (this takes 2-3 hours):

packer build -only ubuntu-24_04.lxd.build_image_24_04 ./images/ubuntu/templates/
```

#### 4. Publish Container as Image

After Packer completes, the container will be in a stopped state. Publish it as an LXD image:

```bash
# Verify the container exists
lxc list

# Publish the container as an image
lxc publish packer-lxd --alias ubuntu-noble-runner
```

#### 5. Verify the Image

Check that the image was created successfully:

```bash
lxc image list
```

You should see your newly created image with the alias `ubuntu-noble-runner`.

## Getting Pre-built Images

### 1. Download from GitHub Actions Artifacts

Builds run automatically every day. The latest builds are available from the following workflow:

- Ubuntu 24.04: [nightly-noble.yaml](https://github.com/whywaita/actions-runner-images-lxd/actions/workflows/nightly-noble.yaml)

Download artifacts from a successful workflow run:

```bash
# Using GitHub CLI
gh run download <run-id> -n virtual-environments-lxd-24_04-<hash>-20251101.zip

# Or access GitHub Actions page via web browser to download
```

### 2. Extract the Artifact

Extract the downloaded zip file:

```bash
unzip virtual-environments-lxd-24_04-<hash>-20251101.zip
```

The extracted directory contains two files:

- `incus.tar.xz`: Metadata and container configuration
- `rootfs.squashfs`: Root filesystem (the actual container contents)

### 3. Import the Image

Images created by distrobuilder use the split format with two separate files. Both files are required for import:

```bash
lxc image import incus.tar.xz rootfs.squashfs --alias ubuntu-noble-runner
```

You can specify any alias name. It's recommended to include version and date:

```bash
lxc image import incus.tar.xz rootfs.squashfs --alias ubuntu-noble-runner-20251101
```

### 4. Verify the Image

Verify the imported image:

```bash
lxc image list
```

## Launching Containers

### Basic Launch

Launch a container from the imported image:

```bash
lxc launch ubuntu-noble-runner my-runner
```

### Launch with Recommended Configuration

When using as a GitHub Actions runner, the following configuration is recommended:

```bash
# Create a profile with security settings
lxc profile create runner

# Configure the profile
# For Docker-in-Docker support
lxc profile set runner security.nesting=true
lxc profile set runner security.syscalls.intercept.mknod=true
lxc profile set runner security.syscalls.intercept.setxattr=true

# Set resource limits if needed
lxc profile set runner limits.cpu=4
lxc profile set runner limits.memory=8GB

# Launch container with the profile
lxc launch ubuntu-noble-runner my-runner --profile default --profile runner
```

## Integration with myshoes

To auto-scale runners using [myshoes](https://github.com/whywaita/myshoes), we recommend using [shoes-lxd-multi](https://github.com/whywaita/shoes-lxd-multi), which provides advanced features for managing multiple LXD instances and resource pools.

Example configuration for using this image with shoes-lxd-multi:

```json
{
  "resource_type": "lxd",
  "image_name": "ubuntu-noble-runner",
  "lxd_host": "http://192.0.2.1:8443",
  "runner_user": "runner"
}
```

Alternatively, you can use the simpler [shoes-lxd](https://github.com/whywaita/myshoes-providers/tree/main/shoes-lxd) provider for basic LXD integration.

## Troubleshooting

### Image Import Fails

Error: `Error: Image already exists with alias 'ubuntu-noble-runner'`

Solution: Delete the existing alias or use a different alias name:

```bash
# Delete existing image
lxc image delete ubuntu-noble-runner

# Or use a different alias name
lxc image import incus.tar.xz rootfs.squashfs --alias ubuntu-noble-runner-new
```

### Insufficient Disk Space

LXD images are large (approximately 25GB). Ensure you have sufficient disk space:

```bash
# Check storage pools
lxc storage list

# Delete unused old images
lxc image list
lxc image delete <fingerprint>
```

## References

- [actions/runner-images](https://github.com/actions/runner-images) - Original runner images project
- [myshoes](https://github.com/whywaita/myshoes) - GitHub Actions auto-scaling system
- [shoes-lxd-multi](https://github.com/whywaita/shoes-lxd-multi) - Advanced LXD provider for myshoes (recommended)
- [shoes-lxd](https://github.com/whywaita/myshoes-providers/tree/main/shoes-lxd) - Simple LXD provider for myshoes
- [LXD Documentation](https://linuxcontainers.org/lxd/docs/latest/) - Official LXD documentation
