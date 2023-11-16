namespace :telegramgptbot do
  desc "Запустить телеграм-бота"
  task :run_bot => :environment do
    require_relative '../../app/bots/telegram_gpt_bot'
    TelegramGptBot.run
  end
end