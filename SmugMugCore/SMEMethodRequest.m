//
//  SMERequest.m
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//


#import "SMESmugMugCore.h"

@interface NSString (SMEDataAdditions)
-(NSString *)urlEscapedString;
@end


@implementation NSString (SMEDataAdditions)

-(NSString *)urlEscapedString {
	NSString *escapedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																				  (CFStringRef)self,
																				  NULL,
																				  CFSTR("?=&+'"),
																				  kCFStringEncodingUTF8);
	return [escapedString autorelease];	
}

@end


@interface NSURL (SMEDataAdditions)
-(NSURL *)URLByAppendingParameterList:(NSDictionary *)params;
@end

@implementation NSURL (SMEDataAdditions)

-(NSURL *)URLByAppendingParameterList:(NSDictionary *)params {
	NSMutableString *parameterList = [NSMutableString stringWithString:@"?"];
	
	int i;
	NSArray *names = [params allKeys];
	for(i=0;i<[names count];i++) {
		NSString *aKey = [names objectAtIndex:i];
		id aVal = [params objectForKey:aKey];
		if([aVal isKindOfClass:[NSString class]])
			[parameterList appendFormat:@"%@=%@", aKey, [(NSString *)aVal urlEscapedString]];
		else if([aVal respondsToSelector:@selector(stringValue)])
			[parameterList appendFormat:@"%@=%@", aKey, [[(NSNumber *)aVal stringValue] urlEscapedString]];
		else 
			[parameterList appendFormat:@"%@=%@", aKey, aVal];
		
		if(i<[names count]-1)
			[parameterList appendString:@"&"];
	}
	
	NSMutableString *newUrl = [NSMutableString stringWithString:[self absoluteString]];
	if(![newUrl hasSuffix:@"/"])
		[newUrl appendString:@"/"];
	
	[newUrl appendString:parameterList];
	return [NSURL URLWithString:newUrl];
}
@end



@interface SMEMethodRequest (Private)
-(NSURLConnection *)connection;
-(void)setConnection:(NSURLConnection *)c;

-(NSMutableData *)mutableResponseData;
-(void)setMutableResponseData:(NSMutableData *)data;

-(SEL)callback;
-(void)setCallback:(SEL)c;

-(id)target;
-(void)setTarget:(id)t;

-(NSHTTPURLResponse *)httpResponse;
-(void)setHttpResponse:(NSHTTPURLResponse *)resp;

-(void)setWasSuccessful:(BOOL)v;

-(BOOL)connectionIsOpen;
-(void)setConnectionIsOpen:(BOOL)v;

-(void)setErrror:(NSError *)err;

-(void)appendToResponse:(NSData *)data;

-(void)errorOccurred:(CFStreamError *)err;

-(BOOL)isTracingEnabled;
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

@implementation SMEMethodRequest

-(id)init {
	if((self = [super init]) == nil)
		return nil;
	
	[self setWasSuccessful:NO];
	[self setConnectionIsOpen:NO];
	
	return self;
}

+(SMEMethodRequest *)request {
	return [[[[self class] alloc] init] autorelease];
}

-(void)dealloc {
	[[self httpResponse] release];
	[[self connection] release];
	[[self error] release];
	[[self mutableResponseData] release];
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

-(NSMutableData *)mutableResponseData {
	return mutableResponseData;
}

-(void)setMutableResponseData:(NSMutableData *)data {
	if(mutableResponseData != data) {
		[mutableResponseData release];
		mutableResponseData = [data retain];	
	}
}

-(void)appendToResponse:(NSData *)data {
	[[self mutableResponseData] appendData:data];
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

-(NSHTTPURLResponse *)httpResponse {
	return httpResponse;
}

-(void)setHttpResponse:(NSHTTPURLResponse *)resp {
	if(resp != httpResponse) {
		[httpResponse release];
		httpResponse = [resp retain];
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
	if([self isTracingEnabled]) {
		NSLog(@"request: %@", [url absoluteString]);
	}
	
	NSURLRequest *req = [NSURLRequest smRequestWithURL:url];
	[self setMutableResponseData:[NSMutableData data]];
	[self setError:nil];
	[self setWasSuccessful:NO];
	
	[self setConnection:[NSURLConnection connectionWithRequest:req delegate:self]]; // begin request
	[self setConnectionIsOpen:YES];
	
	NSRunLoop *rl = [NSRunLoop currentRunLoop];
	while ( [rl runMode:NSDefaultRunLoopMode
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
-(NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
	return request;  // allow any redirects
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)aResponse {
	[[self mutableResponseData] setLength:0]; // reset
	[self setHttpResponse:(NSHTTPURLResponse *)aResponse];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
	return nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self appendToResponse:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if([[self httpResponse] statusCode] == 200) { // can we just expect 200?
		[self setWasSuccessful:YES];
		[self setError:nil];
	} else {
		[self setWasSuccessful:NO];
		[self setError:[NSError errorWithDomain:NSLocalizedString(@"HTTP Error", @"HTTP error domain")
										   code:[[self httpResponse] statusCode]
									   userInfo:[NSDictionary dictionaryWithObject:[NSHTTPURLResponse localizedStringForStatusCode:[[self httpResponse] statusCode]] forKey:NSLocalizedDescriptionKey]]];
	}
	
	if([self isTracingEnabled]) {
		NSString *responseAsString = [[[NSString alloc] initWithData:[self mutableResponseData]
															encoding:NSUTF8StringEncoding] autorelease];
		NSLog(@"response: %@", responseAsString);
	}
	
	[[self target] performSelector:callback withObject:self];
	[self setConnectionIsOpen:NO];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)e {
	if([self isTracingEnabled]) {
		NSLog(@"An error occurred : %@", [e localizedDescription]);
	}
	
	[self setWasSuccessful:NO];
	[self setError:e];
	[[self target] performSelector:callback withObject:self];
	[self setConnectionIsOpen:NO];
}

-(NSData *)responseData {
	return [NSData dataWithData:[self mutableResponseData]];
}

-(void)setIsTracingEnabled:(BOOL)v {
	isTracingEnabled = v;
}

-(BOOL)isTracingEnabled {
	return isTracingEnabled;
}


@end
