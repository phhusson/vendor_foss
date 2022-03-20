#!/bin/bash
set -e

repo="https://f-droid.org/repo/"

addCopy() {
	addition=""
	if [ "$2"  == org.mozilla.fennec_fdroid ];then
		unzip bin/$1 lib/*
		addition="
LOCAL_PREBUILT_JNI_LIBS := \\
$(unzip -lv bin/$1 |grep -v Stored |sed -nE 's;.*(lib/arm64-v8a/.*);\t\1 \\;p')

		"
	fi
    if [ "$2" == com.google.android.gms ] || [ "$2" == com.android.vending ] ;then
        addition="LOCAL_PRIVILEGED_MODULE := true"
    fi

cat >> Android.mk <<EOF
include \$(CLEAR_VARS)
LOCAL_MODULE := $2
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := bin/$1
LOCAL_MODULE_CLASS := APPS
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_OVERRIDES_PACKAGES := $3
$addition
$(aapt d badging "bin/$1" |sed -nE "s/uses-library-not-required:'(.*)'/LOCAL_OPTIONAL_USES_LIBRARIES += \1/p")
$(aapt d badging "bin/$1" |sed -nE "s/uses-library:'(.*)'/LOCAL_USES_LIBRARIES += \1/p")
include \$(BUILD_PREBUILT)

EOF
echo -e "\t$2 \\" >> apps.mk
}

addMultiarch() {
    cat >> Android.mk <<EOF
include \$(CLEAR_VARS)
LOCAL_MODULE := $1
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := APPS
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_OVERRIDES_PACKAGES := $3
LOCAL_SRC_FILES := bin/\$(LOCAL_MODULE)_$2_\$(my_src_arch).apk
$addition
$(aapt d badging "bin/$1_$2_arm64.apk" |sed -nE "s/uses-library-not-required:'(.*)'/LOCAL_OPTIONAL_USES_LIBRARIES += \1/p")
$(aapt d badging "bin/$1_$2_arm64.apk" |sed -nE "s/uses-library:'(.*)'/LOCAL_USES_LIBRARIES += \1/p")
include \$(BUILD_PREBUILT)
EOF
echo -e "\t$1 \\" >> apps.mk
}

rm -Rf apps.mk lib
cat > Android.mk <<EOF
LOCAL_PATH := \$(my-dir)
my_archs := arm arm64 x86 x86_64
my_src_arch := \$(call get-prebuilt-src-arch, \$(my_archs))

EOF
echo -e 'PRODUCT_PACKAGES += \\' > apps.mk

mkdir -p bin

#downloadFromFdroid packageName overrides
downloadFromFdroid() {
    mkdir -p tmp
    [ "$oldRepo" != "$repo" ] && rm -f tmp/index.xml
    oldRepo="$repo"
    if [ ! -f tmp/index.xml ];then
        #TODO: Check security keys
        wget --connect-timeout=10 $repo/index.jar -O tmp/index.jar
        unzip -p tmp/index.jar index.xml > tmp/index.xml
    fi
    marketversion="$(xmlstarlet sel -t -m '//application[id="'"$1"'"]' -v ./marketversion tmp/index.xml || true)"
    nativecodes="$(xmlstarlet sel -t -m '//application[id="'"$1"'"]/package[version="'"$marketversion"'"]' -v nativecode -o ' ' tmp/index.xml || true)"

    # If packages have separate nativecodes
    if echo "$nativecodes" |grep -q arm && ! echo "$nativecodes" |grep -q ',' ;then
        for native in $nativecodes;do
            newNative="$(echo $native |sed -e s/arm64-v8a/arm64/g -e s/armeabi-v7a/arm/g)"
            apk="$(xmlstarlet sel -t -m '//application[id="'"$1"'"]/package[version="'"$marketversion"'" and nativecode="'"$native"'"]' -v ./apkname tmp/index.xml)"
            localName="${1}_${marketversion}_${newNative}.apk"
            if [ ! -f bin/$localName ];then
                while ! wget --connect-timeout=10 $repo/$apk -O bin/$localName;do sleep 1;done
            fi
        done
        addMultiarch $1 $marketversion "$2"
    else
        apk="$(xmlstarlet sel -t -m '//application[id="'"$1"'"]/package[version="'"$marketversion"'"]' -v ./apkname tmp/index.xml || xmlstarlet sel -t -m '//application[id="'"$1"'"]/package[1]' -v ./apkname tmp/index.xml)"
        if [ ! -f bin/$apk ];then
            while ! wget --connect-timeout=10 $repo/$apk -O bin/$apk;do sleep 1;done
        fi
        addCopy $apk $1 "$2"
	fi
}


#phh's Superuser
downloadFromFdroid me.phh.superuser
#Navigation
downloadFromFdroid net.osmand.plus
#Web browser
# downloadFromFdroid org.mozilla.fennec_fdroid "Browser2 QuickSearchBox"
#Calendar
downloadFromFdroid ws.xsoh.etar Calendar
#Pdf viewer
downloadFromFdroid com.artifex.mupdf.viewer.app
#Play Store download
downloadFromFdroid com.aurora.store
#Mail client
downloadFromFdroid com.fsck.k9 "Email"
#Ciphered Instant Messaging
#downloadFromFdroid im.vector.alpha
#Calendar/Contacts sync
downloadFromFdroid com.etesync.syncadapter
#Nextcloud client
downloadFromFdroid com.nextcloud.client

downloadFromFdroid com.simplemobiletools.gallery.pro "Photos Gallery Gallery2"

downloadFromFdroid com.aurora.adroid

downloadFromFdroid org.openbmap

repo=https://microg.org/fdroid/repo/
downloadFromFdroid com.google.android.gms
downloadFromFdroid com.google.android.gsf
downloadFromFdroid com.android.vending

repo=https://archive.newpipe.net/fdroid/repo/
#YouTube viewer
downloadFromFdroid org.schabi.newpipe

repo=https://fdroid.bromite.org/fdroid/repo/
downloadFromFdroid org.bromite.bromite "Browser2 QuickSearchBox"
downloadFromFdroid org.bromite.webview "WebView webview"

echo >> apps.mk

rm -Rf tmp
