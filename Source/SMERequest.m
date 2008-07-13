//
//  SMERequest.m
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "SMERequest.h"

#import "SMEGlobals.h"
#import "SMEUserDefaultsAdditions.h"
#import "SMEDataAdditions.h"
#import "SMEURLAdditions.h"
#import "SMESession.h"

@interface SMERequest (Private)
-(NSURLConnection *)connection;
-(void)setConnection:(NSURLConnection *)c;

-(NSMutableData *)response;
-(void)setResponse:(NSMutableData *)data;

-(SEL)callback;
-(void)setCallback:(SEL)c;

-(id)target;
-(void)setTarget:(id)t;

-(void)setWasSuccessful:(BOOL)v;

-(BOOL)connectionIsOpen;
-(void)setConnectionIsOpen:(BOOL)v;

-(void)setErrror:(NSError *)err;

-(void)appendToResponse:(NSData *)data;

-(void)errorOccurred:(CFStreamError *)err;

@end

@interface NSURLRequest (NSURLRequestAdditions)
+(NSURLRequest *)smRequestWithURL:(NSURL *)aUrl;
@end


@implementation NSURLRequest (NSURLRequestAdditions)
+(NSURLRequest *)smRequestWithURL:(NSURL *)aUrl {
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:aUrl];
	[req setValue:[SMESession UserAgent] forHTTPHeaderField:@"User-Agent"];
	return req;
}
@end

@implementation SMERequest

-(id)init {
	if((self = [super init]) == nil)
		return nil;
	
	[self setWasSuccessful:NO];
	[self setConnectionIsOpen:NO];
	
	return self;
}

+(SMERequest *)request {
	return [[[[self class] alloc] init] autorelease];
}

-(void)dealloc {
	[[self connection] release];
	[[self error] release];
	[[self response] release];
	[[self requestUrl] release];
	[[self requestDict] release];
	[[self target] release];
	
	[super dealloc];
}

-(NSDictionary *)requestDict {
	return requestDict;
}

-(void)setRequestDict:(NSDictionary *)dict {
	if(requestDict != dict) {
		[requestDict release];	
		requestDict = [dict retain];
	}
}

-(NSURL *)requestUrl {
	return requestUrl;
}

-(void)setRequestUrl:(NSURL *)url {
	if(requestUrl != url) {
		[requestUrl release];	
		requestUrl = [url retain];
	}
}

-(NSMutableData *)response {
	return response;
}

-(void)setResponse:(NSMutableData *)data {
	if(response != data) {
		[response release];
		response = [data retain];	
	}
}

-(void)appendToResponse:(NSData *)data {
	[[self response] appendData:data];
}

-(NSURLConnection *)connection {
	return connection;
}

-(void)setConnection:(NSURLConnection *)c {
	if(connection != c) {
		[connection release];
		connection = [c retain];	
	}
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
	if(t != target) {
		[target release];
		target = [t retain];
	}
	
}

-(BOOL)connectionIsOpen {
	return connectionIsOpen;
}

-(void)setConnectionIsOpen:(BOOL)v {
	connectionIsOpen = v;
}

-(NSError *)error {
	return error;
}

-(void)setError:(NSError *)e {
	if(error != e) {
		[error release];
		error = [e retain];
	}
}

-(void)invokeMethodWithUrl:(NSURL *)url {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self setRequestUrl:url];
	if(IsNetworkTracingEnabled()) {
		NSLog(@"request: %@", [url absoluteString]);
	}
	
	NSURLRequest *req = [NSURLRequest smRequestWithURL:url];
	[self setResponse:[NSMutableData data]];
	
	[self setConnection:[NSURLConnection connectionWithRequest:req delegate:self]]; // begin request
	[self setConnectionIsOpen:YES];
	
	while ( [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
									 beforeDate:[NSDate distantFuture]] 
			&& [self connectionIsOpen]);
	
	[pool release];
}

-(void)invokeMethod:(NSURL *)url responseCallback:(SEL)c responseTarget:(id)t {
	[self setCallback:c];
	[self setTarget:t];
	[NSThread detachNewThreadSelector:@selector(invokeMethodWithUrl:) toTarget:self withObject:url];
}

-(void)invokeMethodWithURL:(NSURL *)baseUrl 
			   requestDict:(NSDictionary *)dict 
		  responseCallback:(SEL)callbackSel 
			responseTarget:(id)responseTarget {
	
	[self setRequestDict:dict];
	NSURL *uploadUrl = [baseUrl URLByAppendingParameterList:dict];
	[self invokeMethod:uploadUrl responseCallback:callbackSel responseTarget:responseTarget];
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
	[self setConnectionIsOpen:NO];
	
	if(IsNetworkTracingEnabled()) {
		NSString *responseAsString = [[[NSString alloc] initWithData:[self response]
															encoding:NSUTF8StringEncoding] autorelease];
		NSLog(@"response: %@", responseAsString);
	}	
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)e {
	[self setWasSuccessful:NO];
	[self setError:e];
	[[self target] performSelector:callback withObject:self];
	[self setConnectionIsOpen:NO];
}

-(NSData *)data {
	return [NSData dataWithData:response];
}

@end
