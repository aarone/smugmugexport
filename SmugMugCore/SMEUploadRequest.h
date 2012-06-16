//
//  SMEUploadRequest.h
//  SmugMugExport
//
//  Created by Aaron Evans on 7/13/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMERequest.h"

@class SMEUploadRequest, SMEAlbumRef, SMEImage, SMESession;

// protocol for monitoring an upload
@protocol SMEUploadRequestObserver
-(void)uploadMadeProgress:(SMEUploadRequest *)request bytesWritten:(long)numberOfBytes ofTotalBytes:(long)totalBytes;
-(void)uploadFailed:(SMEUploadRequest *)request withError:(NSString *)reason;
-(void)uploadCanceled:(SMEUploadRequest *)request;
-(void)uploadComplete:(SMEUploadRequest *)request;
@end

@interface SMEUploadRequest : NSObject<SMERequest> {
	CFRunLoopRef uploadRunLoop;
	CFReadStreamRef readStream;
	
	NSObject<SMEUploadRequestObserver> *observer;
	BOOL isUploading;
	BOOL isTracingEnabled;
	NSMutableData *response;
	
	NSString *sessionId;
	SMEAlbumRef *albumRef;
	SMEImage *image;
	SMESession *session;
	
	BOOL wasSuccessful;
	NSError *error;

}

+(SMEUploadRequest *)uploadRequestWithImage:(SMEImage *)anImage
									session:(SMESession *)session
								  intoAlbum:(SMEAlbumRef *)albumRef
								   observer:(NSObject<SMEUploadRequestObserver> *)anObserver;

-(void)beginUpload;

-(void)cancelUpload;
-(NSData *)responseData;

-(SMESession *)session;
-(SMEAlbumRef *)albumRef;
-(SMEImage *)image;

-(NSData *)responseData;

-(BOOL)wasSuccessful;
-(NSError *)error;
-(void)setIsTracingEnabled:(BOOL)v;



@end