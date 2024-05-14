require 'telegram/bot'
require 'dotenv/load'
require 'mongo'
require_relative 'handlers/command_handlers'
require_relative 'handlers/assistant_management'
require_relative 'handlers/message_handling'

class TelegramGptBot
  def self.run
    token = ENV['TELEGRAM_BOT_TOKEN']
    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|

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

        puts "USER ID: #{user_id}"

        user = UserTelegram.find_or_create_by(telegram_id: user_id)
        user.update(
          telegram_username: telegram_username
        )
        state = user.state
        if state.nil?
          user.build_state(
            is_changing_context: false,
            instructions: 'You are personal assistant. You can help me with my tasks.',
            fallback_model: "gpt-4",
            primary_model: "gpt-4o",
            switch_time: DateTime.now,
            assistant_id: nil,
            thread_id: nil,
            run_id: nil,
            is_creating_assistant_name: false,
            is_creating_assistant_instruction: false,
            mongo_assistant_id: nil,
            is_creating_image: false,
            pending_removal_id: nil
          )

          if user.save
            puts "New user created"
          else
            puts "Error creating user #{user.errors.full_messages}"
          end
          state = user.state
        end

        if message.is_a?(Telegram::Bot::Types::Message)
          # Проверяем, прошло ли 10 дней с момента первого сообщения пользователя
=begin
          if user.created_at.nil?
            user.created_at = DateTime.now.utc
            user.save
          end
          if (DateTime.now.utc.to_date - user.created_at.to_date).to_i > user[:trial_period]
            # Если прошло больше 10 дней, отправляем сообщение о закончившемся пробном периоде
            bot.api.send_message(
              chat_id: message.chat.id,
              text: "Пробный период закончился. Если хотите продолжать использовать бота, обратитесь к администратору #{ENV['ADMINISTRATOR_USERNAME']} для увеличения лимита"
            )
            # Завершаем обработку этого сообщения, чтобы не продолжать выполнение других команд
            next
          end
=end

          if message.text

            if state[:is_creating_image] == true
              type = "IMAGE"
            else
              type = "MESSAGE"
            end

            user_telegram = UserTelegram.where(telegram_id: user_id).first
            today_usage = user_telegram.usages.where(
              date: Date.today
            ).count
            today_total_message_length = user_telegram.usages.where(
              date: Date.today
            ).sum(:message_length)
            purchased_messages_amount = user_telegram[:purchased_messages_amount].to_i

            puts "TODAY USAGE: #{today_usage}"
            puts "TODAY TOTAL MESSAGE LENGTH: #{today_total_message_length}"

            user_telegram = UserTelegram.where(telegram_id: user_id).first
            puts "DAY LIMIT: #{user_telegram[:daily_limit]}"
            puts "DAY LENGTH LIMIT: #{user_telegram[:message_day_length_limit]}"

=begin

            if user_telegram[:daily_limit] < today_usage && purchased_messages_amount <= 0
              # Сообщение о том, что превышен суточный лимит
              bot.api.send_message(
                chat_id: message.chat.id,
                text: "Превышен суточный лимит сообщений #{user_telegram[:daily_limit]}. Обратитесь к администратору " + ENV['ADMINISTRATOR_USERNAME'] + " для увеличения лимита"
              )
              next
            end

            if user_telegram[:message_day_length_limit] < today_total_message_length && purchased_messages_amount <= 0
              # Сообщение о том, что превышен суточный лимит
              bot.api.send_message(
                chat_id: message.chat.id,
                text: "Превышен суточный лимит символов #{user_telegram[:message_day_length_limit]}. Обратитесь к администратору " + ENV['ADMINISTRATOR_USERNAME'] + " для увеличения лимита"
              )
              next
            end
