//
//  NSScanner_Extensions.h
//  CocoaJSON
//
//  Created by Jonathan Wight on 12/08/2005.
//  Copyright 2005 Toxic Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSScanner (NSScanner_Extensions)

- (unichar)currentCharacter;
- (unichar)scanCharacter;
- (void)skipWhitespace;
- (BOOL)scanCharacter:(unichar)inCharacter;
- (void)backtrack:(unsigned)inCount;

- (BOOL)scanCStyleComment:(NSString **)outComment;
- (BOOL)scanCPlusPlusStyleComment:(NSString **)outComment;

@end
