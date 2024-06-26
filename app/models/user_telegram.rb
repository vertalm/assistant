class UserTelegram
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :telegram_id, type: Integer
  field :telegram_username, type: String
  field :daily_limit, type: Integer, default: ENV['MESSAGE_AMOUNT_DAY_LIMIT'].to_i
  field :message_day_length_limit, type: Integer, default: ENV['MESSAGE_DAY_LENGTH_LIMIT'].to_i
  field :purchased_messages_amount, type: Integer, default: 0
  field :images_amount_day_limit, type: Integer, default: ENV['IMAGES_AMOUNT_DAY_LIMIT'].to_i
  field :trial_period, type: Integer, default: 10
  field :tokens_ordered_prompt_tokens, type: Integer, default: 100000
  field :tokens_ordered_completion_tokens, type: Integer, default: 100000
  field :tokens_used_prompt_tokens, type: Integer, default: 0
  field :tokens_used_completion_tokens, type: Integer, default: 0
  field :tokens_used_total_tokens, type: Integer, default: 0
  field :license_code, type: String, default: ''

  has_many :open_ai_assistants, class_name: OpenAiAssistant, dependent: :destroy
  has_many :usages, class_name: Usage, dependent: :destroy

  embeds_one :state, class_name: State

end