# Action.IO Client for Mac

## Install Gems

```
sudo chown -R $USER:admin /Library/Ruby/Gems/MacRuby
sudo curl https://raw.github.com/gist/4681824/macruby_deploy -o /usr/local/bin/macruby_deploy
macgem install mac_bacon -v 1.3
macgem install fakefs -v 0.4.2 --format-executable
git clone https://github.com/petejkim/facon.git
cd facon
macgem build ./facon.gemspec
macgem install ./facon-0.5.0.gem
cd ..
```

## Install Bundler

```
macgem install bundler -v 1.2.3 --format-executable
macbundle install
```

## Run Specs

`rake`
