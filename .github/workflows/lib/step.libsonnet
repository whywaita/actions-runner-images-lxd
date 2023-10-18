function(packer_def_path) {
  steps: [
    { uses: 'actions/checkout@v3' },
    { uses: 'whywaita/workflow-telemetry-action@add-disk-space' },
    { uses: 'Kesin11/actions-timeline@v1' },
    { uses: 'whywaita/setup-lxd@v1' },
    {
      name: 'Setup packer',
      shell: 'bash',
      run: |||
        sudo apt-get install -y wget unzip
        curl -L -O https://releases.hashicorp.com/packer/1.7.0/packer_1.7.0_linux_amd64.zip
        unzip packer_1.7.0_linux_amd64.zip
        mv ./packer /tmp/packer
        chmod +x /tmp/packer
        rm -rf packer_1.7.0_linux_amd64.zip
      |||,
    },
    {
      name: 'Setup packer-plugin-lxd',
      shell: 'bash',
      run: |||
        wget https://github.com/hashicorp/packer-plugin-lxd/releases/download/v1.0.1/packer-plugin-lxd_v1.0.1_x5.0_linux_amd64.zip
        unzip packer-plugin-lxd_v1.0.1_x5.0_linux_amd64.zip
        mv packer-plugin-lxd_v1.0.1_x5.0_linux_amd64 /tmp/packer-plugin-lxd
        chmod +x /tmp/packer-plugin-lxd
        rm -f packer-plugin-lxd_v1.0.1_x5.0_linux_amd64.zip
      |||,
    },
    {
      name: 'Setup distrobuilder',
      shell: 'bash',
      run: 'sudo snap install distrobuilder --classic',
    },
    {
      name: 'Delete unused file',
      shell: 'bash',
      run: |||
        sudo rm -rf /opt/
        sudo rm -rf /usr/local/*
        sudo rm -rf /usr/local/.ghcup
        sudo rm -rf /usr/lib/jvm /usr/lib/google-cloud-sdk
        sudo rm -rf /home/runneradmin /home/linuxbrew
        sudo rm -rf /home/runner/runners/*.tar.gz
        # ignore /var/run, snap lxd packages, apt
        sudo ls /var/**/** | grep ":" | tr -d ":" | grep -Ev "/var/run|/var/snap/lxd|/var/lib/snapd|/var/lib/dpkg" |  xargs -I%% sudo rm -rf %%
        # ignore /usr/share/dpkg
        ls /usr/share/ | grep -vE "dpkg|debconf|dbus" | xargs -I%% sudo rm -rf /usr/share/%%
      |||,
    },
    {
      name: 'Display storage information',
      shell: 'bash',
      run: 'df -Th',
    },
    {
      name: 'Clone actions/runner-images',
      shell: 'bash',
      run: |||
        git clone --depth 1 https://github.com/actions/runner-images
        cd runner-images
        export DIR=$(pwd)
        echo "dir=${DIR}" >> $GITHUB_ENV
        echo "virtual-environments-hash=$(git rev-parse --short HEAD)" >> $GITHUB_ENV
        echo "build-date=$(date '+%Y%m%d')" >> $GITHUB_ENV
        echo "os-release=$(cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -d'=' -f2)" >> $GITHUB_ENV
      |||,
    },
    {
      name: 'Clear duplicate entry in nftables (only jammy)',
      shell: 'bash',
      'if': "${{ env.os-release == '22.04' }}",
      run: |||
        # ref: https://discuss.linuxcontainers.org/t/lxdbr0-firewall-problem-with-ubuntu-22-04-host-running-docker-and-lxd/15298/9
        sudo nft flush ruleset
        sudo systemctl restart snap.lxd.daemon
      |||,
    },
    {
      name: 'Apply LXD patch',
      shell: 'bash',
      run: |||
        cp ../lxd.patch .
        patch -p1 < lxd.patch
      |||,
      'working-directory': '${{ env.dir }}',
    },
    {
      name: 'packer validate packer.json',
      shell: 'bash',
      run: std.format('/tmp/packer validate -syntax-only %s', packer_def_path),
      'working-directory': '${{ env.dir }}',
    },
    {
      name: 'packer build packer.json',
      shell: 'bash',
      run: std.format('PATH=$PATH:/tmp /tmp/packer build -on-error=abort %s', packer_def_path),
      'working-directory': '${{ env.dir }}',
      env: {
        PACKER_LOG: 1,
      },
    },
    {
      name: 'Stop container',
      shell: 'bash',
      run: 'lxc stop packer-lxd',
    },
    {
      name: 'Remove swap',
      shell: 'bash',
      run: |||
        sudo swapoff /mnt/swapfile
        sudo rm -rf /mnt/swapfile
      |||,
    },
    {
      name: 'Build by distrobuilder',
      shell: 'bash',
      run: |||
        sudo mkdir -p /mnt/cache
        sudo mkdir -p /mnt/output
        sudo distrobuilder pack-lxd distrobuilder-def.yaml "/var/snap/lxd/common/lxd/storage-pools/default/containers/packer-lxd" /mnt/output --cache-dir /mnt/cache

        set -x
        ls -l /mnt/output
      |||,
    },
    {
      name: 'Remove container',
      shell: 'bash',
      run: 'lxc delete packer-lxd',
    },
    {
      name: 'Upload artifact',
      uses: 'actions/upload-artifact@v3',
      with: {
        name: 'virtual-environments-lxd-${{ env.os-release }}-${{ env.virtual-environments-hash }}-${{ env.build-date }}.zip',
        path: '/mnt/output/*',
        'retention-days': 5,
      },
    },
  ],
}
