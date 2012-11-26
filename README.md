# Action.IO Client for Mac

## Install Gems

`while read -r line; do macgem install $line; done < .gems`

You also need to install a fork of `facon` manually.

```
$ git clone https://github.com/petejkim/facon.git
$ cd facon
facon $ macgem build ./facon.gemspec
facon $ macgem install ./facon-0.5.0.gem
```

## Run Specs

`macrake`

