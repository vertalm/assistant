class ModelsController < ApplicationController
  def index
    # httparty https://api.openai.com/v1/models
    endpoint = "https://api.openai.com/v1/models"
    api_key = ENV['CHAT_GPT_TOKEN'] # Переменная окружения для ключа API OpenAI

    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{api_key}"
    }

    response = HTTParty.get(endpoint, headers: headers)
    @models = JSON.parse(response.body)

    render json: @models
  end
end