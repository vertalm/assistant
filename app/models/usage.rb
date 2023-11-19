class Usage
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated

  field :date, type: Date, default: Date.today
  field :message_text, type: String
  field :message_length, type: Integer, default: 0
  field :type, type: String, default: 'MESSAGE'

  belongs_to :user_telegram
end