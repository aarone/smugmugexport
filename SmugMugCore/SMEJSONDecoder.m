//
//  SMEJSONDecoder.m
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "SMEJSONDecoder.h"
#import "JSONKit.h"

@implementation SMEJSONDecoder

+(NSObject<SMEDecoder> *)decoder {
	return [[[[self class] alloc] init] autorelease];
}

-(NSMutableDictionary *)decodedResponse:(NSData *)smResponse {
    return [[JSONDecoder decoder] mutableObjectWithData: smResponse];
}

@end
