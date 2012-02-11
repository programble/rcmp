#!/usr/bin/env ruby

require 'cinch'
require 'cinch/plugins/basic_ctcp'
require 'configru'
require 'json'
require 'open-uri'
require 'sinatra'

Configru.load do
  just 'rcmp.yml'
  options do
    irc do
      nick String, 'RCMP'
      server_blacklist Array, []
    end
    port Fixnum, 8080
  end
end

# Stuff to keep track of IRC connections
class Connection
  @@list = {}

  def self.get(server, port, &block)
    if @@list.include? [server, port]
      block.call(@@list[[server, port]].bot)
    else
      self.new(server, port, &block)
    end
  end

  attr_reader :bot

  def initialize(server, port, &block)
    @bot = Cinch::Bot.new do
      configure do |c|
        c.nick = "RCMP"
        c.server = server
        c.port = port

        c.plugins.plugins = [Cinch::Plugins::BasicCTCP]
        c.plugins.options[Cinch::Plugins::BasicCTCP][:commands] = [:version, :time, :ping]

        @block_ran = false
      end

      on :connect do
        block.call(bot) unless @block_ran
      end
    end

    Thread.new {@bot.start}
    @@list[[server, port]] = self
  end
end

# Web server (Sinatra) stuff
configure do
  set :port, Configru.port
end

# Deprecated
post '/github/:server/:port/:channel' do |server, port, channel|
  send_payload(server, port.to_i, "##{channel}", params[:payload])
  'Deprecated'
end

# Deprecated
post '/github/:server/:channel' do |server, channel|
  send_payload(server, 6667, "##{channel}", params[:payload])
  'Deprecated'
end

post '/:server/:port/:channel' do |server, port, channel|
  send_payload(server, port.to_i, "##{channel}", params[:payload])
  'Success'
end

post '/:server/:channel' do |server, channel|
  send_payload(server, 6667, "##{channel}", params[:payload])
  'Success'
end

get '/' do
  'Pong'
end

# The real guts
def send_payload(server, port, channel, payload)
  return if Configru.irc.server_blacklist.include?(server)

  Connection.get(server, port) do |bot|
    bot.join(channel)
    bot.msg(channel, format_payload(JSON.parse(payload)))
  end
end

def isgd(url)
  # TODO: Timeout?
  open("http://is.gd/api.php?longurl=#{URI.encode(url)}", 'r', &:read)
end

IRC_BOLD = "\x02"

def format_payload(payload)
  s = ''
  commits = payload['commits']

  s << IRC_BOLD << payload['repository']['owner']['name']
  s << '/' << payload['repository']['name'] << IRC_BOLD
  s << ': ' << payload['ref'].split('/').last << ' '
  if commits.length > 1
    s << "(#{commits.length}) "
    s << "<#{isgd(payload['compare'])}>\n"
  end
  commits[0..2].each do |commit|
    s << format_commit(commit, commits.length == 1)
    s << "\n"
  end
  s
end

def format_commit(commit, url)
  s = ''
  s << commit['id'][0..7] << ' '
  s << "<#{isgd(commit['url'])}> " if url
  s << IRC_BOLD << commit['author']['name'] << IRC_BOLD << ' '
  s << IRC_BOLD << '[' << IRC_BOLD
  files = commit['added'].map {|f| "+#{f}"} + commit['removed'].map {|f| "-#{f}"} + commit['modified']
  s << files[0..4].join(' ')
  s << ' ...' if files.length > 5
  s << IRC_BOLD << ']' << IRC_BOLD << ' '
  s << commit['message'].lines.first
end
