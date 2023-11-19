class UserTelegram
  include Mongoid::Document

  field :telegram_id, type: Integer
  field :telegram_username, type: String
  field :daily_limit, type: Integer, default: ENV['MESSAGE_AMOUNT_DAY_LIMIT'].to_i
  field :message_day_length_limit, type: Integer, default: ENV['MESSAGE_DAY_LENGTH_LIMIT'].to_i
  field :images_amount_day_limit, type: Integer, default: ENV['IMAGES_AMOUNT_DAY_LIMIT'].to_i

  has_many :open_ai_assistants, class_name: OpenAiAssistant, dependent: :destroy
  has_many :usages, class_name: Usage, dependent: :destroy

  embeds_one :state, class_name: State

end