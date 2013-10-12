require 'json'
require 'sinatra/base'

module RCMP
  class Web < Sinatra::Base
    def dispatch(params)
      begin
        payload = JSON.parse(params[:payload])
      rescue JSON::ParserError
        halt 400, 'invalid payload'
      end

      type = [GitHub].find {|type| type.detect(payload) }
      halt 400, 'unknown payload type' unless type

      if server = params[:server]
        port = params[:port] || 6667
        channel = params[:channel]
      else
        server = Configru.irc['default'].server
        port = Configru.irc['default'].port
        channel = params[:channel] || Configru.irc['default'].channel
      end

      IRC[server, port].announce do |irc|
        irc.join(channel) unless irc.channels.include? channel
        Channel(channel).msg(type.format(payload))
      end
    end

    ['/:server/:port/:channel', '/:server/:channel', '/:channel', '/'].each do |route|
      post route do
        dispatch(params)
        'success'
      end
    end

    get '/' do
      'pong'
    end
  end
end
