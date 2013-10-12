require 'httparty'

module RCMP
  module Shorten
    module_function

    def gitio(url)
      HTTParty.post('http://git.io', body: {url: url}).headers['Location']
    end

    def dagd(url)
      HTTParty.get('http://da.gd/s', query: {url: url}).body.strip
    end
  end
end
