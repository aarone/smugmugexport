#!/bin/bash


rm -Rf /Applications/iPhoto.app/Contents/PlugIns/SmugMugExport.iPhotoExporter/ && cp -R ./build/Debug/SmugMugExport.iPhotoExporter /Applications/iPhoto.app/Contents/PlugIns/
