//
//  SMDecoder.h
//  SmugMugExport
//
//  Created by Aaron Evans on 9/3/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol SMDecoder

+(NSObject<SMDecoder> *)decoder;
-(NSDictionary *)decodedResponse:(NSData *)smResponse;

@end
