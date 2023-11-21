local steps_focal = (import './lib/step.libsonnet')('images/ubuntu/templates/ubuntu-20.04.json');

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
      'runs-on': 'ubuntu-20.04',
      steps: steps_focal.steps + [
        steps_notify,
      ],
    },
  },
}
