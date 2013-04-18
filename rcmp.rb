#!/usr/bin/env ruby

require 'bundler/setup'

require 'cinch'
require 'cinch/plugins/basic_ctcp'
require 'cinch/plugins/identify'
require 'configru'
require 'json'
require 'netaddr'
require 'open-uri'
require 'sinatra'

Configru.load('rcmp.yml') do
  option :port, Fixnum, 8080

  option_array :post_whitelist, String do
    default ['127.0.0.1'] + JSON.parse(open('https://api.github.com/meta').read)['hooks']
    transform do |cidr|
      NetAddr::CIDR.create(cidr)
    end
  end

  option_group :irc do
    option :default_nick, String, 'RCMP'
    option_group :default_dest do
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
        c.nick = Configru.irc.nicks[server] || Configru.irc.default_nick
        c.server = server
        c.port = port

        c.plugins.plugins = [Cinch::Plugins::BasicCTCP]
        c.plugins.options[Cinch::Plugins::BasicCTCP][:commands] = [:version, :time, :ping]

        if Configru.irc.nickserv[server]
          c.plugins.plugins << Cinch::Plugins::Identify
          c.plugins.options[Cinch::Plugins::Identify] = {
            :type => :nickserv,
            :username => c.nick,
            :password => Configru.irc.nickserv[server]
          }
        end

        @block_ran = false
      end

      on :connect do
        block.call(bot) unless @block_ran
        @block_ran = true
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

post '/:server/:port/:channel' do |server, port, channel|
  send_payload(server, port.to_i, "##{channel}", params[:payload])
  'Success'
end

post '/:server/:channel' do |server, channel|
  send_payload(server, 6667, "##{channel}", params[:payload])
  'Success'
end

post '/:channel' do |channel|
  send_payload(Configru.irc.default_dest.server, Configru.irc.default_dest.port, "##{channel}", params[:payload])
  'Success'
end

post '/' do
  send_payload(Configru.irc.default_dest.server, Configru.irc.default_dest.port, Configru.irc.default_dest.channel, params[:payload])
  'Success'
end

get '/' do
  'Pong'
end

# The real guts
def send_payload(server, port, channel, payload)
  if Configru.irc.whitelist.any?
    halt 403 unless Configru.irc.whitelist.include?(server)
  else
    halt 403 if Configru.irc.blacklist.include?(server)
  end

  parsed = JSON.parse(payload) rescue halt(400)
  if parsed['commits'] # Payload from Github
    halt 403 unless Configru.post_whitelist.any? {|cidr| cidr.matches? request.ip }
    formatted = format_github_payload(parsed)
  elsif parsed['commit'] # Payload from Travis
    # TODO: Apply whitelist to Travis POSTs
    formatted = format_travis_payload(parsed)
  else # Unknown payload
    halt 400
  end

  Connection.get(server, port) do |bot|
    bot.join(channel)
    bot.Channel(channel).msg(formatted)
  end
end

def dagd(url)
  begin
    open("http://da.gd/s?url=#{URI.encode(url)}&strip=1", 'r', &:read)
  rescue OpenURI::HTTPError => e
    e.to_s
  end
end

IRC_BOLD = "\x02"

# Github stuff

def format_github_payload(payload)
  s = ''
  commits = payload['commits']

  s << IRC_BOLD << payload['repository']['owner']['name']
  s << '/' << payload['repository']['name'] << IRC_BOLD
  s << ': ' << payload['ref'].split('/').last << ' '
  if commits.length > 1
    s << "(#{commits.length}) "
    s << "<#{dagd(payload['compare'])}>\n"
  end

  has_commit = false
  commits[0..2].each do |commit|
    formatted_commit = format_commit(commit, commits.length == 1)
    if formatted_commit
      s << "#{formatted_commit}\n"
      has_commit = true
    end
  end
  s if has_commit
end

def format_commit(commit, url)
  return false if commit['message'].include? '[irc skip]'
  s = ''
  s << commit['id'][0..6] << ' '
  s << "<#{dagd(commit['url'])}> " if url
  s << IRC_BOLD << commit['author']['name'] << IRC_BOLD << ' '
  s << IRC_BOLD << '[' << IRC_BOLD
  files = commit['added'].map {|f| "+#{f}"} + commit['removed'].map {|f| "-#{f}"} + commit['modified']
  s << files[0..4].join(' ')
  s << ' ...' if files.length > 5
  s << IRC_BOLD << ']' << IRC_BOLD << ' '
  s << commit['message'].lines.first
end

# Travis stuff

def format_travis_payload(payload)
  s = ''
  commit = payload['commit']
  owner = payload['repository']['owner_name']
  repository = payload['repository']['name']
  build_id = payload['id']
  build_url = "http://travis-ci.org/#{owner}/#{repository}/builds/#{build_id}"
  last_build = travis_last_build(payload['repository']['id'], payload['number'])
  build_passed = payload['status'].zero?
  last_build_passed = last_build['status'].zero?

  build_status = if !build_passed && last_build_passed
    'failed'
  elsif build_passed && !last_build_passed
    'was fixed'
  elsif !build_passed && !last_build_passed
    'is still failing'
  else # build_passed && last_build_passed
    'passed'
  end

  s << IRC_BOLD << owner << '/' << repository << IRC_BOLD
  s << ': ' << payload['branch'] << ' '
  s << payload['commit'][0..6] << ' '
  s << 'Build #' << payload['number'] << ' ' << build_status << '. '
  s << dagd(build_url)
  s
end

def travis_last_build(repository_id, curr_build_number)
  last_build_number = (curr_build_number.to_i - 1).to_s

  build_list = travis_build_list(repository_id)

  last_build = build_list.find do |build|
    build['number'] == last_build_number
  end

  travis_build_info(last_build['id'])
end

def travis_build_list(repository_id)
  JSON.parse(open("https://api.travis-ci.org/builds?repository_id=#{repository_id}").read)
end

def travis_build_info(build_id)
  JSON.parse(open("https://api.travis-ci.org/builds/#{build_id}").read)
end
