class User < ApplicationRecord
  def partners
    partner_ids = Partnership.where(partner_one_id: id)
      .or(Partnership.where(partner_two_id: id))
      .pluck(:partner_one_id, :partner_two_id)
      .uniq
      .flatten - [id]

    User.where(id: partner_ids)
  end
end
