# README

wget https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/119.0.6045.105/linux64/chrome-linux64.zip
unzip chrome-linux64.zip -d ~/chrome-119
sudo ln -sf ~/chrome-119/chrome-linux64/chrome /usr/bin/chromium-browser
/usr/bin/chromium-browser --version

sudo mv /chromedriver-linux64/chromedriver /usr/bin/chromedriver

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
