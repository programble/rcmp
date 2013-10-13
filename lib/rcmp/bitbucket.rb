module RCMP
  module Bitbucket
    HOOK_IPS = ['131.103.20.165', '131.103.20.166']

    module_function

    def detect(payload)
      payload['canon_url']
    end

    def verify(request)
      HOOK_IPS.include? request.ip
    end

    def format(payload)
      repo = payload['repository']['owner'] + '/' + payload['repository']['slug']
      commits = payload['commits'].reject do |commit|
        commit['message'].include? '[irc skip]'
      end
      return if commits.empty?

      s = String.new
      s << Cinch::Formatting.format(:bold, repo) << ': '
      s << commits.last['branch'] << ' '

      if commits.length > 1
        s << "(#{commits.length})\n"
        # Bitbucket doesn't have compare URLs for arbitrary commits
      end

      commits.last(3).each do |commit|
        url = payload['canon_url'] + payload['repository']['absolute_url'] +
          'commits/' + commit['raw_node']

        files = commit['files'].group_by {|f| f['type'] }
        files.default = []
        files['added'].map! {|f| "+#{f['file']}" }
        files['modified'].map! {|f| f['file'] }
        files['removed'].map! {|f| "-#{f['file']}" }
        files = files['added'] + files['modified'] + files['removed']

        s << commit['node'][0..6] << ' '
        s << "<#{Shorten.dagd(url)}> "
        s << Cinch::Formatting.format(:bold, commit['author']) << ' '
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
