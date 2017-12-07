NWJS_VER='0.27.0-beta1-sdk'
APP_NAME='Web.Cinema'

shopt -s extglob

rm -rf /tmp/$APP_NAME/$APP_NAME.app
mkdir -p /tmp/$APP_NAME
cp -r ~/.nwjs/$NWJS_VER/nwjs.app /tmp/$APP_NAME/$APP_NAME.app
mkdir /tmp/$APP_NAME/$APP_NAME.app/Contents/Resources/app.nw
cp -r !(node_modules|bower_components) /tmp/$APP_NAME/$APP_NAME.app/Contents/Resources/app.nw
( cd /tmp/$APP_NAME/$APP_NAME.app/Contents/Resources/app.nw && npm install && bower install )
( cd /tmp/$APP_NAME && 7z a $APP_NAME.zip $APP_NAME.app && mv $APP_NAME.zip ~/var/Dropbox/Public/Code/$APP_NAME.zip )

