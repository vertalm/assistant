class Assistant
  include Mongoid::Document

  field :assistant_name, type: String
  field :instructions, type: String
  field :assistant_id, type: String
  field :thread_id, type: String

  belongs_to :user_telegram
end