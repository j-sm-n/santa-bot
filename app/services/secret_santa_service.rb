class SecretSantaService
  SECRET_SANTA_BOT_ID = "U01GEG9T46L"

  attr_reader :user, :direct_message_response

  def initialize(user)
    @user = user
    @direct_message_response
    @recipient_is_secret_santa = false
  end

  def handle_message(raw_text:, mentioned_ids:)
    unless mentioned_ids.one?
      set_unknown_recipient_response(mentioned_ids.count)
      return
    end

    recipient = get_recipient(mentioned_ids.first)
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

    response = send_dm(introduction_snippets.join("\n\n"))

    response[:ok]
  end

  def send_message(to:, text:)
    return {ok: false} if to.nil?

    initiate_conversation(to)

    return {ok: false} if user.dm_channel_id.blank?

    text = generate_direct_message_text(to, text)
    post_message(
      channel: to.dm_channel_id,
      text: text
    )
  end

  private

  def recipient_is_secret_santa?
    @recipient_is_secret_santa
  end

  def initiate_conversation(init_user)
    return if init_user.dm_channel_id.present?

    dm_channel_id = get_dm_channel_id(init_user.slack_id)

    init_user.update(dm_channel_id: dm_channel_id)
  end

  def get_recipient(mentioned_id)
    @recipient_is_secret_santa = mentioned_id == SECRET_SANTA_BOT_ID

    if !recipient_is_secret_santa? && mentioned_id != user.recipient.slack_id
      set_unable_to_send_to_user_response(mentioned_id)
      return
    end

    return user.secret_santa if recipient_is_secret_santa?

    User.find_by(slack_id: mentioned_id)
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

  def generate_direct_message_text(recipient, text)
    return "#{dm_recipient_response_intro}>#{text}\n\n#{dm_recipient_response_info}" if recipient_is_secret_santa?

    "#{dm_gift_recipient_intro}>#{text}\n\n#{dm_response_info}"
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
    @direct_message_response ||= if recipient_is_secret_santa?
      "Thank you for your response. I'm sending it over to my Secret Santa helper. If they have any more messages, I will deliver them to you."
    else
      "Your message is on the way to your gift recipient <@#{recipient.slack_id}>! I'll notify you when they respond."
    end
  end

  def set_failed_response(recipient)
    @direct_message_response ||= if recipient_is_secret_santa?
      "Ugh... I think I've run out of magic. I couldn't deliver your message to my Secret Santa helper. Please try again later. :disappointed:"
    else
      "Ugh... I think I've run out of magic. I couldn't deliver your message to <@#{recipient.slack_id}>. Please try again later. :disappointed:"
    end
  end

  def set_unknown_recipient_response(count)
    @direct_message_response ||= if count.zero?
      "Who do you want me to send this message to? Don't forget to include <@#{user.recipient.slack_id}> to send a message to your gift recipient."
    else
      "Whoa! Pull my beard and call me an elf, I can't send that many messages. Please only have one person included in your message below to send your message. For example: \"<@#{user.recipient.slack_id}> What would you like for Christmas?\""
    end
  end

  def set_unable_to_send_to_user_response(mentioned_id)
    @direct_message_response = "I know my brain is full of candy canes, but I can't send a message to <@#{mentioned_id}> since they aren't your gift recipient.\n\nI can only send messages to your <@#{SECRET_SANTA_BOT_ID}> or your gift recipient <@#{user.recipient.slack_id}>."
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
    "To respond, simply begin your message with '<@#{SECRET_SANTA_BOT_ID}>', and I'll send your response to your Seret Santa."
  end

  def dm_recipient_response_intro
    "Your gift recipient, <@#{user.slack_id}>, responded to your message. Here's what they said:\n\n"
  end

  def dm_recipient_response_info
    "If you want to send any more messages to them, just begin the message with their Slack handle <@#{user.slack_id}>."
  end
end
