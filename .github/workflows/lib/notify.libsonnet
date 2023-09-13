{
  name: 'Notify',
  uses: 'slackapi/slack-github-action@v1',
  with: {
    payload: |||
      {
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "Build actions-image-runner-lxd ${{ github.workflow }} is ${{ job.status }}"
            }
          },
          {
            "type": "section",
            "fields": [
              {
                "type": "mrkdwn",
                "text": "*Repository*: <https://github.com/whywaita/actions-runner-images-lxd|whywaita/actions-runner-images-lxd>"
              },
              {
                "type": "mrkdwn",
                "text": ":arrow_right: <${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}|View action>"
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
