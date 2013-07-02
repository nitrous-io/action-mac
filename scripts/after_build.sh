#!/bin/bash
RESOURCES_FOLDER_PATH="$BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH"

echo $RESOURCES_FOLDER_PATH

# copy bundler bundle
mkdir -p "$RESOURCES_FOLDER_PATH/.bundle"
mkdir -p "$RESOURCES_FOLDER_PATH/vendor"
cp -PR "$SRCROOT/.bundle/config" "$RESOURCES_FOLDER_PATH/.bundle"
cp -PR "$SRCROOT/vendor/bundle" "$RESOURCES_FOLDER_PATH/vendor"

# create a symlink for ssh
ACTIONIO_SSH_PATH="$RESOURCES_FOLDER_PATH/actionio-ssh"
rm -f "$ACTIONIO_SSH_PATH"
ln -s /usr/bin/ssh "$ACTIONIO_SSH_PATH"

# codesign fsevent_watch
FSEVENT_BIN_PATH="$RESOURCES_FOLDER_PATH/vendor/bundle/macruby/1.9.2/gems/rb-fsevent-0.9.3/bin/fsevent_watch"
codesign -f -s "Developer ID Application: Jihoon Kim" "$FSEVENT_BIN_PATH"
