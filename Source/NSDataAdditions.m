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

-(NSString *)md5HexString {
	NSData *hashData = [self md5Hash];
	unsigned char *hashBytes = (unsigned char *)[hashData bytes];
	NSMutableString *hexString = [NSMutableString string];
	int i;
	for(i=0;i<[hashData length];i++)
		[hexString appendFormat:@"%02x", hashBytes[i]];
	
	return [NSString stringWithString:hexString];
}

-(NSData *)md5Hash {
	unsigned char digest[16];

	MD5([self bytes],[self length],digest);
	return [NSData dataWithBytes:&digest length:16];
}

@end
