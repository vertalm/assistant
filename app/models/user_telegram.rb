class UserTelegram
  include Mongoid::Document

  field :telegram_id, type: Integer
  has_many :open_ai_assistants, class_name: OpenAiAssistant, dependent: :destroy

  # Другие поля, например:
  # field :name, type: String
end