class SecretSantaPair < ApplicationRecord
  validates :secret_santa_id, uniqueness: true
  validates :recipient_id, uniqueness: true

  belongs_to :secret_santa, class_name: "User"
  belongs_to :recipient, class_name: "User"
end
