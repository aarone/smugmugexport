//
//  SMEDecoder.h
//  SmugMugExport
//
//  Created by Aaron Evans on 9/3/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// decodes the responses we receive from smugmug.
@protocol SMEDecoder

+(NSObject<SMEDecoder> *)decoder;
-(NSDictionary *)decodedResponse:(NSData *)smResponse;

@end
