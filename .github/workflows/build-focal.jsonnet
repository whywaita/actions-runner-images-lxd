local steps_focal = (import './lib/step.libsonnet')('images/ubuntu/templates/ubuntu-20.04.pkr.hcl');

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
