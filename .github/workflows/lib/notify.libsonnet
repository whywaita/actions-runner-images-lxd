{
  name: 'Notify status',
  uses: 'lazy-actions/slatify@master',
  with: {
    job_name: 'Build actions-image-runner-lxd',
    type: '${{ job.status }}',
    icon_emoji: ':octocat:',
    url: '${{ secrets.SLACK_WEBHOOK_URL }}',
    token: '${{ secrets.token }}',
  },
}
