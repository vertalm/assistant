require 'telegram/bot'
require 'dotenv/load'
require 'mongo'
require_relative 'handlers/command_handlers'
require_relative 'handlers/assistant_management'
require_relative 'handlers/message_handling'

class BotState
  attr_accessor :is_changing_context, :instructions, :fallback_model, :primary_model,
                :switch_time, :assistant_id, :thread_id, :run_id,
                :is_creating_assistant_name, :is_creating_assistant_instruction,
                :mongo_assistant_id, :is_creating_image, :pending_removal_id

  def initialize
    @is_changing_context = false
    @instructions = 'Ты персональный ассистент. Помогаешь писать код на RoR с использованием MongoId.'
    @fallback_model = "gpt-4"
    @primary_model = "gpt-4-1106-preview"
    @switch_time = DateTime.now
    @assistant_id = nil
    @thread_id = nil
    @run_id = nil
    @is_creating_assistant_name = false
    @is_creating_assistant_instruction = false
    @mongo_assistant_id = nil
    @is_creating_image = false
    @pending_removal_id = nil
  end
end

class TelegramGptBot

  @@states = {}

  def self.run
    token = ENV['TELEGRAM_BOT_TOKEN']
    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        user_id = message.chat.id
        @@states[user_id] ||= BotState.new
        state = @@states[user_id]
        if message.is_a?(Telegram::Bot::Types::Message)
          if message.text
            case message.text
            when '/start'
              CommandHandlers.handle_start_command(state, bot, message)
            when '/instructions'
              state.is_changing_context = true
              bot.api.send_message(
                chat_id: message.chat.id,
                text: "Пожалуйста, введи новую инструкцию для ассистента."
              )
            when '/new_assistant'
              state.is_creating_assistant_name = true
              bot.api.send_message(
                chat_id: message.chat.id,
                text: "Введи имя нового ассистента."
              )
            when '/remove_assistant'
              CommandHandlers.handle_remove_assistant_command(state, bot, message)
            when '/new_image'
              CommandHandlers.handle_new_image_command(state, bot, message)
            when '/help'
              CommandHandlers.handle_help_command(bot, message)
            else
              website_data = handle_website_visit_command(state, bot, message)
              if website_data
                MessageHandling.handle_default_message(state, bot, message, website_data)
              else
                MessageHandling.handle_default_message(state, bot, message)
              end
            end
          elsif message.document
            # Обработка документов
            file_id = message.document.file_id
            file_info = bot.api.get_file(file_id: file_id)
            file_path = file_info['result']['file_path']
            file_url = "https://api.telegram.org/file/bot#{token}/#{file_path}"
            file_name = message.document.file_name
            file = URI.open(file_url)
            file_data = file.read
            file.close
            MessageHandling.handle_message_with_file(state, bot, message, file_data, file_name)

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
            bot.api.send_message(chat_id: message.from.id, text: 'Удаление отменено.')
          else
            AssistantManagement.handle_assistant_selection(state, bot, message)
          end
        end
      end
    end
  end

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

  def self.handle_website_visit_command(state, bot, message)
    url = extract_url_from_message(message.text)
    if url.nil?
      return
    end
    website_data = WebBrowserService.scrape(url)
    if website_data.nil?
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Не удалось получить данные с веб-сайта.",
        parse_mode: 'Markdown'
      )
    else
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Данные с веб-сайта получены.",
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
