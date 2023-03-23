local steps_focal = (import './lib/step.libsonnet')('images/linux/ubuntu2004.json');

{
  name: 'Build image - focal',
  on: {
    pull_request: {},
    workflow_dispatch: {},
  },
  jobs: {
    'build-focal': steps_focal {
      'runs-on': 'ubuntu-20.04',
    },
  },
}
