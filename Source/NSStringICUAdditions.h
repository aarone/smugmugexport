//
//  NSStringICUAdditions.h
//  CocoaICU
//
//  Created by Aaron Evans on 11/19/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ICUPattern;

@interface NSString (NSStringICUAdditions)

+(NSString *)stringWithUTF16String:(void *)utf16EncodedString;
-(void *)UTF16String;

-(NSArray *)findPattern:(NSString *)aRegex;
-(NSArray *)componentsSeparatedByPattern:(NSString *)aRegex;
-(NSString *)replaceOccurrencesOfPattern:(NSString *)aPattern withString:(NSString *)replacementText;
-(BOOL)matchesPattern:(NSString *)aRegex;
-(NSArray *)findPattern:(NSString *)aRegex;

@end
