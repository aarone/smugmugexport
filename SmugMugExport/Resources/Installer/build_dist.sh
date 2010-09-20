#!/bin/sh

PROJ_ROOT=../../../
PKG=SmugMugExport.pkg
DST=${PROJ_ROOT}/build/
DOC=SmugMugExport.pmdoc
PROJ=${PROJ_ROOT}/SmugMugExport.xcodeproj
PKG_MAKER=/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker
INFO_PLIST=${PROJ_ROOT}/SmugMugExport/Resources/SmugMugExport-Info.plist

if [ ! -f $INFO_PLIST ]; then
	echo "Cannot find plist at '${INFO_PLIST}'"
	exit
fi;

VERSION=`/usr/libexec/PlistBuddy ${INFO_PLIST} -c "Print CFBundleShortVersionString"`
SM_ID=`/usr/libexec/PlistBuddy ${INFO_PLIST} -c "Print :CFBundleIdentifier"`
DISPLAY_NAME=`/usr/libexec/PlistBuddy ${INFO_PLIST} -c "Print :CFBundleDisplayName"`
ZIP_FILE=${PKG%%.pkg}-${VERSION}.zip
CONFIG=Release

echo "Building SmugMug Release"
xcodebuild -project ${PROJ}  -target=${DISPLAY_NAME} -configuration=${CONFIG} &&
echo "Building Distribution from build"
set -x
sudo rm -Rf $DST${PKG} &&
sudo $PKG_MAKER --doc $DOC -o ${DST}${PKG} --id ${SM_ID} --version ${VERSION} --title ${DISPLAY_NAME} &&
cd ${DST} &&
sudo zip -r ${ZIP_FILE} ${PKG} &&
echo "Installer created: " ${DST}${PKG} &&
echo "Zipped installer created: " ${DST}${ZIP_FILE} || echo "Failed to create distribution!"

