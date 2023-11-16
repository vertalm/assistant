module CommandHandlers
  def self.handle_start_command(state, bot, message)
    user_id = message.from.id
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