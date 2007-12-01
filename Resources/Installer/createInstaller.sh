#!/bin/sh

DST=../../build/SmugMugExport.pkg
DOC=SmugMugExport.pmdoc
PKG_MAKER=/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker
VERSION=`/usr/libexec/PlistBuddy ../SmugMugExport-Info.plist -c "Print :CFBundleVersion"`

sudo rm -Rf $DST
sudo $PKG_MAKER --doc $DOC -o $DST
sudo zip -r ${DST}-${VERSION}.zip ${DST}


