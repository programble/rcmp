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

## Configuration

Configuration is stored in `rcmp.yml`.

```yaml
# HTTP port to listen for payloads on
port: 8080

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
