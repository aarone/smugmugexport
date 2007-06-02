//
//  JSONRequest.m
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "JSONRequest.h"
#import "CJSONDeserializer.h"

@implementation JSONRequest

+(JSONRequest *)request {
	return [[[[self class] alloc] init] autorelease];
}

-(id)decodedResponse {
	NSString *responseString = [[[NSString alloc] initWithData:[self response] encoding:NSUTF8StringEncoding] autorelease];
	return [[CJSONDeserializer deserializer] deserialize:responseString];
}

@end
