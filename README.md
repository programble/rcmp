# RCMP

RCMP is a low-maintenance Github commit notification IRC bot with Travis CI integration.

## Usage

RCMP accepts Github and Travis webhook payloads POSTed to:

#### `/`

Notification is sent to default destination.

#### `/:server/:channel`

Example: `/example.org/example`

Notification is sent to `:server` on port 6667 in `:channel`.

#### `/:server/:port/:channel`

Example: `/example.org/6667/example`

Notification is sent to `:server` on `:port` in `:channel`.

### Example Output

```
<RCMP> programble/rcmp: master cbde68d1 <http://da.gd/AHm70> Curtis McEnroe [Gemfile.lock] Update Gemfile.lock
```

```
<RCMP> programble/rcmp: master (3) <http://da.gd/AHm70>
<RCMP> d1ec92fd Curtis McEnroe [Gemfile.lock] Update Gemfile.lock
<RCMP> 72d05d24 Curtis McEnroe [README.md] Remove stillmaintained badge
<RCMP> cbde68d1 Curtis McEnroe [Gemfile Gemfile.lock rcmp.rb] Update to Configru 3.0.0
```

### Travis Integration

To have RCMP announce Travis build results for a project, add the
following to your `.travis.yml`.

```yaml
notifications:
  webhooks:
    - http://your.rcmp.instance/:server/:channel
```

### Custom CI Integration

If you use a CI system other than Travis CI, you can still have your commits
announced.

Send JSON to any of the above URLs (listed in "Usage"), in the following format:

```json
"payload": {
  "custom_ci": true,
  "commit": "the commit hash",
  "branch": "the branch",
  "repository_name": "the repository name",
  "results_url": "where to find the output of the test suite",
  "status": 0 for passing, anything else for failing
}
```

## Configuration

Configuration is stored in `rcmp.yml`.

```yaml
# HTTP port to listen for payloads on
port: 8080

# CIDRs to accept Github webhook POST requests from
# If this option is not provided, RCMP will fetch Github CIDRs from the
# meta API endpoint as well as include 127.0.0.1/32.
post_whitelist:
  - 127.0.0.1

irc:
  # Default nick
  default_nick: RCMP
  # Server-specific nicks
  nicks:
    irc.example.org: potato
  # NickServ passwords
  nickserv:
    irc.example.org: password
  # Default notification destination (for POSTs to /)
  default_dest:
    server: irc.example.org
    port: 6667
    channel: '#example'
  # List of servers to connect to
  whitelist:
    - irc.example.org
  # List of servers to not connect to
  blacklist:
    - irc.example.org
```

## License

Copyright (c) 2011-2012, Curtis McEnroe <programble@gmail.com>

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
