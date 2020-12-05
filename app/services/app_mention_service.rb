class AppMentionService
  COMMANDS = %i[].freeze

  attr_reader :event_params, :declared_response

  def initialize(event_params, declared_response)
    @event_params = event_params
    @declared_response = declared_response
  end

  def handle_message
    declare_response(declared_response)
    # return unless command.present? && valid_command?
    #
    # send(command)
  end

  def respond
    slack_response = post_message(
      channel: event_params[:channel],
      text: response,
    )
    slack_response[:ok]
  end

  private

  def valid_command?
    {
      record: (stripped_text.count == 1 && stripped_text.first.to_i.positive?),
      whatsup: stripped_text.count.zero?,
    }[command]
  end

  def command
    @command ||= COMMANDS.find do |command|
      sanitized_text.include?(command.to_s)
    end
  end

  def sanitized_timestamp
    Time.use_zone("Pacific Time (US & Canada)") { Time.zone.at(event_params[:ts].to_f) }
  end

  def sanitized_text
    event_params[:text].gsub(/\s*<[^()]*\>\s*/, " ").gsub(/[^0-9A-Za-z\s]/, "").downcase
  end

  def stripped_text
    sanitized_text.gsub(/\s*#{command}\s*/, "").split(" ").reject(&:empty?)
  end

  def post_message(**opts)
    slack_msgr.chat(:post_message, opts)
  end

  def slack_msgr
    Rails.configuration.slack_msgr
  end

  def declare_response(response)
    @response = response
  end

  def response
    @response ||= "I'm sorry. I didn't quite get that. " \
                  "Please type `@MrStalky help` for a list of the commands I understand."
  end
end
