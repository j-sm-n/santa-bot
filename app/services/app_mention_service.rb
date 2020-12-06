class AppMentionService
  COMMANDS = %i[signup partners pairsantas start].freeze
  IM_CHANNEL_TYPE = "im"
  ADMIN_SLACK_ID = "UG72JMSDD"
  ERROR_MESSAGE = "Oh no! There's too much ginger bread between my ears... something went wrong and that makes me a sad santa :disappointed:"

  attr_reader :event_params, :user

  def initialize(event_params, user)
    @event_params = event_params
    @user = user
  end

  def handle_message
    return unless message_sent_in_im? || (command.present? && user.slack_id == ADMIN_SLACK_ID)

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

  def message_sent_in_im?
    event_params[:channel_type] == IM_CHANNEL_TYPE
  end

  private

  def signup
    signed_up_users = command_list.map do |raw_user|
      add_user(raw_user)
    end

    response.push("I added #{signed_up_users.join(", ")} to my list... and I'm checking it twice :wink: :sparkles:")
  end

  def partners
    command_list.each do |raw_partners|
      add_partnership(raw_partners)
    end

    response.push("I've made a note of all the partners :heart:")
  end

  def pairsantas
    if SecretSantaPairService.new.go!
      response.push(
        "I've made my list and checked it twice. All of you good boys and girls have been assigned a secret santa. :wink: :shushing_face:\n" \
        "Simply tell me to `start`. :gift: I will message all of the participants individually telling them their secret santa."
      )
    else
      response.push(ERROR_MESSAGE)
    end
  end

  def start
    User.all.each do |user|
      secret_santa_service = SecretSantaService.new(user)
      secret_santa_service.send_introduction
    end
  end

  def command_list
    @command_list ||= event_params[:text].scan(/(?<=\[).*?(?=\])/).first.split(",")
  end

  def handle_direct_message
    response.push("I will deliver your message to, <@#{user.recipient.slack_id}>, your recipient. When they respond, I'll deliver the message here.")
  end

  def add_user(raw_user)
    name = raw_user.split(":").first
    slack_id = raw_user.scan(/<([^>]*)>/).flatten.first.sub("@", "")

    User.find_or_create_by(name: name, slack_id: slack_id).name
  end

  def add_partnership(raw_partners)
    partner_slack_ids = raw_partners.gsub("@", "").scan(/<([^>]*)>/).flatten
    users = User.where(slack_id: partner_slack_ids)

    Partnership.create(partner_one: users.first, partner_two: users.last)
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
