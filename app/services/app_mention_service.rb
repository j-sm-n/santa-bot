class AppMentionService
  COMMANDS = %i[].freeze
  IM_CHANNEL_TYPE = "im"

  attr_reader :event_params, :user

  def initialize(event_params, user)
    @event_params = event_params
    @user = user
  end

  def handle_message
    return unless message_sent_in_im?

    if user.address.blank?
      response.push(
        "It looks like I don't have your address on file. Please respond with your address so that your secret " \
        "santa :shushing_face: knows where to send your gift."
      )
    end
    # send(command)
  end

  def respond
    slack_response = post_message(
      channel: event_params[:channel],
      text: response.join("\n"),
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

  def message_sent_in_im?
    event_params[:channel_type] == IM_CHANNEL_TYPE
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

  def response
    @response ||= ["Merry christmas, <@#{user.slack_id}>! :santa: :christmas_tree:"]
  end
end
