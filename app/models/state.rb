class State
  include Mongoid::Document

  field :is_changing_context, type: Boolean, default: false
  field :instructions, type: String, default: 'Ты персональный ассистент.'
  field :fallback_model, type: String, default: "gpt-4"
  field :primary_model, type: String, default: "gpt-4-turbo"
  field :switch_time, type: DateTime, default: DateTime.now
  field :assistant_id, type: String
  field :thread_id, type: String
  field :run_id, type: String
  field :is_creating_assistant_name, type: Boolean, default: false
  field :is_creating_assistant_instruction, type: Boolean, default: false
  field :mongo_assistant_id, type: String
  field :is_creating_image, type: Boolean, default: false
  field :pending_removal_id, type: String

  embedded_in :user_telegram
end