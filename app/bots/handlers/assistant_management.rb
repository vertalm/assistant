# /app/bots/handlers/assistant_management.rb

module AssistantManagement

  def self.confirm_removal(state, bot, assistant_id, user_id)
    state.update(
      pending_removal_id: assistant_id
    )
    # Создайте inline-клавиатуру для подтверждения
    inline_keyboard = [
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Yes', callback_data: 'confirm_remove')],
      [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'No', callback_data: 'cancel_remove')]
    ]
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: inline_keyboard)
    bot.api.send_message(chat_id: user_id, text: "Are you sure you want to remove this assistant?", reply_markup: markup)
  end

  def self.perform_removal(state, bot, assistant_id, user_id)
    # Находим ассистента в базе данных
    assistant = ::OpenAiAssistant.find(assistant_id)
    # Удаляем ассистента из базы данных
    assistant.destroy

    OpenAiService.delete_assistant(assistant_id)

    bot.api.send_message(chat_id: user_id, text: "Assistant removed.")
  end

  def self.handle_assistant_selection(state, bot, message)
    # Проверяем, что сообщение является ответом на запрос выбора ассистента
    if message.is_a?(Telegram::Bot::Types::CallbackQuery)
      # Получаем ID ассистента из callback_data
      id = message.data
      Rails.logger.info("Selected assistant ID: #{id}")
      state.update(
        mongo_assistant_id:id
      )

      # Находим ассистента в базе данных
      assistant = ::OpenAiAssistant.find(id)
      Rails.logger.info("Selected assistant: #{assistant.inspect}")

      # Устанавливаем параметры состояния из данных ассистента
      state.update(
        assistant_id: assistant.assistant_id,
        thread_id: assistant.thread_id,
        instructions: assistant.instructions
      )

      Rails.logger.info("State: #{state.inspect}")

      # Отправляем сообщение пользователю о выборе ассистента
      bot.api.send_message(
        chat_id: message.from.id,
        text: "You have selected the #{assistant.assistant_name} assistant."
      )

    end
  end
end