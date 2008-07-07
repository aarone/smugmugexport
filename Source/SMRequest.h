//
//  SMRequest.h
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMDecoder.h"
#import "SMUploadObserver.h"
#import "SMAlbumRef.h"

// protocol for monitoring an upload
@protocol SMUploadRequestObserver
-(void)uploadMadeProgress:(SMRequest *)request bytesWritten:(long)numberOfBytes ofTotalBytes:(long)totalBytes;
-(void)uploadFailed:(SMRequest *)request withError:(NSString *)reason;
-(void)uploadCanceled:(SMRequest *)request;
-(void)uploadSucceeded:(SMRequest *)request;
@end


extern NSString *SMUploadKeyImageData;
extern NSString *SMUploadKeyFilename;
//extern NSString *SMUploadKeySessionId;
//extern NSString *SMUploadKeyCaption;
//extern NSString *SMUploadKeyAlbumId;
//extern NSString *SMUploadKeyKeywords;

@interface SMRequest : NSObject {
	NSURLConnection *connection;
	NSMutableData *response;
	CFReadStreamRef readStream;
	CFRunLoopRef uploadRunLoop;
	SEL callback;
	id target;
	BOOL wasSuccessful;
	BOOL connectionIsOpen;
	NSError *error;
	
	NSDictionary *requestDict;
	NSURL *requestUrl;
	
	// upload stuff
	NSObject<SMUploadRequestObserver> *observer;
	BOOL isUploading;
	NSData *imageData;
}

+(SMRequest *)request;

#pragma mark REST method invocation API

/*!
 @method     requestDict
 @abstract   Returns the key/val pairs for the last request method.
 @discussion This method returns a non-nil value only if a method has been invoked
	with specified keys.
 */
-(NSDictionary *)requestDict;

/*!
    @method     requestUrl
    @abstract   Returns the url associated with this request. 
    @discussion Returns the url associated with this request. 
*/
-(NSURL *)requestUrl;

/*!
  @method     invokeMethod:responseCallback:responseTarget
  @abstract   Performs a GET at the given url and return the response to the given target.
  @discussion The callback should take a parameter which will be the RESTCall that originally invoked the method.
*/
-(void)invokeMethod:(NSURL *)url responseCallback:(SEL)callback responseTarget:(id)target;

/*!
 @method     invokeMethodWithURL:keys:values:responseCallback:responseTarget:
 @abstract   performs a GET for the given url and append a sequence of key=val parameters to the URL
 @discussion The keys and values will be escaped and the callback semantics are the same as invokeMethod:responseCallback:responseTarget
 */
-(void)invokeMethodWithURL:(NSURL *)baseUrl requestDict:(NSDictionary *)dict responseCallback:(SEL)callback responseTarget:(id)target;

-(void)uploadImageData:(NSData *)theImageData
			  filename:(NSString *)filename
			 sessionId:(NSString *)sessionId
				 album:(SMAlbumRef *)albumRef
			   caption:(NSString *)caption
			  keywords:(NSArray *)keywords
			  observer:(NSObject<SMUploadRequestObserver> *)anObserver;

-(void)cancelUpload;

/*!
  @method     wasSuccessful
  @abstract   Returns the YES if the last GET was succcessful and NO if no GET has been performed or the last call was unsucessful.
 */
-(BOOL)wasSuccessful;

/*!
  @method     error
  @abstract   Returns the last error encountered during the REST call or nil if no errors have been encountered.
  @discussion This is simply the error from the underlying NSURLConnection.
 */
-(NSError *)error;

-(NSData *)imageData; // the last set image data for an upload

-(NSData *)data;

@end
