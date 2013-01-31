# Action.IO Client for Mac

## Install Gems

```
$ sudo chown -R $USER:admin /Library/Ruby/Gems/MacRuby
$ sudo curl https://raw.github.com/gist/4681824/macruby_deploy -o /usr/local/bin/macruby_deploy
$ macgem install bundler -v 1.2.3 --format-executable
$ macbundle install
```

You also need to install a fork of `facon` manually.

```
$ git clone https://github.com/petejkim/facon.git
$ cd facon
facon $ macgem build ./facon.gemspec
facon $ macgem install ./facon-0.5.0.gem
```

## Run Specs

`macrake`

