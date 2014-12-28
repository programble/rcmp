require 'ipaddr'

module RCMP
  module GitHub
    HOOK_IPS = ['204.232.175.64/27', '192.30.252.0/22'].map {|ip| IPAddr.new(ip) }

    module_function

    def detect(payload)
      payload['ref']
    end

    def verify(request)
      HOOK_IPS.any? {|ip| ip.include? request.ip }
    end

    def format(payload)
      repo = payload['repository']['full_name']
      branch = payload['ref'].split('/', 3).last
      commits = payload['commits'].reject do |commit|
        commit['message'].include? '[irc skip]'
      end
      return if commits.empty?

      s = String.new
      s << Cinch::Formatting.format(:bold, repo) << ': '
      s << branch << ' '

      if commits.length > 1
        s << "(#{commits.length}) "
        s << "<#{Shorten.gitio(payload['compare'])}>\n"
      end

      commits.last(3).each do |commit|
        added = commit['added'].map {|f| "+#{f}" }
        modified = commit['modified']
        removed = commit['removed'].map {|f| "-#{f}" }
        files = added + modified + removed

        s << commit['id'][0..6] << ' '
        s << "<#{Shorten.gitio(commit['url'])}> " if commits.length == 1
        s << Cinch::Formatting.format(:bold, commit['author']['name']) << ' '
        s << Cinch::Formatting.format(:bold, '[')
        s << files.first(5).join(' ')
        s << ' ...' if files.length > 5
        s << Cinch::Formatting.format(:bold, ']') << ' '
        s << commit['message'].lines.first
        s << "\n"
      end

      return s
    end
  end
end
