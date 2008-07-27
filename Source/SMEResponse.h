//
//  SMEResponse.h
//  SmugMugExport
//
//  Created by Aaron Evans on 6/28/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
 
@protocol SMEDecoder, SMERequest;
@class SMEMethodRequest;

extern NSString *SMESmugMugErrorDomain;

// some snugmug error codes
#define NO_CATEGORIES_FOUND_CODE 15
#define INVALID_LOGIN 1
#define SUCCESS_CODE 0

@interface SMEResponse : NSObject {
	NSDictionary *decodedResponse;
	id smData;
	NSError *error;
}

-(id)initWithCompletedRequest:(NSObject<SMERequest> *)req decoder:(NSObject<SMEDecoder> *)aDecoder;
+(SMEResponse *)responseWithCompletedRequest:(NSObject<SMERequest> *)req decoder:(NSObject<SMEDecoder> *)aDecoder;

// underlying response data decoded as a NSDictionary
-(NSDictionary *)decodedResponse;

// further decoded data using a domain-specific class (see /Types)
-(void)setSMData:(id)data;
-(id)smData;

-(BOOL)wasSuccessful;

-(NSError *)error;

@end
