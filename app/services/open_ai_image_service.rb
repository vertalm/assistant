require 'httparty'
require 'json'

module OpenAiImageService
  # API endpoint для создания изображения, согласно документации OpenAI
  ENDPOINT = "https://api.openai.com/v1/images/generations"

  def self.create_image(prompt)
    api_key = ENV['CHAT_GPT_TOKEN'] # Переменная окружения для ключа API OpenAI

    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{api_key}"
    }

    body = {
      "prompt": prompt,
      "n": 1,          # Количество изображений
      "size": "1024x1024", # Размер изображения, поддерживаемые значения: "256x256", "512x512", "1024x1024"
      "model": "dall-e-3"  # Используйте модель изображений, поддерживаемую OpenAI
    }.to_json

    response = HTTParty.post(ENDPOINT, body: body, headers: headers)

    if response.success?
      response_body = JSON.parse(response.body)
      response_body
    else
      { error: response.message } # Возвращаем сообщение об ошибке, если запрос не был успешным.
    end
  end
end
