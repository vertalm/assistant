#!/bin/bash
export RACK_ENV=production
cd /var/www/assistant
bundle exec rake telegramgptbot:run_bot
