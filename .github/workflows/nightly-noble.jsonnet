local steps_noble = (import './lib/step.libsonnet')('images/ubuntu/templates/ubuntu-24.04.pkr.hcl');

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
    'build-jammy': steps_noble {
      'runs-on': 'ubuntu-22.04',
      steps: steps_noble.steps + [
        steps_notify,
      ],
    },
  },
}
