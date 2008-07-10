//
//  SMESession.h
//  SmugMugExport
//
//  Created by Aaron Evans on 10/7/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMERequest.h"

#define NO_CATEGORIES_FOUND_CODE 15

@class SMEAlbumRef, SMEImageRef, SMEAlbum;

/*
 */
@interface SMESession : NSObject<SMEUploadRequestObserver> {
	NSString *sessionID;
	SMERequest *lastUploadRequest;
	NSObject<SMEUploadObserver>* observer;
}

+(SMESession *)session;

-(void)loginWithTarget:(id)target 
			  callback:(SEL)sel 
			  username:(NSString *)username 
			  password:(NSString *)password 
				apiKey:(NSString *)apiKey;

-(void)logoutWithTarget:(id)target
			   callback:(SEL)callback;

-(void)fetchAlbumsWithTarget:(id)target
					callback:(SEL)callback;


-(void)fetchCategoriesWithTarget:(id)target callback:(SEL)callback;

-(void)fetchSubCategoriesWithTarget:(id)target callback:(SEL)callback;

-(void)deleteAlbum:(SMEAlbumRef *)ref withTarget:(id)target callback:(SEL)callback;

-(void)createNewAlbum:(SMEAlbum *)album withTarget:(id)target callback:(SEL)callback;

-(void)editAlbum:(SMEAlbum *)album withTarget:(id)target callback:(SEL)callback;

-(void)fetchExtendedAlbumInfo:(SMEAlbumRef *)ref withTarget:(id)target callback:(SEL)callback;

-(void)fetchImageURLs:(SMEImageRef *)imageRef withTarget:(id)target callback:(SEL)callback;

-(void)uploadImageData:(NSData *)imageData
			  filename:(NSString *)filename
				 album:(SMEAlbumRef *)albumRef
			   caption:(NSString *)caption
			  keywords:(NSArray *)keywords
			  observer:(NSObject<SMEUploadObserver>*)observer;
-(void)stopUpload;



@end
