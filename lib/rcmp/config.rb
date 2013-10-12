require 'configru'

Configru.load(ENV['CONFIG_FILE'] || 'rcmp.yml') do
  option_group :irc do
    option :nick, String, 'RCMP'

    option_group :default do
      option_required :server, String
      option :port, Fixnum, 6667
      option_required :channel, String
    end

    option_array :blacklist, String
    option_array :whitelist, String

    option :nicks, Hash, {}
    option :nickserv, Hash, {}
  end
end
