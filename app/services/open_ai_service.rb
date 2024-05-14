class OpenAiService
  # Metody dlya sozdaniya assistant, thread, messages, i run

  api_key = ENV['CHAT_GPT_TOKEN']

  @headers = {
    'Content-Type' => 'application/json',
    'Authorization' => "Bearer #{api_key}",
    'OpenAI-Beta' => 'assistants=v1' # Добавлен дополнительный заголовок
  }

  def self.delete_assistant(assistant_id)
    endpoint = "https://api.openai.com/v1/assistants/#{assistant_id}"

    response = HTTParty.delete(endpoint, headers: @headers)

    if response.success?
      response_body = JSON.parse(response.body)
      response_body['id']
    end
  end

  def self.create_assistant(state, instructions)
    model = 'pt-4-turbo-2024-04-09'
    name = 'OpenAiPostAssistant chat'
    description = 'OpenAiAssistant for fill chats'

    endpoint = "https://api.openai.com/v1/assistants"

    body = {
      "model": model, # Основная модель
      "name": name,
      "description": description,
      "instructions": instructions
    }.to_json

    response = HTTParty.post(endpoint, body: body, headers: @headers)
    Rails.logger.info("CREATE_OPEN_AI_ASSISTANT_RESPONSE: #{response.inspect}")

    if response.success?
      response_body = JSON.parse(response.body)
      state.update(
        assistant_id:response_body['id']
      )
      response_body['id']
    end
  end

  def self.modify_assistant(model, assistant_id, instructions, state)
    endpoint = "https://api.openai.com/v1/assistants/#{assistant_id}"

    body = {
      "instructions": instructions
    }.to_json

    response = HTTParty.post(endpoint, body: body, headers: @headers)

    if response.success?
      response_body = JSON.parse(response.body)
      state.update(
        assistant_id:response_body['id']
      )
      response_body['id']
    end
  end

  def self.upload_file(file_destination)
    endpoint = "https://api.openai.com/v1/files"

    response = HTTParty.post(
      endpoint,
      body: {
        purpose: 'assistants',
        file: File.new(file_destination)
      },
      headers: { "Authorization" => "Bearer #{ENV['CHAT_GPT_TOKEN']}" },
      multipart: true
    )

    if response.success?
      response_body = JSON.parse(response.body)
      response_body['id']
    end
  end


  def self.create_thread(state)
    endpoint = "https://api.openai.com/v1/threads"

    body = ''
    response = HTTParty.post(endpoint, body: body, headers: @headers)

    if response.success?
      response_body = JSON.parse(response.body)
      state.update(thread_id: response_body['id'])
      response_body['id']
    end
  end

  def self.create_message(thread_id,content, role, file_ids)

    if thread_id.nil?
      return false
    end

    endpoint = "https://api.openai.com/v1/threads/#{thread_id}/messages"

    body = {
      'role' => role || 'user',
      'content' => content,
      'file_ids' => file_ids || []
    }.to_json

    response = HTTParty.post(endpoint, body: body, headers: @headers)
    response_body = JSON.parse(response.body)
    puts "BODY MESSAGES RESPONSE #{response_body.inspect}"
    response
  end

  def self.create_run(state, assistant_id, thread_id)
    endpoint = "https://api.openai.com/v1/threads/#{thread_id}/runs"
    context_window = state.context_window || 10
    if context_window < 4
      context_window = 4
    end

    body = {
      'assistant_id' => assistant_id,
      'truncation_strategy' => {
        'type' => 'last_messages',
        'last_messages' => context_window
      }
    }.to_json

    response = HTTParty.post(endpoint, body: body, headers: @headers)

    if response.success?
      response_body = JSON.parse(response.body)
      state.update(run_id:response_body['id'])
      response_body['id']
    end
  end

  def self.run_check(thread_id, run_id)
    endpoint = "https://api.openai.com/v1/threads/#{thread_id}/runs/#{run_id}"

    response = HTTParty.get(endpoint, headers: @headers)
    response_body = JSON.parse(response.body)
    puts "RESPONSE BODY RUN CHECK #{response_body.inspect}"
    Rails.logger.info "RESPONSE BODY RUN CHECK #{response_body.inspect}"
    response_body
  end

  def self.get_last_message(thread_id)
    endpoint = "https://api.openai.com/v1/threads/#{thread_id}/messages"

    response = HTTParty.get(endpoint, headers: @headers)
    response_body = JSON.parse(response.body)

    puts "RESPONSE BODY GET LAST MESSAGE: #{response_body.inspect}"

    # Проверка успешности запроса
    if response.success?
      # Извлечение и отправка последнего сообщения от системы (ассистента) пользователю

      last_system_message = response_body['data'].select { |message| message['role'] == 'assistant' }.first
      if last_system_message
        last_system_message['content'].first['text']['value']
      else
        "Sorry, I can't find the answer from assistant 1"
      end
    else
      "Sorry, I can't find the answer from assistant 2"
    end
  end
end