require 'nokogiri'
require 'open-uri'

class WebScraperService
  def self.scrape(url)
    html = open(url)
    doc = Nokogiri::HTML(html)

    # Get the text of whole page
    doc.text
  end
end