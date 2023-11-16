module CommandHandlers

  def self.handle_help_command(bot, message)
    help_text = "Список доступных команд:\n"
    help_text += "/start - Начать работу с ботом\n"
    help_text += "/new_assistant - Создать нового ассистента\n"
    help_text += "/new_image - Создать изображение с помощью описания\n"
    help_text += "/instructions - Изменить инструкции для ассистента и создать новый диалог с ним\n"

    bot.api.send_message(
      chat_id: message.chat.id,
      text: help_text
    )
  end

  def self.handle_remove_assistant_command(state, bot, message)
    user_id = message.from.id
    user = ::UserTelegram.where(telegram_id: user_id).first
    if user
      assistants = user.open_ai_assistants
      if assistants.any?
        inline_keyboards = assistants.map do |assistant|
          [Telegram::Bot::Types::InlineKeyboardButton.new(text: assistant.assistant_name, callback_data: "remove_#{assistant.id}")]
        end
        markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: inline_keyboards)
        bot.api.send_message(chat_id: user_id, text: 'Выбери ассистента для удаления:', reply_markup: markup)
      else
        bot.api.send_message(chat_id: user_id, text: 'У тебя нет созданных ассистентов.')
      end
    end
  end

  def self.handle_new_image_command(state, bot, message)
    state.is_creating_image = true

    bot.api.send_message(
      chat_id: message.chat.id,
      text: "Опиши изображение, которое ты хочешь создать:"
    )
  end

  def self.handle_start_command(state, bot, message)
    user_id = message.from.id
    puts "User id: #{user_id}"
    user = ::UserTelegram.where(telegram_id: user_id).first
    if user.nil?
      user = ::UserTelegram.new(telegram_id: user_id)
      user.save
    end
    assistants = user.open_ai_assistants

    if assistants.count > 0
      inline_keyboards = assistants.map do |assistant|
        [Telegram::Bot::Types::InlineKeyboardButton.new(text: assistant.assistant_name, callback_data: assistant.id.to_s)]
      end
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: inline_keyboards)
      bot.api.send_message(
        chat_id: user_id,
        text: 'Выбери ассистента',
        reply_markup: markup
      )
    else
      # Ask user to create assistant name and after assistant instruction
      state.is_creating_assistant_name = true
      bot.api.send_message(
        chat_id: user_id,
        text: 'Введи имя ассистента'
      )
    end
  end

end