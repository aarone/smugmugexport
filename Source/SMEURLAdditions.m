//
//  SMEDataAdditions.m
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "SMEDataAdditions.h"
#import "SMEStringAdditions.h"


@implementation NSURL (SMEDataAdditions)

-(NSURL *)URLByAppendingParameterList:(NSDictionary *)params {
	NSMutableString *parameterList = [NSMutableString stringWithString:@"?"];
	
	int i;
	NSArray *names = [params allKeys];
	for(i=0;i<[names count];i++) {
		NSString *aKey = [names objectAtIndex:i];
		id aVal = [params objectForKey:aKey];
		if([aVal isKindOfClass:[NSString class]])
			[parameterList appendFormat:@"%@=%@", aKey, [(NSString *)aVal urlEscapedString]];
		else if([aVal respondsToSelector:@selector(stringValue)])
			[parameterList appendFormat:@"%@=%@", aKey, [[(NSNumber *)aVal stringValue] urlEscapedString]];
		else 
			[parameterList appendFormat:@"%@=%@", aKey, aVal];
		
		if(i<[names count]-1)
			[parameterList appendString:@"&"];
	}
	
	NSMutableString *newUrl = [NSMutableString stringWithString:[self absoluteString]];
	if(![newUrl hasSuffix:@"/"])
		[newUrl appendString:@"/"];
	
	[newUrl appendString:parameterList];
	return [NSURL URLWithString:newUrl];
}
@end
