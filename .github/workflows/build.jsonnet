local steps_focal = (import './lib/step.libsonnet')('images/linux/ubuntu2004.json');
local steps_jammy = (import './lib/step.libsonnet')('images/linux/ubuntu2204.pkr.hcl');

{
  name: 'Build image',
  on: {
    pull_request: {},
    workflow_dispatch: {},
  },
  jobs: {
    'build-focal': steps_focal {
      'runs-on': 'ubuntu-20.04',
    },
    'build-jammy': steps_jammy {
      'runs-on': 'ubuntu-22.04',
    },
  },
}
