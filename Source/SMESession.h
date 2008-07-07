//
//  SMESession.h
//  SmugMugExport
//
//  Created by Aaron Evans on 10/7/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMRequest.h"


@class SMAlbumRef, SMImageRef, SMAlbum;

/*
 */
@interface SMESession : NSObject<SMUploadRequestObserver> {
	NSString *sessionID;
	SMRequest *lastUploadRequest;
	NSObject<SMUploadObserver>* observer;
}

+(SMESession *)session;

-(void)loginWithTarget:(id)target 
			  callback:(SEL)sel 
			  username:(NSString *)username 
			  password:(NSString *)password 
				apiKey:(NSString *)apiKey;

-(void)fetchAlbumsWithTarget:(id)target
					callback:(SEL)callback;


-(void)fetchCategoriesWithTarget:(id)target callback:(SEL)callback;

-(void)fetchSubCategoriesWithTarget:(id)target callback:(SEL)callback;

-(void)deleteAlbum:(SMAlbumRef *)ref withTarget:(id)target callback:(SEL)callback;

-(void)createNewAlbum:(SMAlbum *)album withTarget:(id)target callback:(SEL)callback;

-(void)editAlbum:(SMAlbum *)album withTarget:(id)target callback:(SEL)callback;

-(void)fetchExtendedAlbumInfo:(SMAlbumRef *)ref withTarget:(id)target callback:(SEL)callback;

-(void)uploadImageData:(NSData *)imageData
			  filename:(NSString *)filename
				 album:(SMAlbumRef *)albumRef
			   caption:(NSString *)caption
			  keywords:(NSArray *)keywords
			  observer:(NSObject<SMUploadObserver>*)observer;
-(void)stopUpload;



@end
