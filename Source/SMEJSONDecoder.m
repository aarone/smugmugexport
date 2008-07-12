//
//  SMEJSONDecoder.m
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "SMEJSONDecoder.h"
#import "SMEGlobals.h"
#import <JSON/JSON.h>

@implementation SMEJSONDecoder

+(NSObject<SMEDecoder> *)decoder {
	return [[[[self class] alloc] init] autorelease];
}

-(NSDictionary *)decodedResponse:(NSData *)smResponse {
	NSString *responseString = [[[NSString alloc] initWithData:smResponse encoding:NSUTF8StringEncoding] autorelease];	
	return (NSDictionary *)[responseString JSONValue];
}

@end
