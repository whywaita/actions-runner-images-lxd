local os_version = '22_04';

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
      'runs-on': std.format('ubuntu-%s', std.strReplace(os_version, "_", ".")),
      steps: steps_jammy.steps + [
        steps_tmate,
      ],
    },
  },
}
