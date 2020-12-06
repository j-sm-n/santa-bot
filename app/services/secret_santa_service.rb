class SecretSantaService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def send_introduction
    initiate_conversation

    return false if user.dm_channel_id.blank?

    responses = introduction_snippets.map do |snippet|
      resp = send_dm(snippet)
      sleep(5)
      resp[:ok]
    end

    responses.all?(true)
  end

  private

  def initiate_conversation
    return if user.dm_channel_id.present?

    dm_channel_id = get_dm_channel_id

    user.update(dm_channel_id: dm_channel_id)
  end

  def get_dm_channel_id
    response = slack_msgr.conversations(
      :open,
      token: slack_msgr.configuration.access_tokens[:bot],
      users: user.slack_id,
    )

    return unless response[:ok]

    response[:channel][:id]
  end

  def send_dm(text)
    slack_msgr.chat(:post_message, text: text, channel: user.dm_channel_id)
  end

  def slack_msgr
    Rails.configuration.slack_msgr
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

end
