require 'selenium-webdriver'

class WebBrowserService
  def self.scrape(url)

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    driver = Selenium::WebDriver.for :chrome, options: options
    driver.get(url)
    wait = Selenium::WebDriver::Wait.new(timeout: 10)
    wait.until { driver.find_element(tag_name: 'body') }
    page_text = driver.find_element(tag_name: 'body').text
    driver.quit
    page_text
  end
end