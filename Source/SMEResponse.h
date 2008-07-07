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
-(id)smData;
-(unsigned int)code;
-(NSString *)errorMessage;
-(NSDictionary *)response;
-(void)setSMData:(id)data;
-(BOOL)wasSuccessful;

@end
