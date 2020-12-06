class Partnership < ApplicationRecord
  belongs_to :partner_one, class_name: "User"
  belongs_to :partner_two, class_name: "User"
end
