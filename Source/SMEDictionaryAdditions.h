//
//  SMEDictionaryAdditions.h
//  SmugMugExport
//
//  Created by Aaron Evans on 7/13/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSMutableDictionary (SMEDictionaryAdditions)
-(void)setBool:(BOOL)v forKey:(id)key;
-(void)nilSafeSetObject:(id)obj forKey:(id)aKey;
@end
