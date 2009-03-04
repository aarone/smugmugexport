#import "ExportImageProtocol.h"


@interface ExportMgr : NSObject <ExportImageProtocol> {
//    ArchiveDocument *mDocument;
//    NSMutableArray *mExporters;
//    Album *mExportAlbum;
//    // Error parsing type: ^{IPPhotoList={vector<IPPhotoInfo*,std::allocator<IPPhotoInfo*> >="_M_impl"{_Vector_impl="_M_start"^^{IPPhotoInfo}"_M_finish"^^{IPPhotoInfo}"_M_end_of_storage"^^{IPPhotoInfo}}}}, name: mSelection
//    // Error parsing type: ^{IPPhotoList={vector<IPPhotoInfo*,std::allocator<IPPhotoInfo*> >="_M_impl"{_Vector_impl="_M_start"^^{IPPhotoInfo}"_M_finish"^^{IPPhotoInfo}"_M_end_of_storage"^^{IPPhotoInfo}}}}, name: mMovieSelection
//    // Error parsing type: ^{IPAlbumList={vector<Album*,std::allocator<Album*> >="_M_impl"{_Vector_impl="_M_start"^@"Album""_M_finish"^@"Album""_M_end_of_storage"^@"Album"}}{map<Key,Album*,std::less<long unsigned int>,std::allocator<std::pair<const Key, Album*> > >="_M_t"{_Rb_tree<Key,std::pair<const Key, Album*>,std::_Select1st<std::pair<const Key, Album*> >,std::less<long unsigned int>,std::allocator<std::pair<const Key, Album*> > >="_M_impl"{_Rb_tree_impl<std::less<long unsigned int>,false>="_M_key_compare"{less<long unsigned int>=}"_M_header"{_Rb_tree_node_base="_M_color"i"_M_parent"^{_Rb_tree_node_base}"_M_left"^{_Rb_tree_node_base}"_M_right"^{_Rb_tree_node_base}}"_M_node_count"I}}}{_opaque_pthread_mutex_t="__sig"l"__opaque"[40c]}}, name: mSelectedAlbums
//    ExportController *mExportController;
//    ImageDB *mDB;
}

+ (id)exportMgr;
+ (id)exportMgrNoAlloc;
- (id)init;
- (void)dealloc;
- (void)releasePlugins;
- (void)setExportController:(id)fp8;
- (id)exportController;
- (void)setDocument:(id)fp8;
- (id)document;
- (void)updateDocumentSelection;
- (unsigned int)count;
- (id)recAtIndex:(unsigned int)fp8;
- (void)scanForExporters;
- (unsigned int)imageCount;
- (BOOL)imageIsEditedAtIndex:(unsigned int)fp8;
- (BOOL)imageIsPortraitAtIndex:(unsigned int)fp8;
- (id)imagePathAtIndex:(unsigned int)fp8;
- (id)sourcePathAtIndex:(unsigned int)fp8;
- (struct _NSSize)imageSizeAtIndex:(unsigned int)fp8;
- (unsigned long)imageFormatAtIndex:(unsigned int)fp8;
- (unsigned long)originalImageFormatAtIndex:(unsigned int)fp8;
- (BOOL)originalIsRawAtIndex:(unsigned int)fp8;
- (BOOL)originalIsMovieAtIndex:(unsigned int)fp8;
- (id)imageTitleAtIndex:(unsigned int)fp8;

// only for iPhoto 6
-(id)imageCaptionAtIndex:(unsigned int)fp8;

