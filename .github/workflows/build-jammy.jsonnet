local os_version = '22.04';

local steps_jammy = (import './lib/step.libsonnet')(os_version);
local steps_tmate = (import './lib/tmate.libsonnet');

{
  name: 'Build image - jammy',
  on: {
    pull_request: {},
    workflow_dispatch: {},
  },
  jobs: {
    'build-jammy': steps_jammy {
      'runs-on': std.format('ubuntu-%s', os_version),
      steps: steps_jammy.steps + [
        steps_tmate,
      ],
    },
  },
}
