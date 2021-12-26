require 'singleton'
require 'faraday'

module DBLChecker
  module Adapters
    module Persistance
      class Slack
        include Singleton

        def initialize
          @webhook_url = DBLChecker.configuration.slack_webhook_url
          @headers = { Accept: 'application/json', 'Content-Type': 'application/json' }
        end

        def call(check)
          raise DBLChecker::Errors::ConfigError, 'Must configure a Slack webhook URL' if @webhook_url.nil?
          return if check.error.blank?

          Faraday.post(
            @webhook_url,
            failure_template(check).to_json,
            @headers,
          )
        rescue StandardError => e
          raise DBLChecker::Errors::ServerError, "Failed to notify Slack. Error: #{e.message}"
        end

        private

        # https://app.slack.com/block-kit-builder/T9PAX51DM#%7B%22blocks%22:%5B%7B%22type%22:%22header%22,%22text%22:%7B%22type%22:%22plain_text%22,%22text%22:%22:octagonal_sign:%20Checker%20Failed!%20$ENV_job_klass%22,%22emoji%22:true%7D%7D,%7B%22type%22:%22divider%22%7D,%7B%22type%22:%22section%22,%22fields%22:%5B%7B%22type%22:%22mrkdwn%22,%22text%22:%22*error*:%5Cn%20$DBL_CHECK_error%22%7D,%7B%22type%22:%22mrkdwn%22,%22text%22:%22*app%20version*:%5Cn%20$DBL_CHECK_app_version%22%7D,%7B%22type%22:%22mrkdwn%22,%22text%22:%22*timeout%20after%20seconds*:%5Cn%20$DBL_CHECK_timeout_after_seconds%22%7D,%7B%22type%22:%22mrkdwn%22,%22text%22:%22*execution%20time%20in%20ms*:%5Cn%20$DBL_CHECK_execution_time_in_ms%22%7D,%7B%22type%22:%22mrkdwn%22,%22text%22:%22*name*:%5Cn%20$DBL_CHECK_name%22%7D,%7B%22type%22:%22mrkdwn%22,%22text%22:%22*description*:%5Cn%20$DBL_CHECK_description%22%7D,%7B%22type%22:%22mrkdwn%22,%22text%22:%22*finished%20at*:%5Cn%20$DBL_CHECK_finished_at%22%7D%5D%7D,%7B%22type%22:%22section%22,%22text%22:%7B%22type%22:%22mrkdwn%22,%22text%22:%22Check%20the%20following%20runbook%20on%20how%20to%20handle%20this%20failure:%22%7D,%22accessory%22:%7B%22type%22:%22button%22,%22text%22:%7B%22type%22:%22plain_text%22,%22text%22:%22Runbook%22%7D,%22value%22:%22click_me_123%22,%22url%22:%22https://google.com%22,%22action_id%22:%22button-action%22%7D%7D%5D%7D
        # rubocop:disable Metrics/MethodLength
        def failure_template(check)
          # Slack fails if this is a blank string, null, or not a URL
          # The failure is impossible to debug: `status: 400, response_body: "no_text"`
          button_link = check.runbook.presence || 'https://github.com/dbl-works/checker'
          button_link = "https://#{button_link}" unless button_link.start_with?('http')

          {
            blocks: [
              {
                type: 'header',
                text: {
                  type: 'plain_text',
                  text: ":octagonal_sign: #{check.job_klass} Failed!",
                  emoji: true,
                },
              },
              {
                type: 'divider',
              },
              {
                type: 'section',
                fields: [
                  {
                    type: 'mrkdwn',
                    text: "*error*:\n #{check.error}",
                  },
                  {
                    type: 'mrkdwn',
                    text: "*environment*:\n #{DBLChecker.configuration.environment}",
                  },
                  {
                    type: 'mrkdwn',
                    text: "*app version*:\n #{check.app_version}",
                  },
                  {
                    type: 'mrkdwn',
                    text: "*timeout after seconds*:\n #{check.timeout_after_seconds}",
                  },
                  {
                    type: 'mrkdwn',
                    text: "*execution time in ms*:\n #{check.execution_time_in_ms}",
                  },
                  {
                    type: 'mrkdwn',
                    text: "*name*:\n #{check.name}",
                  },
                  {
                    type: 'mrkdwn',
                    text: "*description*:\n #{check.description}",
                  },
                  {
                    type: 'mrkdwn',
                    text: "*finished at*:\n #{check.finished_at}",
                  },
                ],
              },
              {
                type: 'section',
                text: {
                  type: 'mrkdwn',
                  text: 'Check the following runbook on how to handle this failure:',
                },
                accessory: {
                  type: 'button',
                  text: {
                    type: 'plain_text',
                    text: 'Runbook',
                  },
                  value: check.id, # must not be blank, else Slack fails
                  url: button_link,
                  action_id: check.id,
                },
              },
            ],
          }
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
