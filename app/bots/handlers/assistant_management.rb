# handlers/assistant_management.rb

module AssistantManagement

  def self.confirm_removal(state, bot, assistant_id, user_id)
    state.update(
      pending_removal_id: assistant_id
    )
    # Создайте inline-клавиатуру для подтверждения
    inline_keyboard = [
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Да', callback_data: 'confirm_remove')],
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Нет', callback_data: 'cancel_remove')]
    ]
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: inline_keyboard)
    bot.api.send_message(chat_id: user_id, text: "Вы уверены, что хотите удалить ассистента?", reply_markup: markup)
  end

  def self.perform_removal(state, bot, assistant_id, user_id)
    # Находим ассистента в базе данных
    assistant = ::OpenAiAssistant.find(assistant_id)
    # Удаляем ассистента из базы данных
    assistant.destroy

    OpenAiService.delete_assistant(assistant_id)

    bot.api.send_message(chat_id: user_id, text: "Ассистент удален.")
  end

  def self.handle_assistant_selection(state, bot, message)
    # Проверяем, что сообщение является ответом на запрос выбора ассистента
    if message.is_a?(Telegram::Bot::Types::CallbackQuery)
      # Получаем ID ассистента из callback_data
      id = message.data
      state.update(
        mongo_assistant_id:id
      )

      # Находим ассистента в базе данных
      assistant = ::OpenAiAssistant.find(id)

      # Устанавливаем параметры состояния из данных ассистента
      state.update(
        assistant_id: assistant.assistant_id,
        thread_id: assistant.thread_id,
        instructions: assistant.instructions
      )

      # Отправляем сообщение пользователю о выборе ассистента
      bot.api.send_message(
        chat_id: message.from.id,
        text: "Ассистент #{assistant.assistant_name} выбран."
      )

=begin

      OpenAiService.create_message(state.thread_id, "Привет", 'user', [])
      run_id = OpenAiService.create_run(state, assistant.assistant_id, assistant.thread_id)

      # Проверка выполнения
      wait_complete = MessageHandling.check_run_completion(run_id, state.thread_id)
      if wait_complete == false
        bot.api.send_message(
          chat_id: message.from.id,
          text: "Таймаут ответа от OpenAI",
          parse_mode: 'Markdown'
        )
        return
      end
=end

      # Отправка сообщения пользователю
=begin
      bot.api.send_message(
        chat_id: message.from.id,
        text: "Привет, ты выбрал ассистента #{assistant.assistant_name} с инструкцией #{assistant.instructions}.",
        parse_mode: 'Markdown'
      )
=end
    end
  end
end