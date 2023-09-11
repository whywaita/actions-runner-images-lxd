{
  name: 'Notify',
  uses: 'slackapi/slack-github-action@v1',
  with: {
    payload: |||
      {
        "text": 'Build actions-image-runner-lxd ${{ job.status }}',
        "blocks": [
          {
            "type": "section",
            "fields": [
              {
                "type": "mrkdwn",
                "text": "*Repository*: <https://github.com/whywaita/actions-runner-images-lxd|whywaita/actions-runner-images-lxd>"
              },
              {
                "type": "mrkdwn",
                "text": "<${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}|View action>"
              }
            ]
          }
        ]
      }
    |||,
  },
  env: {
    SLACK_WEBHOOK_URL: '${{ secrets.SLACK_WEBHOOK_URL }}',
    SLACK_WEBHOOK_TYPE: 'INCOMING_WEBHOOK'
  }
}
