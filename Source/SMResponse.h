//
//  SMResponse.h
//  SmugMugExport
//
//  Created by Aaron Evans on 6/28/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol SMDecoder;
@class SMData;

@interface SMResponse : NSObject {
	NSDictionary *response;
	id smData;
}

-(id)initWithData:(NSData *)data decoder:(NSObject<SMDecoder> *)aDecoder;
+(SMResponse *)responseWithData:(NSData *)data decoder:(NSObject<SMDecoder> *)aDecoder;
-(id)smData;
-(unsigned int)code;
-(NSString *)errorMessage;
-(NSDictionary *)response;
-(void)setSMData:(id)data;
-(BOOL)wasSuccessful;

@end
