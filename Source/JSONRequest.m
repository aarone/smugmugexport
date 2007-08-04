//
//  JSONRequest.m
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "JSONRequest.h"
#import "CJSONDeserializer.h"
#import "Globals.h"

@implementation JSONRequest

+(JSONRequest *)request {
	return [[[[self class] alloc] init] autorelease];
}

-(id)decodedResponse {
	NSString *responseString = [[[NSString alloc] initWithData:[self response] encoding:NSUTF8StringEncoding] autorelease];
	
	if(NetworkTracingEnabled) {
		NSLog(@"response: %@", responseString);
	}
	
	return [[CJSONDeserializer deserializer] deserialize:responseString];
}

@end
