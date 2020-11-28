# Be sure to restart your server when you modify this file.

SlackMsgr.configure do |config|
  config.verification_token = ENV['SLACK_VERIFICATION_TOKEN']
  config.client_secret      = ENV['SLACK_CLIENT_SECRET']
  config.signing_secret     = ENV['SLACK_SIGNING_SECRET']
  config.access_tokens      = {
    bot: ENV['BOT_ACCESS_TOKEN']
  }
end

Rails.application.configure do
  config.slack_msgr = SlackMsgr
end
