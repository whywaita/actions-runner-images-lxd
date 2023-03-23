local steps_jammy = (import './lib/step.libsonnet')('images/linux/ubuntu2204.pkr.hcl');

{
  name: 'Build image - jammy',
  on: {
    pull_request: {},
    workflow_dispatch: {},
  },
  jobs: {
    'build-jammy': steps_jammy {
      'runs-on': 'ubuntu-22.04',
    },
  },
}
