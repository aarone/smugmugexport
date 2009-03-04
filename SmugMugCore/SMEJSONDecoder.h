//
//  SMEJSONDecoder.h
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMEDecoder.h"

@interface SMEJSONDecoder : NSObject<SMEDecoder> {
}

+(NSObject<SMEDecoder> *)decoder;
-(NSDictionary *)decodedResponse:(NSData *)smResponse;

@end
