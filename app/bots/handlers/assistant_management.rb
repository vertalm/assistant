# handlers/assistant_management.rb

module AssistantManagement
  def self.handle_assistant_selection(state, bot, message)
    # Проверяем, что сообщение является ответом на запрос выбора ассистента
    if message.is_a?(Telegram::Bot::Types::CallbackQuery)
      # Получаем ID ассистента из callback_data
      id = message.data
      state.mongo_assistant_id = id

      # Находим ассистента в базе данных
      assistant = ::OpenAiAssistant.find(id)

      # Устанавливаем параметры состояния из данных ассистента
      state.assistant_id = assistant.assistant_id
      state.thread_id = assistant.thread_id
      state.instructions = assistant.instructions

      # Отправляем сообщение пользователю о выборе ассистента
      bot.api.send_message(
        chat_id: message.from.id,
        text: "Ассистент #{assistant.assistant_name} выбран."
      )

      # Теперь, когда выбран ассистент, можно безопасно вызывать create_message и create_run
      OpenAiService.create_message(state.thread_id, "Привет", 'user', [])
      state.run_id = OpenAiService.create_run(state.assistant_id, state.thread_id)

      # Проверка выполнения
      wait_complete = MessageHandling.check_run_completion(state.run_id, state.thread_id)
      if wait_complete == false
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "Таймаут ответа от OpenAI",
          parse_mode: 'Markdown'
        )
        return
      end

      # Отправка сообщения пользователю
      bot.api.send_message(
        chat_id: message.from.id,
        text: "Привет, ты выбрал ассистента #{assistant.assistant_name} с инструкцией #{assistant.instructions}.",
        parse_mode: 'Markdown'
      )
    end
  end
end