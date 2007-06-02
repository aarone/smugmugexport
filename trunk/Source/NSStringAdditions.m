//
//  NSStringAdditions.m
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "NSStringAdditions.h"


@implementation NSString (NSStringAdditions)

-(NSString *)urlEscapedString {
	NSString *escapedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																				  (CFStringRef)self,
																				  NULL,
																				  CFSTR("?=&+'"),
																				  kCFStringEncodingUTF8);
	return [escapedString autorelease];	
}

@end
