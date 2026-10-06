// Notify a failing job to Discord.
//
// Replaces the Slack incoming-webhook notification (slackapi/slack-github-action).
// Discord has no official GitHub action, so the message goes out with curl against
// an incoming webhook URL, using Discord's own payload format ("embeds").
//
// Gated on failure(): the nightly build is supposed to be green, so only a failure
// is worth reporting. Steps default to `if: success()`, so without this key the
// notification would never fire on a failing job.
{
  name: 'Notify failure to Discord',
  'if': 'failure()',
  shell: 'bash',
  env: {
    DISCORD_WEBHOOK_URL: '${{ secrets.DISCORD_WEBHOOK_URL }}',
  },
  // Discord answers 204 on success and 400 with a JSON body on a malformed payload,
  // so curl must fail the step on a non-2xx response instead of swallowing it.
  run: |||
    set -euo pipefail

    if [ -z "${DISCORD_WEBHOOK_URL:-}" ]; then
      echo "::error::DISCORD_WEBHOOK_URL is not set for this repository"
      exit 1
    fi

    cat > discord-payload.json <<'EOF'
    {
      "embeds": [
        {
          "title": "${{ github.workflow }} failed",
          "url": "${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}",
          "color": 15158332,
          "fields": [
            {
              "name": "Job",
              "value": "`${{ github.job }}`",
              "inline": true
            },
            {
              "name": "Ref",
              "value": "`${{ github.ref_name }}`",
              "inline": true
            },
            {
              "name": "Run",
              "value": "[#${{ github.run_number }}](${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }})",
              "inline": true
            }
          ],
          "footer": {
            "text": "${{ github.repository }}"
          }
        }
      ]
    }
    EOF

    jq -e . discord-payload.json > /dev/null

    curl -sS --fail-with-body -X POST \
      -H 'Content-Type: application/json' \
      --data @discord-payload.json \
      "$DISCORD_WEBHOOK_URL"
  |||,
}
