#!/bin/bash

repo="https://f-droid.org/repo/"

addCopy() {
	echo -e "PRODUCT_COPY_FILES += \\\\\n\tvendor/foss/bin/$1:system/app/$2/${2}.apk" >> apps.mk
}

rm -Rf bin apps.mk
mkdir -p bin
downloadFromFdroid() {
	mkdir -p tmp
	if [ ! -f tmp/index.xml ];then
		#TODO: Check security keys
		wget $repo/index.jar -O tmp/index.jar
		unzip -p tmp/index.jar index.xml > tmp/index.xml
	fi
	apk="$(xmlstarlet sel -t -m '//application[id="'"$1"'"]/package[1]' -v ./apkname tmp/index.xml)"
	wget $repo/$apk -O bin/$apk
	addCopy $apk $1
}


#YouTube viewer
downloadFromFdroid org.schabi.newpipe
#Ciphered SMS
downloadFromFdroid org.smssecure.smssecure
#Navigation
downloadFromFdroid net.osmand.plus
#Web browser
downloadFromFdroid acr.browser.lightning
#Calendar
downloadFromFdroid ws.xsoh.etar
#Public transportation
downloadFromFdroid de.grobox.liberario
#Barcode scanner
downloadFromFdroid com.google.zxing.client.android
#Pdf viewer
downloadFromFdroid com.artifex.mupdfdemo
#Keyboard/IME
downloadFromFdroid com.menny.android.anysoftkeyboard

wget https://f-droid.org/FDroid.apk -O bin/FDroid.apk
addCopy FDroid.apk FDroid

rm -Rf tmp
