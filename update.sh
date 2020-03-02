#!/bin/bash
set -e

repo="https://f-droid.org/repo/"

addCopy() {
cat >> Android.mk <<EOF
include \$(CLEAR_VARS)
LOCAL_MODULE := $2
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := bin/$1
LOCAL_MODULE_CLASS := APPS
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_OVERRIDES_PACKAGES := $3
include \$(BUILD_PREBUILT)

EOF
echo -e "\t$2 \\" >> apps.mk
}

rm -Rf bin apps.mk
cat > Android.mk <<EOF
LOCAL_PATH := \$(my-dir)

EOF
echo -e 'PRODUCT_PACKAGES += \\' > apps.mk

mkdir -p bin
#downloadFromFdroid packageName overrides
downloadFromFdroid() {
	mkdir -p tmp
	if [ ! -f tmp/index.xml ];then
		#TODO: Check security keys
		wget --connect-timeout=10 $repo/index.jar -O tmp/index.jar
		unzip -p tmp/index.jar index.xml > tmp/index.xml
	fi
	marketvercode="$(xmlstarlet sel -t -m '//application[id="'"$1"'"]' -v ./marketvercode tmp/index.xml || true)"
	apk="$(xmlstarlet sel -t -m '//application[id="'"$1"'"]/package[versioncode="'"$marketvercode"'"]' -v ./apkname tmp/index.xml || xmlstarlet sel -t -m '//application[id="'"$1"'"]/package[1]' -v ./apkname tmp/index.xml)"
	while ! wget --connect-timeout=10 $repo/$apk -O bin/$apk;do sleep 1;done
	addCopy $apk $1 "$2"
}


#phh's Superuser
downloadFromFdroid me.phh.superuser
#YouTube viewer
downloadFromFdroid org.schabi.newpipe
#Ciphered SMS
downloadFromFdroid org.smssecure.smssecure "messaging"
#Navigation
downloadFromFdroid net.osmand.plus
#Web browser
#downloadFromFdroid org.mozilla.fennec_fdroid "Browser2 QuickSearchBox"
downloadFromFdroid acr.browser.lightning "Browser2 QuickSearchBox"
#Calendar
downloadFromFdroid ws.xsoh.etar Calendar
#Public transportation
downloadFromFdroid de.grobox.liberario
#Pdf viewer
downloadFromFdroid com.artifex.mupdf.viewer.app
#Keyboard/IME
downloadFromFdroid com.menny.android.anysoftkeyboard "LatinIME OpenWnn"
#Play Store download
downloadFromFdroid com.github.yeriomin.yalpstore
#Mail client
downloadFromFdroid com.fsck.k9 "Email"
#Ciphered Instant Messaging
#downloadFromFdroid im.vector.alpha
#Calendar/Contacts sync
downloadFromFdroid at.bitfire.davdroid
#Nextcloud client
downloadFromFdroid com.nextcloud.client
#Lawnchair launcher
downloadFromFdroid ch.deletescape.lawnchair.plah "Launcher3QuickStep Launcher2 Launcher3"

#TODO: Some social network?
doqnloadFromFdroid org.mariotaku.twidere
#Facebook? Twitter? Reddit? Mastodon?

downloadFromFdroid org.fdroid.fdroid
echo >> apps.mk

rm -Rf tmp
