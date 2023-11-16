class User
  include Mongoid::Document

  field :telegram_id, type: Integer
  has_many :assistants

  # Другие поля, например:
  # field :name, type: String
end