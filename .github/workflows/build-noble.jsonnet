local os_version = '24.04';

local steps_noble = (import './lib/step.libsonnet')(os_version);
local steps_tmate = (import './lib/tmate.libsonnet');

{
  name: 'Build image - noble',
  on: {
    pull_request: {},
    workflow_dispatch: {},
  },
  jobs: {
    'build-noble': steps_noble {
      'runs-on': std.format('ubuntu-%s', os_version),
      steps: steps_noble.steps + [
        steps_tmate,
      ],
    },
  },
}
