//
//  SMEDataAdditions.m
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "SMEDataAdditions.h"
#import "SMGlobals.h"

@implementation NSString (SMEDataAdditions)

-(NSString *)urlEscapedString {
	NSString *escapedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																				  (CFStringRef)self,
																				  NULL,
																				  CFSTR("?=&+'"),
																				  kCFStringEncodingUTF8);
	return [escapedString autorelease];	
}

// version strings are ${major}.${minor}.${micro}.${qualifier}
// where all components except qualifier are integers and qualifier
// is a alphanumeric string
-(NSComparisonResult)compareVersionToVersion:(NSString *)aVersion {
	NSArray *thisComponents = [self componentsSeparatedByString:@"."];
	NSArray *thatComponents = [aVersion componentsSeparatedByString:@"."];
	
	if(IsEmpty(thisComponents))
		return NSOrderedSame;
	if(IsEmpty(thatComponents))
		return NSOrderedSame;
	
	NSNumber *thisMajor = [NSNumber numberWithInt:[[thisComponents objectAtIndex:0] intValue]];
	NSNumber *thatMajor = [NSNumber numberWithInt:[[thatComponents objectAtIndex:0] intValue]];
	NSNumber *thisMinor = [thisComponents count] > 1 ? [NSNumber numberWithInt:[[thisComponents objectAtIndex:1] intValue]] : nil;
	NSNumber *thatMinor = [thatComponents count] > 1 ? [NSNumber numberWithInt:[[thatComponents objectAtIndex:1] intValue]]  : nil;
	NSNumber *thisMicro = [thisComponents count] > 2 ? [NSNumber numberWithInt:[[thisComponents objectAtIndex:2] intValue]] : nil;
	NSNumber *thatMicro = [thatComponents count] > 2 ? [NSNumber numberWithInt:[[thatComponents objectAtIndex:2] intValue]] : nil;
	NSString *thisQualifier = [thisComponents count] > 3 ? [thisComponents objectAtIndex:3] : nil;
	NSString *thatQualifier = [thatComponents count] > 3 ? [thatComponents objectAtIndex:3] : nil;
	
	NSComparisonResult result ;
	if((result = [thisMajor compare:thatMajor]) != NSOrderedSame)
		return result;
	
	// 2.X > 2 
	if(thisMinor == nil && thatMinor != nil)
		return NSOrderedAscending;
	else if(thisMinor != nil && thatMinor == nil)
		return NSOrderedDescending;
	
	if((result = [thisMinor compare:thatMinor]) != NSOrderedSame)
		return result;
	
	// 2.3.0 > 2.3
	if(thisMicro == nil && thatMicro != nil)
		return NSOrderedAscending;
	else if(thisMicro != nil && thatMicro == nil)
		return NSOrderedDescending;
	
	if((result = [thisMicro compare:thatMicro]) != NSOrderedSame)
		return result;
	
	// 2.3.0.p1 > 2.3.0
	if(thisQualifier == nil && thatQualifier != nil)
		return NSOrderedAscending;
	else if(thisQualifier != nil && thatQualifier == nil)
		return NSOrderedDescending;
	
	return [thisQualifier compare:thatQualifier];
}


@end
