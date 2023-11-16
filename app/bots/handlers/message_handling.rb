module MessageHandling

  def self.handle_message_with_file(state, bot, message, file_ids)
    bot.api.send_message(
      chat_id: message.chat.id,
      text: "Файл сохранен в #{file_ids.join(', ')}"
    )
    handle_default_message(state, bot, message, '', file_ids)
  end

  def self.handle_default_message(state, bot, message, website_data = '', file_ids = [])
    if state.is_creating_assistant_instruction
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

      puts "Inspecting resp: #{resp.inspect}"

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
      bot.api.send_message(
        chat_id: message.chat.id,
        text: last_message,
        parse_mode: 'Markdown'
      )
    end
  end

  def self.check_run_completion(run_id, thread_id)
    max_retries = 30 # Ограничение количества попыток
    tries = 0

    while tries < max_retries
      sleep(1)
      status_body = OpenAiService.run_check(thread_id, run_id)
      return status_body if status_body['status'] == 'completed'

      tries += 1
    end

    false
  end
end