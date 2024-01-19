local steps_jammy = (import './lib/step.libsonnet')('images/ubuntu/templates/ubuntu-22.04.pkr.hcl');
local steps_tmate = (import './lib/tmate.libsonnet');

{
  name: 'Build image - jammy',
  on: {
    pull_request: {},
    workflow_dispatch: {},
  },
  jobs: {
    'build-jammy': steps_jammy {
      'runs-on': 'ubuntu-22.04',
      steps: steps_jammy.steps + [
        steps_tmate,
      ],
    },
  },
}
