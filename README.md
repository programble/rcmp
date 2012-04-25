# RCMP

![](http://stillmaintained.com/programble/rcmp.png)

A Github commit hook IRC bot written in Ruby with Sinatra and Cinch.

# Using

To use, set up and run RCMP (by default it listens on port 8080, so have that
forwarded, or change it by creating an `rcmp.yml` config, with the following:

```yaml
options:
  port: 8081
```

...changing 8081 to the port of your choice. Remember that on *nix, to bind
to a port below 1024, you must run the bot as root (not recommended).

Also remember to open up that port on your firewall.

Once you have the bot running, select a repository on Github on which you have
admin capabilities. Click the admin button, go to 'Service Hooks', and click
on the top one in the list, 'Post-Receive URLs'.

Type in the URL in the field in the following format:

http://your.rcmp.host:port/irc.network/channel

For example: http://foobar.com:8081/irc.freenode.net/myproject will make the
bot (running on foobar.com:8081) connect to irc.freenode.net and announce
commits to #myproject.

You can click the test hook if your repo has several commits in it, to ensure
that the bot is working. The bot will not join a channel until it receives a
POST from Github. The bot will remain in the channel indefinitely (until it is
forcibly disconnected or removed).

# Skipping Commits

You can make certain commits not be announced (useful if you're testing a bunch
of small commits for some reason. Simply put the text `[irc skip]` somewhere in
your commit message, and the bot will skip over that commit.

## License

Copyright (c) 2012-present, Curtis McEnroe <programble@gmail.com>

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
