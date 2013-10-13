module RCMP
  module Travis
    module_function

    def detect(payload)
      payload['matrix']
    end

    def verify(payload)
      true
    end

    def format(payload)
      repo = payload['repository']['owner_name'] + '/' + payload['repository']['name']
      build_url = "http://travis-ci.org/#{repo}/builds/#{payload['id']}"

      [
        Cinch::Formatting.format(:bold, repo) + ':',
        payload['branch'],
        payload['commit'][0..6],
        "<#{Shorten.dagd(build_url)}>",
        "build ##{payload['number']}",
        payload['status_message'].downcase
      ].join(' ')
    end
  end
end
