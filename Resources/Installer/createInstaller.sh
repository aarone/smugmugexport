#!/bin/sh

PKG=SmugMugExport.pkg
DST=../../build/${PKG}
DOC=SmugMugExport.pmdoc
PKG_MAKER=/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker
VERSION=`/usr/libexec/PlistBuddy ../SmugMugExport-Info.plist -c "Print :CFBundleVersion"`
ZIP_FILE=${PKG%%.pkg}-${VERSION}.zip

sudo rm -Rf $DST &&
sudo $PKG_MAKER --doc $DOC -o $DST &&
cd ${DST}/.. &&
sudo zip -r ${ZIP_FILE} ${PKG} 

echo "Installer created: " ${DST}
echo "Zipped installer created: " ${ZIP_FILE}

