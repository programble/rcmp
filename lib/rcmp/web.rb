require 'sinatra/base'

module RCMP
  class Web < Sinatra::Base
    get '/' do
      'pong'
    end
  end
end
