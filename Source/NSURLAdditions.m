//
//  NSURLAdditions.m
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "NSURLAdditions.h"
#import "NSStringAdditions.h"

@implementation NSURL (NSURLAdditions)

-(NSURL *)URLByAppendingParameterListWithNames:(NSArray *)names values:(NSArray *)values {
	NSMutableString *parameterList = [NSMutableString stringWithString:@"?"];
	
	int i;
	for(i=0;i<[names count];i++) {
		NSString *aKey = [names objectAtIndex:i];
		id aVal = [values objectAtIndex:i];
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
