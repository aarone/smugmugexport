//
//  NSStringAdditions.h
//  SmugMugExport
//
//  Created by Aaron Evans on 11/18/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <regex.h>
@class CompiledRegex;

@interface NSString (NSStringAdditions)

-(BOOL)matchesRegularExpression:(CompiledRegex *)aRegex;
-(NSArray *)findUsingRegularExpression:(CompiledRegex *)aRegex replaceWith:(NSString *)replacementString;

@end


@interface CompiledRegex : NSObject {
	regex_t *compiledRegex;
}

+(CompiledRegex *)compiledRegexWithString:(NSString *)aRegexExpression;
-(id)initWithString:(NSString *)aRegexExpression;
-(regex_t *)regex;

@end