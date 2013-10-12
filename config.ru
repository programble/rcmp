$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
%w[web].map {|r| require("rcmp/#{r}") }

run RCMP::Web
