//
//  SMESession.h
//  SmugMugExport
//
//  Created by Aaron Evans on 10/7/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMEMethodRequest.h"
#import "SMEUploadRequest.h"
#import "SMEUploadObserver.h"

@class SMEAlbumRef, SMEImageRef, SMEAlbum;

/*
 * Interface to SmugMug interface.  Methods map to underlying SmugMug
 * functions (see docs at link below). Upon login, the instance of the
 * session keeps the underlying session id for future requests.  All 
 * non-upload methods take a callback object and selector.  The selector 
 * should take a single parameter, an SMResponse instance.  The response
 * provides generic error handling and reporting and a potentially an
 * domain-specific representation of the response (see /Types for existing
 * domain-specific representations).  The docs below detail the 
 * domain-specific responses for each method.
 *
 * SmugMug API: http://smugmug.jot.com/WikiHome/1.2.0
 */
@interface SMESession : NSObject<SMEUploadRequestObserver> {
	NSString *sessionID;
	NSURL *baseRequestUrl;
	SMEUploadRequest *lastUploadRequest;
	NSObject<SMEUploadObserver>* observer;
}

+(SMESession *)session;
+(SMESession *)sessionWithBaseRequestURL:(NSURL  *)apiBaseUrl;

+(NSString *)UserAgent;

/* response is an SMESessionInfo */
-(void)loginWithTarget:(id)target 
			  callback:(SEL)sel 
			  username:(NSString *)username 
			  password:(NSString *)password 
				apiKey:(NSString *)apiKey;

-(NSString *)sessionID;

/* response has no domain specific representation */
-(void)logoutWithTarget:(id)target
			   callback:(SEL)callback;

/* response is an array of SMEConciseAlbums */
-(void)fetchAlbumsWithTarget:(id)target
					callback:(SEL)callback;

/* response has an array of SMECategory */
-(void)fetchCategoriesWithTarget:(id)target callback:(SEL)callback;

/* response has an array of SMESubCategory */
-(void)fetchSubCategoriesWithTarget:(id)target callback:(SEL)callback;

/* response has no domain specific representation */
-(void)deleteAlbum:(SMEAlbumRef *)ref withTarget:(id)target callback:(SEL)callback;

/* response has no domain specific representation */
-(void)createNewAlbum:(SMEAlbum *)album withTarget:(id)target callback:(SEL)callback;

/* response has no domain specific representation */
-(void)editAlbum:(SMEAlbum *)album withTarget:(id)target callback:(SEL)callback;

/* response is an SMEAlbum */
-(void)fetchExtendedAlbumInfo:(SMEAlbumRef *)ref withTarget:(id)target callback:(SEL)callback;

/* response is an array of SMEImageURLs */
-(void)fetchImageURLs:(SMEImageRef *)imageRef withTarget:(id)target callback:(SEL)callback;


-(void)uploadImage:(SMEImage *)theImage
		 intoAlbum:(SMEAlbumRef *)albumRef
		  observer:(NSObject<SMEUploadObserver> *)anObserver;

-(void)stopUpload;

@end
