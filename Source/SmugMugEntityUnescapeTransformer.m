//
//  SmugMugEntityUnescapeTransformer.m
//  SmugMugExport
//
//  Created by Aaron Evans on 11/18/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import "SmugMugEntityUnescapeTransformer.h"
#import "NSStringICUAdditions.h"

@implementation SmugMugEntityUnescapeTransformer

+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(NSString *)value {
    if (value == nil) 
		return nil;
	
	/*
	 * characters like #34 are turned into html entities &#34; and then decoded as html strings
	 */
	NSString *tmp = [value replaceOccurrencesOfPattern:@"(#[0-9]+)" withString:@"&$1;"];
	NSDictionary *dict = nil; // ignore
	NSAttributedString *decodedString = [[[NSAttributedString alloc] initWithHTML:[tmp dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:&dict] autorelease];
	return [decodedString string];
	
}
@end
 