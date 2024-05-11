class OpenAiAssistant
  include Mongoid::Document
  include Mongoid::Timestamps

  field :assistant_name, type: String
  field :instructions, type: String
  field :assistant_id, type: String
  field :thread_id, type: String

  belongs_to :user_telegram
end