class AppMentionService
  COMMANDS = %i[signup].freeze
  IM_CHANNEL_TYPE = "im"

  attr_reader :event_params, :user

  def initialize(event_params, user)
    @event_params = event_params
    @user = user
  end

  def handle_message
    return unless message_sent_in_im? || (command.present? && valid_command?)

    if message_sent_in_im?
      handle_direct_message
    else
      send(command)
    end
  end

  def respond
    slack_response = post_message(
      channel: event_params[:channel],
      text: response.join("\n"),
    )
    slack_response[:ok]
  end

  private

  def signup
    raw_user_list = event_params[:text].scan(/(?<=\[).*?(?=\])/).first

    signed_up_users = raw_user_list.split(", ").map do |raw_user|
      add_user(raw_user)
    end

    response.push("I added #{signed_up_users.join(", ")} to my list... and I'm checking it twice :wink: :sparkles:")
  end

  def handle_direct_message
    if user.address.blank?
      response.push(
        "It looks like I don't have your address on file. Please respond with your address so that your secret " \
        "santa :shushing_face: knows where to send your gift."
      )
    end
  end

  def add_user(raw_user)
    name = raw_user.split(":").first
    slack_id = raw_user.scan(/<([^>]*)>/).flatten.first.sub("@", "")

    User.find_or_create_by(name: name, slack_id: slack_id).name
  end

  def valid_command?
    {
      signup: user.slack_id == "UG72JMSDD",
    }[command]
  end

  def message_sent_in_im?
    event_params[:channel_type] == IM_CHANNEL_TYPE
  end

  def command
    @command ||= COMMANDS.find do |command|
      event_params[:text].include?(command.to_s)
    end
  end

  def sanitized_timestamp
    Time.use_zone("Pacific Time (US & Canada)") { Time.zone.at(event_params[:ts].to_f) }
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
