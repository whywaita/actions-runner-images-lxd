local steps_noble = (import './lib/step.libsonnet')('images/ubuntu/templates/ubuntu-24.04.pkr.hcl');
local steps_tmate = (import './lib/tmate.libsonnet');

{
  name: 'Build image - noble',
  on: {
    pull_request: {},
    workflow_dispatch: {},
  },
  jobs: {
    'build-noble': steps_noble {
      'runs-on': 'ubuntu-22.04',
      steps: steps_noble.steps + [
        steps_tmate,
      ],
    },
  },
}
