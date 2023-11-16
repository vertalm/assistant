#!/bin/bash -l
export RACK_ENV=production
source /home/vertalm/.rvm/environments/default
cd /var/www/assistant
/home/vertalm/.rvm/rubies/ruby-3.2.2/bin/bundle exec rake telegramgptbot:run_bot
