//
//  JSONRequest.m
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "JSONDecoder.h"
#import "CJSONDeserializer.h"
#import "Globals.h"
#import "NSUserDefaultsAdditions.h"

@implementation JSONDecoder

+(NSObject<SMDecoder> *)decoder {
	return [[[[self class] alloc] init] autorelease];
}

-(NSDictionary *)decodedResponse:(NSData *)smResponse {
	NSString *responseString = [[[NSString alloc] initWithData:smResponse encoding:NSUTF8StringEncoding] autorelease];
	
	if(IsNetworkTracingEnabled()) {
		NSLog(@"response: %@", responseString);
	}
	
	return (NSDictionary *)[[CJSONDeserializer deserializer] deserialize:responseString];
}

@end
