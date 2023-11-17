module MessageHandling

  def self.handle_message_with_file(state, bot, message, file_content, file_name)

    bot.api.send_message(
      chat_id: message.chat.id,
      text: "Файл #{file_name} отправлен в OpenAI."
    )

    puts "FILE CONTENT: #{file_content}"
    name_and_content = file_name + "\n" + file_content + "\n Don't answer, just remember file content"
    resp = OpenAiService.create_message(state.thread_id, name_and_content, 'user', [])
    if resp == false
      bot.api.send_message(
        chat_id: message.chat.id,
        text: 'Прости, начни сначала /start',
        parse_mode: 'Markdown'
      )
      return
    end

    run_id = OpenAiService.create_run(state.assistant_id, state.thread_id)
    state.run_id = run_id
    wait_complete = check_run_completion(run_id, state.thread_id)
    if wait_complete == false
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Таймаут ответа от OpenAI",
        parse_mode: 'Markdown'
      )
      return
    end

    last_message = OpenAiService.get_last_message(state.thread_id)
    puts "last_message: #{last_message}"

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
      bot.api.send_message(
        chat_id: message.chat.id,
        text: last_message,
        parse_mode: 'Markdown'
      )
    end

  end



  def self.handle_default_message(state, bot, message, website_data = '', file_ids = [])

    if state.is_creating_image && message.text
      image_description = message.text
      state.is_creating_image = false

      # Вызываем метод `create_image` из модуля `OpenAiImageService`, передавая ему описание изображения
      image_response = OpenAiImageService.create_image(image_description)
      puts "IMAGE RESP: #{image_response.inspect}"

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
          text: "Произошла ошибка: #{image_response[:error]}"
        )
      else
        # Если ответ неожиданный или неверный, уведомляем пользователя
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "Не удалось создать изображение. Пожалуйста, попробуйте еще раз."
        )
      end
    elsif state.is_creating_assistant_instruction
      assistant_instruction = message.text
      state.is_creating_assistant_instruction = false
      assistant = ::OpenAiAssistant.where(id: state.mongo_assistant_id).first
      assistant.instructions = assistant_instruction
      assistant.save
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Инструкция для ассистента: #{assistant_instruction}"
      )

      assistant_id = OpenAiService.create_assistant(assistant_instruction)
      state.assistant_id = assistant_id
      thread_id = OpenAiService.create_thread
      state.thread_id = thread_id

      assistant.update(
        assistant_id: assistant_id,
        thread_id: thread_id
      )

    elsif state.is_creating_assistant_name
      assistant_name = message.text
      state.is_creating_assistant_name = false
      state.is_creating_assistant_instruction = true
      user = UserTelegram.find_by(telegram_id: message.from.id)
      assistant = ::OpenAiAssistant.create(assistant_name: assistant_name, user_telegram: user)
      state.mongo_assistant_id = assistant.id
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Имя ассистента: #{assistant_name}. Введи инструкцию для ассистента"
      )
    elsif state.is_changing_context
      new_instructions = message.text
      state.instructions = new_instructions

      if state.assistant_id.nil?
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "Прости, начни сначала",
          parse_mode: 'Markdown'
        )
        return
      end

      assistant_id = OpenAiService.create_assistant(new_instructions)
      state.assistant_id = assistant_id
      OpenAiService.create_message(state.thread_id, "Привет", 'user', [])
      run_id = OpenAiService.create_run(state.assistant_id, state.thread_id)
      state.run_id = run_id

      wait_complete = check_run_completion(run_id, state.thread_id)
      if wait_complete == false
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "Таймаут ответа от OpenAI",
          parse_mode: 'Markdown'
        )
        return
      end

      state.is_changing_context = false

      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Инструкция ассистента обновлена: #{new_instructions}"
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
      resp = OpenAiService.create_message(state.thread_id, message_text, 'user', file_ids)
      if resp == false
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "Прости, начни сначала",
          parse_mode: 'Markdown'
        )
        return
      end

      run_id = OpenAiService.create_run(state.assistant_id, state.thread_id)
      state.run_id = run_id
      wait_complete = check_run_completion(run_id, state.thread_id)
      if wait_complete == false
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "Таймаут ответа от OpenAI",
          parse_mode: 'Markdown'
        )
        return
      end

      last_message = OpenAiService.get_last_message(state.thread_id)
      puts "last_message: #{last_message}"
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

  def self.check_run_completion(run_id, thread_id)
    max_retries = 600   # Ограничение количества попыток
    tries = 0
    sleep_time = 1
    start_time = Time.now

    while tries < max_retries
      sleep(sleep_time)
      status_body = OpenAiService.run_check(thread_id, run_id)
      return status_body if status_body['status'] == 'completed'

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