local os_version = '20.04';

local steps_focal = (import './lib/step.libsonnet')(os_version);
local steps_notify = (import './lib/notify.libsonnet');

{
  name: 'Build image (nightly) - focal',
  on: {
    schedule: [
      {
        cron: '0 22 * * *',  // The start of builld is 7:00 AM JST. We wish to end until 10:00 AM JST.
      },
    ],
    workflow_dispatch: {},
  },
  jobs: {
    'build-focal': steps_focal {
      'runs-on': std.format('ubuntu-%s', os_version),
      steps: steps_focal.steps + [
        steps_notify,
      ],
    },
  },
}