=end

            tokens_ordered_prompt_tokens = user[:tokens_ordered_prompt_tokens] || 100000
            tokens_ordered_completion_tokens = user[:tokens_ordered_completion_tokens] || 100000
            tokens_used_prompt_tokens = user[:tokens_used_prompt_tokens] || 0
            tokens_used_completion_tokens = user[:tokens_used_completion_tokens] || 0

            # check is message text format DE5F-WG3F-QW43-4F3F
            message_license = false
            if message.text.match?(/\b[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}\b/)
              message_license = true
            end

            if message_license == false && (tokens_used_prompt_tokens > tokens_ordered_prompt_tokens || tokens_used_completion_tokens > tokens_ordered_completion_tokens)
              # Сообщение о том, что превышен лимит токенов и что можно купить новые по адресу https://dev.opuna.com/page/products
              bot.api.send_message(
                chat_id: message.chat.id,
                text: "Your token limit has been exceeded. You can buy new tokens at https://dev.opuna.com/assistant_code"
              )
              next
            end

            case message.text
            when '/start'
              CommandHandlers.handle_help_command(bot, message)
              CommandHandlers.handle_start_command(state, bot, message)
            when '/instructions'
              state.update(is_changing_context: true)
              bot.api.send_message(
                chat_id: message.chat.id,
                text: "Please enter the new instructions for the assistant."
              )
            when '/new_assistant'
              state.update(is_creating_assistant_name:true)
              bot.api.send_message(
                chat_id: message.chat.id,
                text: "Please enter the name of the new assistant."
              )
            when '/get_token_info'

              tokens_ordered_prompt_tokens = user[:tokens_ordered_prompt_tokens] || 100000
              tokens_ordered_completion_tokens = user[:tokens_ordered_completion_tokens] || 100000
              tokens_used_prompt_tokens = user[:tokens_used_prompt_tokens] || 0
              tokens_used_completion_tokens = user[:tokens_used_completion_tokens] || 0

              tokens_used_prompt_tokens_left = tokens_ordered_prompt_tokens - tokens_used_prompt_tokens
              tokens_used_completion_tokens_left = tokens_ordered_completion_tokens - tokens_used_completion_tokens

              context_window = state[:context_window] || 10
              if context_window < 4
                context_window = 4
              end
              # у вас осталось
              bot.api.send_message(
                chat_id: message.chat.id,
                text: "You have left:
                        prompt tokens: #{tokens_used_prompt_tokens_left}
                        completion tokens: #{tokens_used_completion_tokens_left}
                        context window: #{context_window}
                       "
              )

            when '/enter_license_code'
              bot.api.send_message(
                chat_id: message.chat.id,
                text: "Please enter the license code."
              )
            when '/change_context_window'
              state.update(is_changing_context_window: true)
              bot.api.send_message(
                chat_id: message.chat.id,
                text: "Please enter the new context window."
              )
            when '/remove_assistant'
              CommandHandlers.handle_remove_assistant_command(state, bot, message)
            when '/new_image'
              CommandHandlers.handle_new_image_command(state, bot, message)
            when '/help'
              CommandHandlers.handle_help_command(bot, message)
            else

              user_telegram = ::UserTelegram.where(telegram_id: user_id).first
              user_telegram.usages.create(
                message_text: message.text,
                message_length: message.text.length,
                type: type,
                date: Date.today
              )

              if purchased_messages_amount > 0
                user_telegram.update(purchased_messages_amount: purchased_messages_amount - 1)
              end
              website_data = handle_website_visit_command(state, bot, message)
              if website_data
                MessageHandling.handle_default_message(state, bot, message, website_data)
              else
                MessageHandling.handle_default_message(state, bot, message)
              end
            end
          elsif message.document

            begin
              file_id = message.document.file_id
              file_info = bot.api.get_file(file_id: file_id)
              file_path = file_info['result']['file_path']
              file_url = "https://api.telegram.org/file/bot#{token}/#{file_path}"
              file_name = message.document.file_name
              file = URI.open(file_url)
              file_data = file.read
              file.close
            rescue
              bot.api.send_message(
                chat_id: message.chat.id,
                text: "Something went wrong. Now you can send only text files."
              )
              file_data = ''
            end

            if state[:is_creating_image] == true
              type = "IMAGE"
            else
              type = "MESSAGE"
            end

            user_telegram = UserTelegram.where(telegram_id: user_id).first
            begin
              user_telegram.usages.create(
                message_text: file_data,
                message_length: file_data.to_s.length,
                type: type,
                date: Date.today,
                prompt_tokens: 4000,
                completion_tokens: 4000,
                total_tokens: 8000
              )

              user_telegram.update(
                tokens_used_prompt_tokens: user_telegram[:tokens_used_prompt_tokens] + 4000,
                tokens_used_completion_tokens: user_telegram[:tokens_used_completion_tokens] + 4000,
                tokens_used_total_tokens: user_telegram[:tokens_used_total_tokens] + 8000
              )
            rescue
              # Сообщение о том, что превышен суточный лимит
            end
            today_usage = user_telegram.usages.where(
              date: Date.today
            ).count
            today_total_message_length = user_telegram.usages.where(
              date: Date.today
            ).sum(:message_length)
            purchased_messages_amount = user_telegram[:purchased_messages_amount].to_i

            puts "TODAY USAGE: #{today_usage}"
            puts "TODAY TOTAL MESSAGE LENGTH: #{today_total_message_length}"

            user_telegram = UserTelegram.where(telegram_id: user_id).first
            puts "DAY LIMIT: #{user_telegram[:daily_limit]}"
            puts "DAY LENGTH LIMIT: #{user_telegram[:message_day_length_limit]}"

            tokens_ordered_prompt_tokens = user[:tokens_ordered_prompt_tokens] || 100000
            tokens_ordered_completion_tokens = user[:tokens_ordered_completion_tokens] || 100000
            tokens_used_prompt_tokens = user[:tokens_used_prompt_tokens] || 0
            tokens_used_completion_tokens = user[:tokens_used_completion_tokens] || 0

            if tokens_used_prompt_tokens > tokens_ordered_prompt_tokens || tokens_used_completion_tokens > tokens_ordered_completion_tokens
              # Сообщение о том, что превышен лимит токенов и что можно купить новые по адресу https://dev.opuna.com/page/products
              bot.api.send_message(
                chat_id: message.chat.id,
                text: "Your token limit has been exceeded. You can buy new tokens at https://dev.opuna.com/assistant_code"
              )
              next
            end

            MessageHandling.handle_message_with_file(state, bot, message, file_data, file_name, user)

          end
        elsif message.is_a?(Telegram::Bot::Types::CallbackQuery)
          if message.data.start_with?('remove_')
            assistant_id = message.data.sub('remove_', '')
            # Логика для подтверждения удаления ассистента
            AssistantManagement.confirm_removal(state, bot, assistant_id, message.from.id)
          elsif message.data == 'confirm_remove'
            # Логика для выполнения удаления
            AssistantManagement.perform_removal(state, bot, state.pending_removal_id, message.from.id)
          elsif message.data == 'cancel_remove'
            # Логика для отмены удаления
            bot.api.send_message(chat_id: message.from.id, text: 'Canceling removal.')
          else
            AssistantManagement.handle_assistant_selection(state, bot, message)
          end
        end
      end
    end
  end

  def self.handle_assistant_selection(state, bot, message, user)
    # Проверяем, что сообщение является ответом на запрос выбора ассистента
    if message.is_a?(Telegram::Bot::Types::CallbackQuery)
      # Получаем ID ассистента из callback_data
      id = message.data
      state.update(mongo_assistant_id:id)

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
        text: "You have selected the assistant #{assistant.assistant_name}."
      )

      # Теперь, когда выбран ассистент, можно безопасно вызывать create_message и create_run
      OpenAiService.create_message(state.thread_id, "Hi", 'user', [])
      state.run_id = OpenAiService.create_run(state, state.assistant_id, state.thread_id)

      # Проверка выполнения
      wait_complete = MessageHandling.check_run_completion(state.run_id, state.thread_id, user)
      if wait_complete == false
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "OpenAI timeout. Please try again later.",
          parse_mode: 'Markdown'
        )
        return
      end
    end
  end

  def self.handle_website_visit_command(state, bot, message)
    url = extract_url_from_message(message.text)
    if url.nil?
      return
    end

    website_data = nil
    begin
      website_data = WebBrowserService.scrape(url)
    rescue
      #
    end
    if website_data.nil?
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "We could not get data from the website.",
        parse_mode: 'Markdown'
      )
    else
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "We have successfully received data from the website.",
        parse_mode: 'Markdown'
      )
    end

    website_data
  end

  def self.extract_url_from_message(text)
    # Извлеките URL из текста сообщения
    url_regex = /(https?:\/\/[^\s]+)/
    url = text.match(url_regex)
    if url.nil?
      nil
    else
      url[0]
    end
  end

end
