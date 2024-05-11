module MessageHandling

  def self.handle_message_with_file(state, bot, message, file_content, file_name, user)

    bot.api.send_message(
      chat_id: message.chat.id,
      text: "File received. Processing...",
    )

    name_and_content = file_name + "\n" + file_content + "\n Don't answer, just remember file content"
    resp = OpenAiService.create_message(state.thread_id, name_and_content, 'user', [])
    if resp == false
      bot.api.send_message(
        chat_id: message.chat.id,
        text: 'Sorry, start over /start',
        parse_mode: 'Markdown'
      )
      return
    end

    run_id = OpenAiService.create_run(state,state.assistant_id, state.thread_id)
    state.update(
      run_id:run_id
    )
    wait_complete = check_run_completion(run_id, state.thread_id, user)
    if wait_complete == false
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Timeout from OpenAI",
        parse_mode: 'Markdown'
      )
      return
    end

    last_message = OpenAiService.get_last_message(state.thread_id)

    # Если длина последнего сообщения больше 4096 символов, то разбиваем его на несколько сообщений
    if last_message.length > 4000
      last_message.scan(/.{1,4000}/m).each do |message_part|
        bot.api.send_message(
          chat_id: message.chat.id,
          text: message_part
        )
      end
      return
    else
      begin
        bot.api.send_message(
          chat_id: message.chat.id,
          text: last_message,
          parse_mode: 'Markdown'
        )
      rescue
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "Sorry, start over /start",
          parse_mode: 'Markdown'
        )
      end
    end

  end



  def self.handle_default_message(state, bot, message, website_data = '', file_ids = [])

    if message.from&.id
      user_id = message.from.id
      telegram_username = message.from.username || ''
    elsif message.chat&.id
      user_id = message.chat.id
      telegram_username = ''
    else
      user_id = "unknown"
      telegram_username = ''
    end

    user = UserTelegram.find_by(telegram_id: user_id)

    if state.is_creating_image && message.text
      image_description = message.text
      state.update(is_creating_image:false)

      # Вызываем метод `create_image` из модуля `OpenAiImageService`, передавая ему описание изображения
      image_response = OpenAiImageService.create_image(image_description)

      #IMAGE RESP: {"created"=>1700152879, "data"=>[{"revised_prompt"=>"Generate an image of a cute little kitten with soft fur and sparkling eyes, playing with a ball of yarn. The kitten has a striking colour contrast between its white body and black spots, and it's having a fun time in a cozy room with a wooden floor and soft sunlight streaming in through a large window.", "url"=>"https://oaidalleapiprodscus.blob.core.windows.net/private/org-ZwKoULY3uV8aeUiHn7BsA2sK/user-lRZCbf7f2GwGtXT3uCrbLayw/img-neOfJmhQSe8TUsXEITatrb55.png?st=2023-11-16T15%3A41%3A18Z&se=2023-11-16T17%3A41%3A18Z&sp=r&sv=2021-08-06&sr=b&rscd=inline&rsct=image/png&skoid=6aaadede-4fb3-4698-a8f6-684d7786b067&sktid=a48cca56-e6da-484e-a814-9c849652bcb3&skt=2023-11-16T16%3A41%3A18Z&ske=2023-11-17T16%3A41%3A18Z&sks=b&skv=2021-08-06&sig=z8rg5C3rAHkJghdaQp7nR5BZRv1oH13GSC0/7xE5eg0%3D"}]}

      if image_response.is_a?(Hash) && image_response['data'] && image_response['data'][0] && image_response['data'][0]['url']
        # Если ответ содержит URL изображения, отправляем его пользователю в виде фото
        bot.api.send_photo(
          chat_id: message.chat.id,
          photo: image_response['data'][0]['url'],
          caption: image_response['data'][0]['revised_prompt']
        )
      elsif image_response.is_a?(Hash) && image_response[:error]
        # Если ответ содержит ошибку, отправляем её пользователю в виде текстового сообщения
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "Error: #{image_response[:error]}"
        )
      else
        # Если ответ неожиданный или неверный, уведомляем пользователя
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "Sorry, something went wrong. Please try again later."
        )
      end
    elsif state.is_creating_assistant_instruction
      assistant_instruction = message.text
      state.update(is_creating_assistant_instruction:false)
      assistant = ::OpenAiAssistant.where(id: state.mongo_assistant_id).first
      assistant.instructions = assistant_instruction
      assistant.save
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Assistant instruction: #{assistant_instruction}"
      )

      assistant_id = OpenAiService.create_assistant(state,assistant_instruction)
      puts "Инструкция для ассистента: #{assistant_instruction}"
      puts "CREATED ASSISTANT_ID: #{assistant_id}"
      state.update(assistant_id:assistant_id)
      thread_id = OpenAiService.create_thread(state)
      puts "CREATED THREAD_ID: #{thread_id}"
      state.update(thread_id:thread_id)

      puts "IN STATES:"
      puts "ASSISTANT_ID: #{state.assistant_id}"
      puts "THREAD_ID: #{state.thread_id}"

      assistant.update(
        assistant_id: assistant_id,
        thread_id: thread_id
      )

    elsif state.is_creating_assistant_name
      assistant_name = message.text
      state.update(
        is_creating_assistant_name:false,
        is_creating_assistant_instruction:true
      )
      user = UserTelegram.find_by(telegram_id: message.from.id)
      assistant = ::OpenAiAssistant.create(assistant_name: assistant_name, user_telegram: user)
      state.update(mongo_assistant_id:assistant.id)
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Assistant name: #{assistant_name}, \n\nplease provide assistant instruction"
      )
    elsif state.is_changing_context
      new_instructions = message.text
      state.update(instructions:new_instructions)

      if state.assistant_id.nil?
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "Sorry, start over /start",
          parse_mode: 'Markdown'
        )
        return
      end

      assistant_id = OpenAiService.create_assistant(state, new_instructions)
      state.update(assistant_id:assistant_id)
      OpenAiService.create_message(state.thread_id, "Hi", 'user', [])
      run_id = OpenAiService.create_run(state, state.assistant_id, state.thread_id)
      state.update(run_id: run_id)

      wait_complete = check_run_completion(run_id, state.thread_id, user)
      if wait_complete == false
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "Timeout from OpenAI",
          parse_mode: 'Markdown'
        )
        return
      end

      state.update(is_changing_context:false)

      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Instructions changed to: #{new_instructions}",
      )
    else
      if message.caption && message.caption != ''
        message_text = message.caption
      else
        message_text = message.text
      end
      if website_data != ''
        message_text = message_text + ' ' + website_data
      end

      puts "MESSAGE_TEXT: #{message_text}"
      resp = OpenAiService.create_message(state.thread_id, message_text, 'user', file_ids)
      if resp == false
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "Sorry, start over /start",
          parse_mode: 'Markdown'
        )
        return
      end

      puts "BEFORE RUN"
      puts "ASSISTANT_ID: #{state.assistant_id}"
      puts "THREAD_ID: #{state.thread_id}"
      run_id = OpenAiService.create_run(state, state.assistant_id, state.thread_id)
      state.update(run_id:run_id)
      puts "AFTER RUN"
      puts "ASSISTANT_ID: #{state.assistant_id}"
      puts "THREAD_ID: #{state.thread_id}"
      puts "RUN_ID: #{run_id}"

      wait_complete = check_run_completion(run_id, state.thread_id, user)
      if wait_complete == false
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "Timeout from OpenAI",
          parse_mode: 'Markdown'
        )
        return
      end

      last_message = OpenAiService.get_last_message(state.thread_id)
      # Если длина сообщения превышает 4096 символов, разбиваем его на несколько сообщений
      if last_message.length > 4000
        last_message.scan(/.{1,4000}/m) do |message_part|
          bot.api.send_message(
            chat_id: message.chat.id,
            text: message_part
          )
        end
        return
      else
        bot.api.send_message(
          chat_id: message.chat.id,
          text: last_message,
          parse_mode: 'Markdown'
        )
      end
    end
  end

  def self.check_run_completion(run_id, thread_id, user)
    max_retries = 30   # Ограничение количества попыток
    tries = 0
    sleep_time = 1
    start_time = Time.now

    while tries < max_retries
      sleep(sleep_time)
      status_body = OpenAiService.run_check(thread_id, run_id)
      if status_body['error'] && status_body['error']['type'] == 'invalid_request_error'
        return false
      end

      if status_body['status'] == 'completed' || status_body['status'] == 'failed'
        Rails.logger.info("Run completed update usage: #{status_body}")
        last_user_usage = user.usages.last
        last_user_usage.update(
          prompt_tokens: status_body['usage']['prompt_tokens'],
          completion_tokens: status_body['usage']['completion_tokens'],
          total_tokens: status_body['usage']['total_tokens']
        )

        tokens_used_prompt_tokens = user[:tokens_used_prompt_tokens] || 0
        tokens_used_completion_tokens = user[:tokens_used_completion_tokens] || 0
        tokens_used_total_tokens = user[:tokens_used_total_tokens] || 0
        user.update(
          tokens_used_prompt_tokens: tokens_used_prompt_tokens + status_body['usage']['prompt_tokens'].to_i,
          tokens_used_completion_tokens: tokens_used_completion_tokens + status_body['usage']['completion_tokens'].to_i,
          tokens_used_total_tokens: tokens_used_total_tokens + status_body['usage']['total_tokens'].to_i
        )
      end

      return status_body if status_body['status'] == 'completed' || status_body['status'] == 'failed'


      elapsed_time = Time.now - start_time
      sleep_time = if elapsed_time > 5 * 60 # Прошло более 5 минут
                     10
                   elsif elapsed_time > 60 # Прошло более 1 минуты
                     5
                   elsif tries > 10
                     3
                   else
                     1
                   end

      tries += 1
    end

    false
  end
end