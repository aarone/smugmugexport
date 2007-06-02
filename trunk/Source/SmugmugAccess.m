//
//  SmugmugAccess.m
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "SmugmugAccess.h"

#import "NSURLAdditions.h"
#import "NSURLRequestAdditions.h"

@interface SmugmugAccess (Private)
-(NSURLConnection *)connection;
-(void)setConnection:(NSURLConnection *)c;
-(NSMutableData *)response;
-(void)setResponse:(NSMutableData *)data;
-(void)appendToResponse:(NSData *)data;
-(void)setWasSuccessful:(BOOL)v;
-(SEL) callback;
-(void)setCallback:(SEL)c;
-(id)target;
-(void)setTarget:(id)t;
-(void)setErrror:(NSError *)err;
@end

@implementation SmugmugAccess

-(id)init {
	if(![super init])
		return nil;
	
	[self setWasSuccessful:NO];
	
	return self;
}

+(SmugmugAccess *)request {
	return [[[[self class] alloc] init] autorelease];
}

-(void)dealloc {
	[[self connection] release];
	[[self error] release];
	
	[super dealloc];
}

-(NSMutableData *)response {
	return response;
}

-(void)setResponse:(NSMutableData *)data {
	if([self response] != nil)
		[[self response] release];
	
	response = [data retain];
}

-(void)appendToResponse:(NSData *)data {
	[[self response] appendData:data];
}

-(NSURLConnection *)connection {
	return connection;
}

-(void)setConnection:(NSURLConnection *)c {
	if([self connection] != nil)
		[[self connection] release];
	
	connection = [c retain];
}

-(BOOL)wasSuccessful {
	return wasSuccessful;
}

-(void)setWasSuccessful:(BOOL)v {
	wasSuccessful = v;
}

-(SEL) callback {
	return callback;
}

-(void)setCallback:(SEL)c {
	callback = c;
}

-(id)target {
	return target;
}

-(void)setTarget:(id)t {
	target = t; // no retain, just like a delegate
}

-(NSError *)error {
	return error;
}

-(void)setError:(NSError *)e {
	if([self error] != nil)
		[[self error] release];
	
	error = [e retain];
}

-(void)invokeMethodWithUrl:(NSURL *)url {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSURLRequest *req = [NSURLRequest smRequestWithURL:url];
	[self setResponse:[NSMutableData data]];
	
	[self setConnection:[NSURLConnection connectionWithRequest:req delegate:self]]; // begin request
	
	while ( [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
									 beforeDate:[NSDate distantFuture]] );
	
	[pool release];
}

-(void)invokeMethod:(NSURL *)url responseCallback:(SEL)c responseTarget:(id)t {
	[self setCallback:c];
	[self setTarget:t];
	
	[NSThread detachNewThreadSelector:@selector(invokeMethodWithUrl:) toTarget:self withObject:url];
}

-(void)invokeMethodWithURL:(NSURL *)baseUrl keys:(NSArray *)keys values:(NSArray *)values responseCallback:(SEL)callbackSel responseTarget:(id)responseTarget {
	
	NSURL *uploadUrl = [baseUrl URLByAppendingParameterListWithNames:keys values:values];
	[self invokeMethod:uploadUrl responseCallback:callbackSel responseTarget:responseTarget];
}

-(void)invokeMethodWithURL:(NSURL *)baseURL keys:(NSArray *)keys valueDict:(NSDictionary *)keyValDict responseCallback:(SEL)callbackSel responseTarget:(id)responseTarget {
	
	NSMutableArray *values = [NSMutableArray array];
	NSEnumerator *keyEnumerator = [keys objectEnumerator];
	NSString *aKey;
	while(aKey = [keyEnumerator nextObject])
		[values addObject:[keyValDict objectForKey:aKey]];
	
	[self invokeMethodWithURL:baseURL keys:keys values:values responseCallback:callbackSel responseTarget:responseTarget];
}

#pragma mark NSURLConnection Delegate Methods
- (NSURLRequest *)connection:(NSURLConnection *)conn willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
	return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[[self response] setLength:0];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
	return nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self appendToResponse:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[self setWasSuccessful:YES];
	[self setError:nil];
	[[self target] performSelector:callback withObject:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)e {
	[self setWasSuccessful:NO];
	[self setError:e];
	[[self target] performSelector:callback withObject:self];
}

-(id)decodedResponse {
	return nil;
}

@end
