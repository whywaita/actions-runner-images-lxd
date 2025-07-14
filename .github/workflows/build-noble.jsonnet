local os_version = '24_04';

local steps_noble = (import './lib/step.libsonnet')(os_version);
local steps_tmate = (import './lib/tmate.libsonnet');

{
  name: 'Build image - noble',
  on: {
    pull_request: {},
    workflow_dispatch: {},
  },
  env: {
    PACKER_GITHUB_API_TOKEN: '${{ secrets.GITHUB_TOKEN }}'
  },
  jobs: {
    'build-noble': steps_noble {
      'runs-on': std.format('ubuntu-%s', std.strReplace('22_04', "_", ".")), // TODO: replace to os_version after released GitHub-hosted runner
      steps: steps_noble.steps + [
        steps_tmate,
      ],
    },
  },
}
