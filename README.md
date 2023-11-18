# Telegram Bot с интеграцией OpenAI

Этот проект представляет собой Telegram бота, который интегрирован с API OpenAI, что позволяет боту выступать в роли ассистента, отвечающего на запросы пользователей с использованием расширенных возможностей искусственного интеллекта.

## Особенности бота

- Взаимодействие с API OpenAI для обработки команд и текстовых запросов.
- Поддержка нескольких пользовательских сессий одновременно.
- Хранение состояния и данных сессий в MongoDB.

## Как начать

Чтобы запустить этот бот, вам потребуется выполнить несколько шагов по настройке вашего окружения и учетных записей.

### Необходимые условия

- Учетная запись на [OpenAI](https://openai.com/) для получения CHAT_GPT_TOKEN.
- Бот в Telegram, созданный через [BotFather](https://t.me/botfather), для получения TELEGRAM_BOT_TOKEN.
- Учетная запись на [MongoDB](https://www.mongodb.com/) и доступ к серверу баз данных для создания DEV и PROD баз данных.

### Установка и настройка

1. Установите Ruby 3.2.2, желательно с использованием RVM:

- rvm install 3.2.2
- rvm use 3.2.2

2. Клонируйте репозиторий проекта:

- git clone https://github.com/vertalm/assistant
- cd telegram-bot

3. Установите все зависимости с помощью Bundler:

- bundle install

4. Создайте файл конфигурации .env в директории app с следующим содержимым

```
TELEGRAM_BOT_TOKEN=***
CHAT_GPT_TOKEN=***

MONGO_DB_DEV=***
MONGO_USER_DEV=***
MONGO_HOST_DEV=***
MONGO_PASSWORD_DEV=***

MONGO_DB_PROD=***
MONGO_USER_PROD=***
MONGO_HOST_PROD=***
MONGO_PASSWORD_PROD=***

ADMINISTRATOR_USERNAME=https://t.me/***
```

### Конфигурация базы данных MongoDB

Вы должны создать базы данных и пользователей для DEV и PROD окружений. Обратитесь к документации MongoDB для получения инструкций по созданию баз данных и пользователей.

### Запуск бота

Чтобы запустить бота, выполните:

rake telegramgptbot:run_bot

## Работа с ботом

После запуска, вы можете общаться с вашим ботом в Telegram, отправляя ему сообщения, и он будет использовать OpenAI для их обработки.

## Контрибьютинг

Мы приветствуем ваши предложения и исправления через систему Pull Requests.

## Лицензия

Проект распространяется под лицензией MIT. Смотрите файл `LICENSE` для дополнительной информации.

Дополнительно для установки Chrome браузера и драйвера:
- wget https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/119.0.6045.105/linux64/chrome-linux64.zip
- unzip chrome-linux64.zip -d ~/chrome-119
- sudo ln -sf ~/chrome-119/chrome-linux64/chrome /usr/bin/chromium-browser
- /usr/bin/chromium-browser --version

- wget https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/119.0.6045.105/linux64/chromedriver-linux64.zip
- unzip chromedriver-linux64.zip -d ~/chromedriver-linux64
- sudo mv /chromedriver-linux64/chromedriver /usr/bin/chromedriver

