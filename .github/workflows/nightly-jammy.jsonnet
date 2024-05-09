local os_version = '22.04';

local steps_jammy = (import './lib/step.libsonnet')(os_version);
local steps_notify = (import './lib/notify.libsonnet');

{
  name: 'Build image (nightly) - jammy',
  on: {
    schedule: [
      {
        cron: '0 22 * * *',  // The start of builld is 7:00 AM JST. We wish to end until 10:00 AM JST.
      },
    ],
    workflow_dispatch: {},
  },
  jobs: {
    'build-jammy': steps_jammy {
      'runs-on': std.format('ubuntu-%s', os_version),
      steps: steps_jammy.steps + [
        steps_notify,
      ],
    },
  },
}
