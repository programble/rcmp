require 'cinch'
require 'cinch/plugins/basic_ctcp'
require 'cinch/plugins/identify'

module RCMP
  class IRC < Cinch::Bot
    # @list[server][port] -> Connection
    @@list = Hash.new {|h, k| h[k] = Hash.new }

    def self.[](server, port)
      if irc = @@list[server][port]
        irc
      else
        irc = self.new(server, port)
        irc.start!
        @@list[server][port] = irc
      end
    end

    attr_accessor :connected
    attr_reader :thread, :announce_hook

    def initialize(server, port)
      super()

      configure do |c|
        c.nick = Configru.irc.nicks[server] || Configru.irc.nick
        c.server = server
        c.port = port

        c.plugins.plugins = [Cinch::Plugins::BasicCTCP]
        c.plugins.options[Cinch::Plugins::BasicCTCP][:commands] = [:version, :time, :ping]

        if nickserv = Configru.irc.nickserv[server]
          c.plugins.plugins << Cinch::Plugins::Identify
          c.plugins.options[Cinch::Plugins::Identify] = {
            :type => :nickserv,
            :username => c.nick,
            :password => nickserv
          }
        end
      end

      @connected = false
      on :connect do
        bot.connected = true
      end

      @@list[server][port] = self
    end

    def start!
      @thread = Thread.new { start }
    end

    def announce(&block)
      if @connected
        @callback.instance_exec(self, &block)
      else
        @announce_hook = on :connect do
          instance_exec(bot, &block)
          bot.handlers.unregister(bot.announce_hook)
        end
      end
    end
  end
end
