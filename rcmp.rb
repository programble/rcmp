#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'cinch'
require 'cinch/plugins/basic_ctcp'
require 'open-uri'
require 'json'

$servers = {}

def isgd(url)
  url = URI.encode(url)
  open("http://is.gd/api.php?longurl=#{url}", 'r') { |file| file.read }
end

def format_commit(commit, url)
  short_url = url ? "<#{isgd(commit['url'])}> " : nil
  files = commit['added'].map {|x| "+" + x} + commit['removed'].map {|x| "-" + x} + commit['modified']
  files = files[0..4] + ["(#{files.length - 5} more)"] if files.length > 5
  "#{short_url}\x02#{commit['author']['name']}\x02: #{commit['id'][0..7]}\x02 [\x02#{files.join(' ')}\x02]\x02 #{commit['message'].lines.first}"
end

def format_payload(payload)
  payload = JSON.parse(payload)
  if payload['commits'].length > 1
    if payload['commits'].length > 3
      commits = payload['commits'][0..1].map {|x| format_commit(x, false)} + ["And #{payload['commits'].length - 2} other commits..."]
    else
      commits = payload['commits'][0..2].map {|x| format_commit(x, false)}
    end
    "\x02#{payload['repository']['owner']['name']}/#{payload['repository']['name']}\x02: #{payload['commits'].length} commits on #{payload['ref'].split('/').last} <#{isgd(payload['compare'])}> #{payload['repository']['open_issues']} open issues\n#{commits.join("\n")}"
  else
    "\x02#{payload['repository']['owner']['name']}/#{payload['repository']['name']}\x02: #{payload['ref'].split('/').last} #{format_commit(payload['commits'][0], true)}"
  end
end

def notify(server, port, channel, payload)
  if $servers.include?(server)
    $servers[server].join(channel)
    $servers[server].msg(channel, format_payload(payload))
  else
    sent = false
    $servers[server] = Cinch::Bot.new do
      configure do |c|
        c.nick = "RCMP"
        c.server = server
        c.port = port
        c.channels = [channel]
        
        c.plugins.plugins = [Cinch::Plugins::BasicCTCP]
        c.plugins.options[Cinch::Plugins::BasicCTCP][:commands] = [:version, :time, :ping]
      end
      
      on :join do |m|
        if m.user.nick == bot.nick && m.channel.name == channel
          m.channel.msg(format_payload(payload)) unless sent
          sent = true
        end
      end
    end
    Thread.new { $servers[server].start }
  end
end

configure do
  set :port, (ARGV[0] ? ARGV[0].to_i : 8080)
end

# Deprecated
post "/github/:server/:port/:channel" do
  notify(params[:server], params[:port].to_i, "##{params[:channel]}", params[:payload])
  "Stop using this :("
end

# Deprecated
post "/github/:server/:channel" do
  notify(params[:server], 6667, "##{params[:channel]}", params[:payload])
  "Stop using this :("
end

post "/:server/:port/:channel" do
  notify(params[:server], params[:port].to_i, "##{params[:channel]}", params[:payload])
  "Success"
end

post "/:server/:channel" do
  notify(params[:server], 6667, "##{params[:channel]}", params[:payload])
  "Success"
end

get "/:server/*" do
  "Connection: #{$servers[params[:server]] ? 'Active' : 'Not connected'}"
end

get "/" do
  "Active connections: #{$servers.length}"
end
