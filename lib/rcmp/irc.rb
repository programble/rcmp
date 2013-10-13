require 'cinch'
require 'cinch/plugins/basic_ctcp'
require 'cinch/plugins/identify'

module RCMP
  class IRC < Cinch::Bot
    @@list = Hash.new

    def self.[](server)
      if irc = @@list[server]
        irc
      else
        irc = self.new(server)
        irc.start!
        @@list[server] = irc
      end
    end

    attr_accessor :connected
    attr_reader :thread, :announce_hook

    def initialize(server)
      super()

      configure do |c|
        c.nick = server['nick']
        c.server = server['address']
        c.port = server['port'] || 6667

        c.plugins.plugins = [Cinch::Plugins::BasicCTCP]
        c.plugins.options[Cinch::Plugins::BasicCTCP][:commands] = [:version, :time, :ping]

        if nickserv = server['nickserv']
          c.plugins.plugins << Cinch::Plugins::Identify
          c.plugins.options[Cinch::Plugins::Identify] = {
            :type => :nickserv,
            :username => c.nick,
            :password => nickserv
          }
        end
      end

      @connected = false
      if server['nickserv']
        on :identified do
          bot.connected = true
        end
      else
        on :connect do
          bot.connected = true
        end
      end
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
