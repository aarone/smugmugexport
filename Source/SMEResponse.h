//
//  SMEResponse.h
//  SmugMugExport
//
//  Created by Aaron Evans on 6/28/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol SMEDecoder;
@class SMEMethodRequest;

// some snugmug error codes
#define NO_CATEGORIES_FOUND_CODE 15
#define SUCCESS_CODE 0

@interface SMEResponse : NSObject {
	NSDictionary *decodedResponse;
	NSError *connectionError;
	id smData;
}

-(id)initWithCompletedRequest:(SMEMethodRequest *)data decoder:(NSObject<SMEDecoder> *)aDecoder;
+(SMEResponse *)responseWithCompletedRequest:(SMEMethodRequest *)req decoder:(NSObject<SMEDecoder> *)aDecoder;

-(NSString *)errorMessage;

-(unsigned int)smErrorCode;
-(NSString *)smErrorMessage;

// underlying response data decoded as a NSDictionary
-(NSDictionary *)decodedResponse;

// further decoded data using a domain-specific class (see /Types)
-(void)setSMData:(id)data;
-(id)smData;

-(BOOL)wasSuccessful;

-(NSError *)connectionError;

@end
