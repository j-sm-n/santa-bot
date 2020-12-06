class User < ApplicationRecord
  def partners
    partner_ids = Partnership.where(partner_one_id: id)
      .or(Partnership.where(partner_two_id: id))
      .pluck(:partner_one_id, :partner_two_id)
      .uniq
      .flatten - [id]

    User.where(id: partner_ids)
  end

  def secret_santa
    SecretSantaPair.find_by(recipient_id: id)&.secret_santa
  end

  def recipient
    SecretSantaPair.find_by(secret_santa_id: id)&.recipient
  end
end
