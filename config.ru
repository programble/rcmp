$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
%w[config irc shorten github travis bitbucket web].map {|r| require("rcmp/#{r}") }

run RCMP::Web
