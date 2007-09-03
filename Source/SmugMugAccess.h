//
//  SmugMugAccess.h
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMDecoder.h"

@interface SmugMugAccess : NSObject {
	NSURLConnection *connection;
	NSMutableData *response;
	SEL callback;
	id target;
	BOOL wasSuccessful;
	NSError *error;
	NSObject<SMDecoder> * decoder;
}

+(SmugMugAccess *)smugMugAccess:(NSObject<SMDecoder> *)decoder;

#pragma mark REST method invocation API
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
-(void)invokeMethodWithURL:(NSURL *)baseUrl keys:(NSArray *)keys values:(NSArray *)values responseCallback:(SEL)callback responseTarget:(id)target;

	/*!
    @method     invokeMethodWithURL:keys:valueDict:responseCallback:responseTarget:
	 @abstract   Invokes invokeMethodWithURL:keys:values:responseCallback:responseTarget: with the keys and values given by the given dictionary.
	 */
-(void)invokeMethodWithURL:(NSURL *)baseURL keys:(NSArray *)keys valueDict:(NSDictionary *)keyValDict responseCallback:(SEL)callback responseTarget:(id)target;

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

-(NSDictionary *)decodedResponse;

+(NSString *)userAgent;
@end
