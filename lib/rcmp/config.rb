require 'configru'

Configru.load(ENV['CONFIG_FILE'] || 'rcmp.yml') do
  option_group :irc do
    option :servers, Hash, {}
  end
end
