class SecretSantaPairService
  def go!
    initial_secret_santa_pair_count = SecretSantaPair.count
    pairs = pair_up_participants

    ActiveRecord::Base.transaction do
      pairs.each do |pair|
        SecretSantaPair.create(secret_santa: pair.first, recipient: pair.last)
      end
    end

    SecretSantaPair.count > initial_secret_santa_pair_count
  end

  private

  def pair_up_participants
    recipients = users.values.shuffle
    users.values.shuffle.map do |secret_santa|
      valid_recipients = recipients.shuffle - secret_santa.partners.to_a.push(secret_santa)

      return pair_up_participants if valid_recipients.count.zero?

      recipient = recipients.delete(valid_recipients.first)
      [secret_santa, recipient]
    end
  end

  def users
    @users ||= User.all.reduce({}) do |result, user|
      result[user.id] = user
      result
    end
  end
end
