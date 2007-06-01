//
//  NSURLRequestAdditions.m
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "NSURLRequestAdditions.h"
#import "Globals.h"

@implementation NSURLRequest (NSURLRequestAdditions)

+(NSURLRequest *)smRequestWithURL:(NSURL *)aUrl {
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:aUrl];
	[req setValue:UserAgent forHTTPHeaderField:@"User-Agent"];
	return req;
}

@end
