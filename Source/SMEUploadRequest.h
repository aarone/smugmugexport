//
//  SMEUploadRequest.h
//  SmugMugExport
//
//  Created by Aaron Evans on 7/13/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SMEUploadRequest, SMEAlbumRef;

// protocol for monitoring an upload
@protocol SMEUploadRequestObserver
-(void)uploadMadeProgress:(SMEUploadRequest *)request bytesWritten:(long)numberOfBytes ofTotalBytes:(long)totalBytes;
-(void)uploadFailed:(SMEUploadRequest *)request withError:(NSString *)reason;
-(void)uploadCanceled:(SMEUploadRequest *)request;
-(void)uploadComplete:(SMEUploadRequest *)request;
@end

@interface SMEUploadRequest : NSObject {
	CFRunLoopRef uploadRunLoop;
	CFReadStreamRef readStream;
	
	NSObject<SMEUploadRequestObserver> *observer;
	BOOL isUploading;
	NSMutableData *response;

	NSData *imageData;
	NSString *filename;
	NSString *sessionId;
	SMEAlbumRef *albumRef;
	NSString *caption;
	NSArray *keywords;
}

+(SMEUploadRequest *)uploadRequest;
-(void)uploadImageData:(NSData *)theImageData
			  filename:(NSString *)filename
			 sessionId:(NSString *)sessionId
				 album:(SMEAlbumRef *)albumRef
			   caption:(NSString *)caption
			  keywords:(NSArray *)keywords
			  observer:(NSObject<SMEUploadRequestObserver> *)anObserver;

-(void)cancelUpload;
-(NSData *)responseData;

// the parameters set data for the upload
-(NSString *)filename;
-(NSData *)imageData; 
-(NSString *)sessionId;
-(SMEAlbumRef *)albumRef;
-(NSString *)caption;
-(NSArray *)keywords;

@end