- (id)imageCommentsAtIndex:(unsigned int)fp8;
- (float)imageRotationAtIndex:(unsigned int)fp8;
- (id)thumbnailPathAtIndex:(unsigned int)fp8;
- (float)imageAspectRatioAtIndex:(unsigned int)fp8;
- (unsigned long long)imageFileSizeAtIndex:(unsigned int)fp8;
- (id)imageDateAtIndex:(unsigned int)fp8;
- (int)imageRatingAtIndex:(unsigned int)fp8;
- (id)imageTiffPropertiesAtIndex:(unsigned int)fp8;
- (id)imageExifPropertiesAtIndex:(unsigned int)fp8;
- (id)imageKeywordsAtIndex:(unsigned int)fp8;
- (id)imageFileNameAtIndex:(unsigned int)fp8;
- (void)commitImageRotation;
- (unsigned int)albumCount;
- (id)albumNameAtIndex:(unsigned int)fp8;
- (id)albumMusicPathAtIndex:(unsigned int)fp8;
- (id)albumCommentsAtIndex:(unsigned int)fp8;
- (id)albumsOfImageAtIndex:(unsigned int)fp8;
- (unsigned int)positionOfImageAtIndex:(unsigned int)fp8 inAlbum:(unsigned int)fp12;
- (struct IPPhotoInfo *)photoAtIndex:(unsigned int)fp8;
- (void)enableControls;
- (void)disableControls;
- (id)window;
- (void)clickExport;
- (void)startExport;
- (void)cancelExport;
- (void)cancelExportBeforeBeginning;
- (id)directoryPath;
- (unsigned int)sessionID;
- (id)temporaryDirectory;
- (BOOL)doesFileExist:(id)fp8;
- (BOOL)doesDirectoryExist:(id)fp8;
- (BOOL)createDir:(id)fp8;
- (id)uniqueSubPath:(id)fp8 child:(id)fp12;
- (id)makeUniquePath:(id)fp8;
- (id)makeUniqueFilePath:(id)fp8 extension:(id)fp12;
- (id)makeUniqueFileNameWithTime:(id)fp8;
- (BOOL)makeFSSpec:(id)fp8 spec:(struct FSSpec *)fp12;
- (id)pathForFSSpec:(struct FSSpec *)fp8;
- (BOOL)getFSRef:(struct FSRef *)fp8 forPath:(id)fp12 isDirectory:(BOOL)fp16;
- (id)pathForFSRef:(struct FSRef *)fp8;
- (unsigned long)countFiles:(id)fp8 descend:(BOOL)fp12;
- (unsigned long)countFilesFromArray:(id)fp8 descend:(BOOL)fp12;
- (unsigned long long)sizeAtPath:(id)fp8 count:(unsigned long *)fp12 physical:(BOOL)fp16;
- (BOOL)isAliasFileAtPath:(id)fp8;
- (id)pathContentOfAliasAtPath:(id)fp8;
- (id)stringByResolvingAliasesInPath:(id)fp8;
- (BOOL)ensurePermissions:(unsigned long)fp8 forPath:(id)fp12;
- (id)validFilename:(id)fp8;
- (id)getExtensionForImageFormat:(unsigned long)fp8;
- (unsigned long)getImageFormatForExtension:(id)fp8;
- (struct OpaqueGrafPtr *)uncompressImage:(id)fp8 size:(struct _NSSize)fp12 pixelFormat:(unsigned long)fp20 rotation:(float)fp24 colorProfile:(char ***)fp28;
- (void *)createThumbnailer;
- (void *)retainThumbnailer:(void *)fp8;
- (void *)autoreleaseThumbnailer:(void *)fp8;
- (void)releaseThumbnailer:(void *)fp8;
- (void)setThumbnailer:(void *)fp8 maxBytes:(unsigned int)fp12 maxWidth:(unsigned int)fp16 maxHeight:(unsigned int)fp20;
- (struct _NSSize)thumbnailerMaxBounds:(void *)fp8;
- (void)setThumbnailer:(void *)fp8 quality:(int)fp12;
- (int)thumbnailerQuality:(void *)fp8;
- (void)setThumbnailer:(void *)fp8 rotation:(float)fp12;
- (float)thumbnailerRotation:(void *)fp8;
- (void)setThumbnailer:(void *)fp8 outputFormat:(unsigned long)fp12;
- (unsigned long)thumbnailerOutputFormat:(void *)fp8;
- (void)setThumbnailer:(void *)fp8 outputExtension:(id)fp12;
- (id)thumbnailerOutputExtension:(void *)fp8;
- (BOOL)thumbnailer:(void *)fp8 createThumbnail:(id)fp12 dest:(id)fp16;
- (struct _NSSize)lastImageSize:(void *)fp8;
- (struct _NSSize)lastThumbnailSize:(void *)fp8;
- (BOOL)exportImageAtIndex:(unsigned int)fp8 dest:(id)fp12 options:(void *)fp16;
- (struct _NSSize)lastExportedImageSize;
- (BOOL)_checkForChangedDateLayout;

@end