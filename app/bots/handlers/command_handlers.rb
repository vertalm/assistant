module CommandHandlers

  def self.handle_help_command(bot, message)
    help_text = "Список доступных команд:\n"
    help_text += "/start - Начать работу с ботом\n"
    help_text += "/new_assistant - Создать нового ассистента\n"
    help_text += "/new_image - Создать изображение с помощью описания\n"
    help_text += "/instructions - Изменить инструкции для ассистента и создать новый диалог с ним\n"
    help_text += "/remove_assistant - Удалить ассистента\n"

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
    state.update(
      is_creating_image:true
    )

    bot.api.send_message(
      chat_id: message.chat.id,
      text: "Опиши изображение, которое ты хочешь создать:"
    )
  end

  def self.handle_start_command(state, bot, message)
    user_id = message.from.id
    username = message.from.username || ''
    user = ::UserTelegram.where(telegram_id: user_id).first
    if user.nil?
      user = ::UserTelegram.new(
        telegram_id: user_id,
        telegram_username: username
      )
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

      if ENV['ADMINISTRATOR_USERNAME'] == 'https://t.me/vaskatabaska'
        assistant_name = 'Гопник'
        new_instructions = 'Ты страшный гопник с низким интеллектом, пишешь с ошибками, ругаешься матом, вставляешь слово блять через каждые три слова. На все мои вопросы отвечаешь уклончиво и просишь все время денег в долг.'
        user = UserTelegram.find_by(telegram_id: message.from.id)
        assistant = ::OpenAiAssistant.create(assistant_name: assistant_name, user_telegram: user)
        assistant_id = OpenAiService.create_assistant(state, new_instructions)
        assistant.update(assistant_id: assistant_id)
        thread_id = OpenAiService.create_thread(state)
        assistant.update(thread_id: thread_id)

        assistant_name = 'Психолог'
        new_instructions = 'Ты опытный психолог. Работаешь в разных направлениях. Знаешь психоанализ, гештальд-терапию, когнитивно-поведенческую терапию, системно-семейную терапию, интерперсональную терапию, майндфулнес терапию, нарративную терапию, схема-терапию, игровую терапию, арт терапию, экзистенциальную терапию. Умеешь работать с зависимостями. Знаешь психиатрию. Можешь объяснить простыми словами и поддержать. Можешь подсказать, как справиться с той или иной ситуацией. Можешь подсказать книги по психологии. Знаешь книги Фрейда, Юнга, современных психологов.'
        assistant = ::OpenAiAssistant.create(assistant_name: assistant_name, user_telegram: user)
        assistant_id = OpenAiService.create_assistant(state, new_instructions)
        assistant.update(assistant_id: assistant_id)
        thread_id = OpenAiService.create_thread(state)
        assistant.update(thread_id: thread_id)

        assistant_name = 'Мама'
        new_instructions = 'Ты любящая и заботливая мать. Твоя любовь лишена токсичности и предвзятости. Ты любишь чисто и искренне, желаешь своим детям всего самого лучшего, искренне интересуешься их жизнью, достижениями и сложностями. Можешь найти правильные слова для поддержки в сложных ситуациях. Говоришь о том, что любишь. Можешь дать полезный совет, без навязывания своего мнения. Ты та мать, о которой мечтают все люди.'
        assistant = ::OpenAiAssistant.create(assistant_name: assistant_name, user_telegram: user)
        assistant_id = OpenAiService.create_assistant(state, new_instructions)
        assistant.update(assistant_id: assistant_id)
        thread_id = OpenAiService.create_thread(state)
        assistant.update(thread_id: thread_id)

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
        end
      else
        # Ask user to create assistant name and after assistant instruction
        state.update(
          is_creating_assistant_name:true
        )
        bot.api.send_message(
          chat_id: user_id,
          text: 'Введи имя ассистента'
        )
      end
    end
  end
end