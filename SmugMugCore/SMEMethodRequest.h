//
//  SMERequest.h
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMEDecoder.h"
#import "SMEAlbumRef.h"
#import "SMERequest.h"

@interface SMEMethodRequest : NSObject<SMERequest> {
	NSURLConnection *connection;
	
	NSMutableData *mutableResponseData;
	
	SEL callback;
	id target;
	BOOL wasSuccessful;
	BOOL connectionIsOpen;
	BOOL isTracingEnabled;
	
	NSError *error;
	NSHTTPURLResponse *httpResponse;
	
	NSDictionary *requestDict;
	NSURL *requestUrl;
}

+(SMEMethodRequest *)request;

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
-(void)invokeMethodWithURL:(NSURL *)baseUrl 
			   requestDict:(NSDictionary *)dict 
		  responseCallback:(SEL)callback 
			responseTarget:(id)target;

/*!
  @method     wasSuccessful
  @abstract   Returns the YES if the last GET was succcessful and NO if no GET has been performed or the last call was unsucessful.
 */
-(BOOL)wasSuccessful;

/*!
  @method     error
  @abstract   Returns the last error encountered for the connection or nil if no errors have been encountered.
  @discussion This is can be an error from the underlying NSURLConnection or an HTTP error.
 */
-(NSError *)error;

/*!
 @method data
 @abstract Returns the response data from the underlying connection.
 */
-(NSData *)responseData;

-(void)setIsTracingEnabled:(BOOL)v;
@end
