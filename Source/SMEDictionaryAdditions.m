//
//  SMEDictionaryAdditions.m
//  SmugMugExport
//
//  Created by Aaron Evans on 7/13/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMEDictionaryAdditions.h"


@implementation NSMutableDictionary (SMEDictionaryAdditions)

-(void)setBool:(BOOL)v forKey:(id)key {
	[self setObject:[NSNumber numberWithBool:v] forKey:key];
}

-(void)nilSafeSetObject:(id)obj forKey:(id)aKey {
	if(obj == nil)
		[self removeObjectForKey:aKey];
	else
		[self setObject:obj forKey:aKey];
}

@end
