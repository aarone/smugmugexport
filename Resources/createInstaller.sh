#!/bin/sh

DST=../build/SmugMugExport.pkg
PROJ=SmugMugExport.pmproj
PKG_MAKER=PackageMaker

sudo rm -Rf $DST
sudo $PKG_MAKER -build -proj $PROJ -p $DST


