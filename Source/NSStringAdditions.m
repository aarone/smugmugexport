//
//  NSStringAdditions.m
//  SmugMugExport
//
//  Created by Aaron Evans on 11/18/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import "NSStringAdditions.h"
#include <regex.h>

@implementation NSString (NSStringAdditions)

-(BOOL)matchesRegularExpression:(CompiledRegex *)aRegex
{
	return [[self findUsingRegularExpression:aRegex replaceWith:nil] count] > 0;	
}

-(NSArray *)findUsingRegularExpression:(CompiledRegex *)aRegex replaceWith:(NSString *)replacementString
{
	NSAssert(aRegex != nil && [aRegex regex] != nil,
			 @"Cannot execute regular expression with invalid compiled regex.");

	regmatch_t match[128];
	memset(&match, 0, sizeof(regmatch_t));
	int err = regexec([aRegex regex], [self UTF8String], 128, match, 0);
	NSMutableArray *foundMatches = [NSMutableArray array];

	if(err == REG_NOMATCH) {
		return foundMatches;
	} else if(err) {
		size_t errBuffSize = 255;
		char errorBuffer[errBuffSize];
		size_t errorStringLen = regerror(err, [aRegex regex], errorBuffer, errBuffSize);
		NSString *regexError = [[NSString alloc] initWithBytes:errorBuffer length:errorStringLen-1 encoding: NSASCIIStringEncoding];
		[NSException raise:@"Regular Expression Error" format:regexError];
	}

	// otherwise, build up matches
	int i = 0;
	while(match[i].rm_so != -1) {
		NSString *thisMatch = [self substringWithRange:NSMakeRange(match[i].rm_so, match[i].rm_eo - match[i].rm_so)];
		[foundMatches addObject:thisMatch];
		i++;
	}

	return foundMatches;
}

@end

@implementation CompiledRegex

+(CompiledRegex *)compiledRegexWithString:(NSString *)aRegexExpression
{
	return [[[self alloc] initWithString:aRegexExpression] autorelease];
}

-(id)initWithString:(NSString *)aRegexExpression 
{
	if(![super init])
		return nil;
	
	compiledRegex = malloc(sizeof(regex_t));
	int err = regcomp(compiledRegex, [aRegexExpression UTF8String], REG_EXTENDED);

	if(err) {
		[self release];
		size_t errBuffSize = 255;
		char errorBuffer[errBuffSize];
		size_t errorStringLen = regerror(err, compiledRegex, errorBuffer, errBuffSize);
		NSString *regexError = [[NSString alloc] initWithBytes:errorBuffer length:errorStringLen-1 encoding: NSASCIIStringEncoding];
		[NSException raise:@"Regex Expression Exception" format:@"Failed to compile regex using expression: %@\n%@", aRegexExpression, regexError];
		return nil;
	}

	return self;
}

-(regex_t *)regex
{
	return compiledRegex;
}

-(void)dealloc
{
	regfree(compiledRegex);
	free(compiledRegex);

	[super dealloc];
}

@end