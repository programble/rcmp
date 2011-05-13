#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'cinch'
require 'open-uri'
require 'json'
require 'yaml'

class RCMP < Sinatra::Base
  def initialize
    @servers = {}
    
    File.open(File.join(File.dirname(__FILE__), 'config.yml'), 'r') do |f|
      @config = YAML.load(f)
    end
    
    set :port, @config['port']
  end
  
  def notify(server, port, channel, payload)
    if @servers.include?(server)
      @servers[server].join(channel)
      @servers[server].msg(channel, format_payload(payload))
    else
      sent = false
      @servers[server] = Cinch::Bot.new do
        configure do |c|
          c.nick = "RCMP"
          c.server = server
          c.port = port
          c.channels = [channel]
        end
        
        on :join do |m|
          if m.user.nick == bot.nick && m.channel.name == channel
            m.channel.msg(format_payload(payload)) unless sent
            sent = true
          end
        end
      end
      Thread.new { @servers[server].start }
    end
  end
  
  def format_payload(payload)
    payload = JSON.parse(payload)
    if payload['commits'].length > 1
      commits = payload['commits'][0..2].map {|x| format_commit(x, false)}
      commits << "(#{payload['commits'].length - 3} more commits)" if payload['commits'].length > 3
      "\x02#{payload['repository']['owner']['name']}/#{payload['repository']['name']}\x02: #{payload['commits'].length} commits on #{payload['ref'].split('/').last} <#{isgd(payload['compare'])}> #{payload['repository']['open_issues']} open issues\n#{commits.join("\n")}"
    else
      "\x02#{payload['repository']['owner']['name']}/#{payload['repository']['name']}\x02: #{payload['ref'].split('/').last} #{format_commit(payload['commits'][0], true)}"
    end
  end
  
  def format_commit(commit, url)
    short_url = url ? "<#{isgd(commit['url'])}> " : nil
    files = commit['added'].map {|x| "+" + x} + commit['removed'].map {|x| "-" + x} + commit['modified']
    "#{short_url}\x02#{commit['author']['name']}\x02: #{commit['id'][0..7]}\x02 [\x02#{files.join(' ')}\x02]\x02 #{commit['message']}"
  end
  
  def isgd(url)
    url = URI.encode(url)
    open("http://is.gd/api.php?longurl=#{url}", 'r') { |file| file.read }
  end
  
  post '/github/:server/:port/:channel' do
    notify(params[:server], params[:port].to_i, "##{params[:channel]}", params[:payload])
    'Payload received, sir!'
  end
  
  post '/github/:server/:channel' do
    notify(params[:server], 6667, "##{params[:channel]}", params[:payload])
    'Payload received, sir!'
  end
  
  get '/' do
    'Reporting for duty, sir!'
  end
end

rcmp = RCMP.new
