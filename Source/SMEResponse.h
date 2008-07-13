//
//  SMEResponse.h
//  SmugMugExport
//
//  Created by Aaron Evans on 6/28/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol SMEDecoder;
@class SMEData;

@interface SMEResponse : NSObject {
	NSDictionary *response;
	id smData;
}

-(id)initWithData:(NSData *)data decoder:(NSObject<SMEDecoder> *)aDecoder;
+(SMEResponse *)responseWithData:(NSData *)data decoder:(NSObject<SMEDecoder> *)aDecoder;
-(unsigned int)code;
-(NSString *)errorMessage;

// underlying response data decoded as a NSDictionary
-(NSDictionary *)response;

// further decoded data using a domain-specific class (see /Types)
-(void)setSMData:(id)data;
-(id)smData;

-(BOOL)wasSuccessful;

@end
