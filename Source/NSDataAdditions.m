//
//  NSDataAdditions.m
//  SmugMugExport
//
//  Created by Aaron Evans on 10/11/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import "NSDataAdditions.h"
#include <openssl/md5.h>

@implementation NSData (NSDataAdditions)

-(NSData *)md5Hash
{
	NSMutableData *digest = [NSMutableData dataWithLength:MD5_DIGEST_LENGTH];
	if (digest && MD5([self bytes], [self length], [digest mutableBytes]))
		return [NSData dataWithData:digest];
	
	return nil;
}

@end
