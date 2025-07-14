local packer_def_path(os_version) = std.format('images/ubuntu/templates/build.ubuntu-%s.pkr.hcl', os_version);

function(os_version) {
  steps: [
    { uses: 'actions/checkout@v4' },
    { uses: 'catchpoint/workflow-telemetry-action@v2' },
    { uses: 'Kesin11/actions-timeline@v2' },
    { uses: 'whywaita/setup-lxd@v1' },
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

        sudo mkdir -p /opt
        sudo chmod 777 /opt
      |||,
    },
    { uses: 'hashicorp/setup-packer@main' },
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
      name: 'packer init',
      shell: 'bash',
      run: 'packer init ./images/ubuntu/templates/',
      'working-directory': '${{ env.dir }}',
    },
    {
      name: 'packer validate packer.json',
      shell: 'bash',
      run: std.format('packer validate -syntax-only -only ubuntu-%s.lxd.build_image ./images/ubuntu/templates/', os_version),
      'working-directory': '${{ env.dir }}',
    },
    {
      name: 'packer build packer.json',
      shell: 'bash',
      run: std.format('packer build -only ubuntu-%s.lxd.build_image ./images/ubuntu/templates/', os_version),
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
        sudo distrobuilder pack-incus distrobuilder-def.yaml "/var/snap/lxd/common/lxd/storage-pools/default/containers/packer-lxd" /mnt/output --cache-dir /mnt/cache

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
      uses: 'actions/upload-artifact@v4',
      with: {
        name: std.format('virtual-environments-lxd-%s-${{ env.virtual-environments-hash }}-${{ env.build-date }}.zip', os_version),
        path: '/mnt/output/*',
        'retention-days': 5,
      },
    },
    {
      name: 'Upload SoftwareReport.md',
      uses: 'actions/upload-artifact@v4',
      with: {
        name: std.format('Ubuntu%s-Readme.md', std.strReplace(os_version, "_", "")),
        path: std.format('./runner-images/images/ubuntu/Ubuntu%s-Readme.md', std.strReplace(os_version, "_", "")),
        'retention-days': 5,
      },
    },
    {
      name: 'Upload software-report.json',
      uses: 'actions/upload-artifact@v4',
      with: {
        name: 'software-report.json',
        path: './runner-images/images/ubuntu/software-report.json',
        'retention-days': 5,
      },
    },
  ],
}
