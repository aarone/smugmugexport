//
//  RESTCall.m
//  SmugMugExport
//
//  Created by Aaron Evans on 12/30/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import "RESTCall.h"

NSString *UserAgent = @"iPhoto SmugMugExport";

@interface NSURLRequest (NSURLRequestSMAdditions)
+(NSURLRequest *)smRequestWithURL:(NSURL *)aUrl;
@end

@implementation NSURLRequest (NSURLRequestSMAdditions)
+(NSURLRequest *)smRequestWithURL:(NSURL *)aUrl {
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:aUrl];
	[req setValue:UserAgent forHTTPHeaderField:@"User-Agent"];
	return req;
}
@end

@interface NSString (NSStringURLAdditions)
-(NSString *)urlEscapedString;
@end

@implementation NSString (NSStringURLAdditions)
-(NSString *)urlEscapedString {
	NSString *escapedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																				  (CFStringRef)self,
																				  NULL,
																				  CFSTR("?=&+'"),
																				  kCFStringEncodingUTF8);
	return [escapedString autorelease];
}
@end

@interface NSURL (RESTURLAdditions)
-(NSURL *)URLByAppendingParameterListWithNames:(NSArray *)names values:(NSArray *)values;
@end

@implementation NSURL (RESTURLAdditions)
-(NSURL *)URLByAppendingParameterListWithNames:(NSArray *)names values:(NSArray *)values {
	NSMutableString *parameterList = [NSMutableString stringWithString:@"?"];

	int i;
	for(i=0;i<[names count];i++) {
		NSString *aKey = [names objectAtIndex:i];
		id aVal = [values objectAtIndex:i];
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

@interface RESTCall (Private)
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
-(void)setDocument:(NSXMLDocument *)d;
-(void)setErrror:(NSError *)err;
@end

@implementation RESTCall

-(id)init {
	if(![super init])
		return nil;
	
	[self setWasSuccessful:NO];

	return self;
}

+(RESTCall *)RESTCall {
	return [[[[self class] alloc] init] autorelease];
}

-(void)dealloc {
	[[self document] release];
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

-(NSXMLDocument *)document {
	return document;
}

-(void)setDocument:(NSXMLDocument *)d {
	if([self document] != nil)
		[[self document] release];
	
	document = [d retain];
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
	NSString *responseString = [[[NSString alloc] initWithData:[self response] encoding:NSUTF8StringEncoding] autorelease];
	NSError *err = nil;
	NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:responseString options:0 error:&err] autorelease];
	[self setDocument:doc];
	[self setWasSuccessful:YES];
	[self setError:nil];
	[[self target] performSelector:callback withObject:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)e {
	[self setWasSuccessful:NO];
	[self setError:e];
	[[self target] performSelector:callback withObject:self];
}

@end
