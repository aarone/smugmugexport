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

// from http://www.cocoadev.com/index.pl?NsUrlNotLoadingPages
+(NSData *)dataFromModGzUrl:(NSURL *)url {
	
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSTask  *gunzip;
    NSPipe  *compressedDataPipe, *uncompressedDataPipe;
    
	NSData *compressedData = [NSData dataWithContentsOfURL:url];
	unsigned char firstByte = 0;
	[compressedData getBytes:&firstByte length:1];
	if(firstByte != 0x1F) // not gzipped data
		return [NSData dataWithData:compressedData];
	
    gunzip = [[NSTask alloc] init];
    
    compressedDataPipe = [NSPipe pipe];
    uncompressedDataPipe = [NSPipe pipe];
    
    [gunzip setLaunchPath:@"/usr/bin/gunzip"];
    [gunzip setArguments:[NSArray arrayWithObject:@"-f"]];
    
    [gunzip setStandardInput:compressedDataPipe];
    [gunzip setStandardOutput:uncompressedDataPipe];
    
    [gunzip launch];
    
    NSFileHandle *writerHandle = [compressedDataPipe fileHandleForWriting];
    [writerHandle writeData:compressedData];
    
    [writerHandle closeFile];
    
    int maxToRead = (1024 * 1024);
    
    NSFileHandle    *readerFileHandle = [uncompressedDataPipe fileHandleForReading];
    NSMutableData   *uncompressedData = [NSMutableData data];
    
    do {
        NSData  *dataToRead;
        
        dataToRead = [readerFileHandle availableData];
        
        if (dataToRead && [dataToRead length]) {
            [uncompressedData appendData:dataToRead];
        } else {
            break;
        }
        
    } while ([uncompressedData length] < maxToRead);
    
    [gunzip terminate];
    [gunzip release];
    
    NSData *newData = [[NSData alloc] initWithData:uncompressedData];
    [pool release];
    [newData autorelease];
    if (!newData || ![newData length]) newData = compressedData;
    return newData;
}

@end
