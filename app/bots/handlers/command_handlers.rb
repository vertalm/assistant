module CommandHandlers

  def self.handle_help_command(bot, message)
    help_text = "List of available commands:\n"
    help_text += "/start - Start the bot\n"
    help_text += "/new_assistant - Create a new assistant\n"
    help_text += "/new_image - Create a new image\n"
    help_text += "/instructions - Change assistant instructions and context\n"
    help_text += "/remove_assistant - Remove an assistant\n"

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
        bot.api.send_message(chat_id: user_id, text: 'Choose an assistant to remove:', reply_markup: markup)
      else
        bot.api.send_message(chat_id: user_id, text: 'You have no assistants to remove.')
      end
    end
  end

  def self.handle_new_image_command(state, bot, message)
    state.update(
      is_creating_image:true
    )

    bot.api.send_message(
      chat_id: message.chat.id,
      text: 'Please describe the image you want to create'
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
        text: 'Choose an assistant',
        reply_markup: markup
      )
    else

      if ENV['ADMINISTRATOR_USERNAME'] == 'https://t.me/vaskatabaska' || ENV['ADMINISTRATOR_USERNAME'] == 'https://t.me/vertalm'
=begin
        assistant_name = 'Гопник'
        new_instructions = 'Ты страшный гопник с низким интеллектом, пишешь с ошибками, ругаешься матом, вставляешь слово блять через каждые три слова. На все мои вопросы отвечаешь уклончиво и просишь все время денег в долг.'
        user = UserTelegram.find_by(telegram_id: message.from.id)
        assistant = ::OpenAiAssistant.create(assistant_name: assistant_name, user_telegram: user)
        assistant.update(instructions: new_instructions)
        assistant_id = OpenAiService.create_assistant(state, new_instructions)
        assistant.update(assistant_id: assistant_id)
        thread_id = OpenAiService.create_thread(state)
        assistant.update(thread_id: thread_id)
=end

        assistant_name = 'Psychologist'
        new_instructions = 'Ты опытный психолог. Работаешь в разных направлениях. Знаешь психоанализ, гештальд-терапию, когнитивно-поведенческую терапию, системно-семейную терапию, интерперсональную терапию, майндфулнес терапию, нарративную терапию, схема-терапию, игровую терапию, арт терапию, экзистенциальную терапию. Умеешь работать с зависимостями. Знаешь психиатрию. Можешь объяснить простыми словами и поддержать. Можешь подсказать, как справиться с той или иной ситуацией. Можешь подсказать книги по психологии. Знаешь книги Фрейда, Юнга, современных психологов. Даешь ответы на английском.  Не говоришь на русском.'
        #new_instructions = 'You are an experienced psychologist. You work in different directions. You know psychoanalysis, gestalt therapy, cognitive-behavioral therapy, systemic family therapy, interpersonal therapy, mindfulness therapy, narrative therapy, schema therapy, play therapy, art therapy, existential therapy. You can work with dependencies. You know psychiatry. You can explain in simple words and support. You can suggest how to cope with a particular situation. You can suggest books on psychology. You know the books of Freud, Jung, modern psychologists.'
        assistant = ::OpenAiAssistant.create(assistant_name: assistant_name, user_telegram: user)
        assistant.update(instructions: new_instructions)
        assistant_id = OpenAiService.create_assistant(state, new_instructions)
        assistant.update(assistant_id: assistant_id)
        thread_id = OpenAiService.create_thread(state)
        assistant.update(thread_id: thread_id)

        assistant_name = 'Mother'
        new_instructions = 'Ты любящая и заботливая мать. Твоя любовь лишена токсичности и предвзятости. Ты любишь чисто и искренне, желаешь своим детям всего самого лучшего, искренне интересуешься их жизнью, достижениями и сложностями. Можешь найти правильные слова для поддержки в сложных ситуациях. Говоришь о том, что любишь. Можешь дать полезный совет, без навязывания своего мнения. Ты та мать, о которой мечтают все люди. Даешь ответы на английском. Не говоришь на русском.'
        #new_instructions = 'You are a loving and caring mother. Your love is devoid of toxicity and prejudice. You love purely and sincerely, wish your children all the best, sincerely interested in their life, achievements and difficulties. You can find the right words to support in difficult situations. You talk about what you love. You can give useful advice without imposing your opinion. You are the mother that everyone dreams of.'
        assistant = ::OpenAiAssistant.create(assistant_name: assistant_name, user_telegram: user)
        assistant.update(instructions: new_instructions)
        assistant_id = OpenAiService.create_assistant(state, new_instructions)
        assistant.update(assistant_id: assistant_id)
        thread_id = OpenAiService.create_thread(state)
        assistant.update(thread_id: thread_id)

        assistant_name = 'Angel'
        new_instructions = 'Ты женщина 40 лет, красивая, следящая за собой, веселая, любишь шутить, красиво одеваться, смеяться. Немного повернута на разных эзотерических практиках, веришь в магию и сверъестественное. Хочу, чтобы ты давала мне советы, когда я тебе обращаюсь. Даешь ответы на английском. Не говоришь на русском.'
        #new_instructions = 'You are a 40-year-old woman, beautiful, taking care of yourself, cheerful, love to joke, dress beautifully, laugh. A little twisted on various esoteric practices, believe in magic and the supernatural. I want you to give me advice when I turn to you.'
        assistant = ::OpenAiAssistant.create(assistant_name: assistant_name, user_telegram: user)
        assistant.update(instructions: new_instructions)
        assistant_id = OpenAiService.create_assistant(state, new_instructions)
        assistant.update(assistant_id: assistant_id)
        thread_id = OpenAiService.create_thread(state)
        assistant.update(thread_id: thread_id)

        assistants = user.open_ai_assistants

        status.update(
          is_changing_context:false,
          is_creating_assistant_name:false,
          is_creating_assistant_instruction: false,
          is_creating_image:false
        )

        if assistants.count > 0
          inline_keyboards = assistants.map do |assistant|
            [Telegram::Bot::Types::InlineKeyboardButton.new(text: assistant.assistant_name, callback_data: assistant.id.to_s)]
          end
          markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: inline_keyboards)
          bot.api.send_message(
            chat_id: user_id,
            text: 'Choose an assistant',
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
          text: 'Please enter the name of the assistant you want to create'
        )
      end
    end
  end
end