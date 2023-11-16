#!/bin/bash -l
export RACK_ENV=production
cd /var/www/assistant
/home/vertalm/.rvm/rubies/ruby-3.2.2/bin/bundle exec rake telegramgptbot:run_bot
