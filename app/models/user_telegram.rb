class UserTelegram
  include Mongoid::Document

  field :telegram_id, type: Integer
  field :daily_limit, type: Integer, default: 5
  has_many :open_ai_assistants, class_name: OpenAiAssistant, dependent: :destroy
  has_many :usages, class_name: Usage, dependent: :destroy

  embeds_one :state, class_name: State

end