#!/bin/bash
git="/usr/bin/env git"
date=`date`
echo "/* Generated at $date */" > config/InfoPlist.h

version=`cat VERSION`
echo "#define AIO_VERSION $version" >> config/InfoPlist.h

git_hash=`$git describe --always`
echo "#define AIO_GIT_HASH $git_hash" >> config/InfoPlist.h

if [ $AIO_ENV == 'production' ]; then
echo "#define AIO_BUNDLE_ID io.nitrous.mac-app" >> config/InfoPlist.h
else
echo "#define AIO_BUNDLE_ID io.nitrous.mac-app-$AIO_ENV" >> config/InfoPlist.h
fi

cat "config/InfoPlist-$AIO_ENV.h" >> config/InfoPlist.h

touch config/Info.plist
