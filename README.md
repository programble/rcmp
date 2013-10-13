# RCMP

RCMP is a low-maintenance VCS push notification IRC bot with support for
GitHub, Bitbucket and Travis CI.

## Usage

RCMP accepts webhook POSTs on the following URLs:

 * `/`: Notification will be sent to default server and channel (see
   [Configuration](#configuration))
 * `/:channel`: Notification will be sent to `:channel` on default
   server
 * `/:server/:channel`: Notification will be sent to `:channel` on
   `:server`

For all endpoints, `:channel` is the channel name without the leading
`#`. For channels with two leading hashes, the second must be URL
encoded, i.e. `%23`. `:server` is either a server address (e.g.
`irc.freenode.net`) or a server name/alias (e.g. `freenode` or `fn`).
See [Configuration](#configuration) for details.

### GitHub

Add the WebHook URL to the Service Hooks in your repository's Settings.

### Bitbucket

Add a POST Hook in your repository's Administration page.

### Travis CI

Add the following to your project's `.travis.yml`:

```yaml
notifications:
  webhooks:
    - http://rcmp.instance/server/channel
```

### Sample output

```irc
<RCMP> programble/rcmp: master f234586 <http://git.io/LMlhbQ> Curtis McEnroe [README.md] Update documentation
```

```irc
<RCMP> programble/rcmp: master (11) <http://git.io/qbks9w>
<RCMP> ebd6793 Curtis McEnroe [lib/rcmp/config.rb lib/rcmp/irc.rb lib/rcmp/web.rb] Change format for configuring IRC servers
<RCMP> c3514e5 Curtis McEnroe [lib/rcmp/web.rb] Fix selecting server/channel from URI
<RCMP> 51f504b Curtis McEnroe [lib/rcmp/github.rb lib/rcmp/web.rb] Add payload source verification
```

```irc
<RCMP> programble/configru: master 88f6665 <http://da.gd/XcbB> build #68 passed
```

## Set up

First, fetch the dependencies using Bundler:

```sh
bundle install
```

Start RCMP using Rack's `rackup` command.

### Configuration

RCMP loads server configuration from the YAML file specified in the
`CONFIG_FILE` environment variable, or by default `rcmp.yml`.

The configuration file format is the following:

```yaml
irc:
  servers:
    name:
      address: irc.example.com
      port: 6667 # optional
      nick: RCMP
      nickserv: password # optional
      alias: # optional
        - example
        - ex
    othername:
      # ...
```

The configuration file must contain at least one server named `default`,
which will be the default destination for notifications. This server
must also contain a `channel` key which will be the default channel for
notifications.

## License

Copyright © 2011-2013, Curtis McEnroe <programble@gmail.com>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
