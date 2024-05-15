local os_version = '24.04';

local steps_noble = (import './lib/step.libsonnet')(os_version);
local steps_notify = (import './lib/notify.libsonnet');

{
  name: 'Build image (nightly) - noble',
  on: {
    schedule: [
      {
        cron: '0 22 * * *',  // The start of builld is 7:00 AM JST. We wish to end until 10:00 AM JST.
      },
    ],
    workflow_dispatch: {},
  },
  jobs: {
    'build-noble': steps_noble {
      'runs-on': std.format('ubuntu-%s', os_version),
      steps: steps_noble.steps + [
        steps_notify,
      ],
    },
  },
}
