class SecretSantaService
  SECRET_SANTA_BOT_ID = "U01GEG9T46L"

  attr_reader :user, :direct_message_response

  def initialize(user)
    @user = user
    @direct_message_response
  end

  def handle_message(raw_text:, mentioned_ids:)
    unless mentioned_ids.one?
      set_unknown_recipient_response(mentioned_ids.count)
      return
    end

    recipient = User.find_by(slack_id: mentioned_ids.first)
    message = raw_text.sub(/<([^>]*)>/, "").strip
    response = send_message(to: recipient, text: message)

    if response[:ok]
      set_successful_response(recipient)
    else
      set_failed_response(recipient)
    end
  end

  def send_introduction
    initiate_conversation(user)

    return false if user.dm_channel_id.blank?

    responses = introduction_snippets.map do |snippet|
      resp = send_dm(snippet)
      sleep(5)
      resp[:ok]
    end

    responses.all?(true)
  end

  def send_message(to:, text:)
    initiate_conversation(to)

    return false if to.dm_channel_id.blank?

    post_message(
      channel: to.dm_channel_id,
      text: "#{dm_gift_recipient_intro}>#{text}\n\n#{dm_response_info}"
    )
  end

  private

  def initiate_conversation(init_user)
    return if init_user.dm_channel_id.present?

    dm_channel_id = get_dm_channel_id(init_user.slack_id)

    init_user.update(dm_channel_id: dm_channel_id)
  end

  def get_dm_channel_id(slack_id)
    response = slack_msgr.conversations(
      :open,
      token: slack_msgr.configuration.access_tokens[:bot],
      users: slack_id,
    )

    return unless response[:ok]

    response[:channel][:id]
  end

  def post_message(**opts)
    slack_msgr.chat(:post_message, opts)
  end

  def send_dm(text)
    slack_msgr.chat(:post_message, text: text, channel: user.dm_channel_id)
  end

  def slack_msgr
    Rails.configuration.slack_msgr
  end

  def set_successful_response(recipient)
    @direct_message_response = "Your message is on the way to <@#{recipient.slack_id}>! I'll notify you when they respond."
  end

  def set_failed_response(recipient)
    @direct_message_response = "Ugh... I think I've run out of magic. I couldn't deliver your message to <@#{recipient.slack_id}>. Please try again later. :disappointed:"
  end

  def set_unknown_recipient_response(count)
    @direct_message_response = if count.zero?
      "Who do you want me to send this message to? Don't forget to include <@#{user.recipient.slack_id}> to send a message to your gift recipient."
    else
      "Whoa! Pull my beard and call me an elf, I can't send that many messages. Please only have one person included in your message below to send your message. For example: \"<@#{user.recipient.slack_id}> What would you like for Christmas?\""
    end
  end

  def introduction_snippets
    [
      "Ho ho ho! Nice to meet you, #{user.name}. I'm Secret Santa :dark_sunglasses: :santa:",
      "You've been selected to be one of my special helpers this year. You see, COVID-19 has made delivering gifts a lot more difficult. Between all the elves working from home and Rudolph in quarantine after attending the super spreader reindeer games, I need all the help I can get. That's where you come in.",
      "You're going to be a Secret Santa helper, and I need you to get a fun, special gift for *#{user.recipient.name}* (<@#{user.recipient.slack_id}>).",
      "Now, remember, do not tell anyone who you're giving your gift to... we're \"*SECRET*\" Santas, not \"big-mouth, tell everyone everything\" santas. :face_with_rolling_eyes: You'd be surprised how many people forget that... :face_with_hand_over_mouth:",
      "In any case, to help you out, I'll be a liason between you and your recipient. Just begin your message with <@#{user.recipient.slack_id}> and everything you write, I will deliver to #{user.recipient.name} as myself. When they respond, I will tell you what they said. Also, I will deliver messages from my Secret Santa helper who is sending you a gift. If you have any questions, ask my special buddy Ryan Workman. He's been helping me out a ton!",
      "Alright! Thanks for all the help!!! Let's send our first message to your recipient, simply type \"<@#{user.recipient.slack_id}> Where should I send your gift?\" and click `Send`.",
      ":gift: :santa: :christmas_tree:"
    ]
  end

  def dm_gift_recipient_intro
    "Ho ho ho! Merry Christmas and season's greetings. My Secret Santa helper has a message for you below.\n\n"
  end

  def dm_response_info
    "To repond, simply begin your message with '<@#{SECRET_SANTA_BOT_ID}>', and I'll send your response to your Seret Santa."
  end
end
