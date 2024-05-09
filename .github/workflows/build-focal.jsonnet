local os_version = '20.04';

local steps_focal = (import './lib/step.libsonnet')(os_version);
local steps_tmate = (import './lib/tmate.libsonnet');

{
  name: 'Build image - focal',
  on: {
    pull_request: {},
    workflow_dispatch: {},
  },
  jobs: {
    'build-focal': steps_focal {
      'runs-on': std.format('ubuntu-%s', os_version),
      steps: steps_focal.steps + [
        steps_tmate,
      ],
    },
  },
}
