local os_version = '26_04';

local steps_resolute = (import './lib/step.libsonnet')(os_version);
local steps_tmate = (import './lib/tmate.libsonnet');

{
  name: 'Build image - resolute',
  on: {
    pull_request: {},
    workflow_dispatch: {},
  },
  env: {
    PACKER_GITHUB_API_TOKEN: '${{ secrets.GITHUB_TOKEN }}'
  },
  jobs: {
    'build-resolute': steps_resolute {
      // The LXD-based build runs on ubuntu-22.04, same as build-noble.
      // TODO: switch to ubuntu-26.04 after it is available as a GitHub-hosted runner
      'runs-on': 'ubuntu-22.04',
      steps: steps_resolute.steps + [
        steps_tmate,
      ],
    },
  },
}
