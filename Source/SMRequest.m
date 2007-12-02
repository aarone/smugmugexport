//
//  SMRequest.m
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "SMRequest.h"

#import "NSURLAdditions.h"
#import "SMGlobals.h"
#import "NSUserDefaultsAdditions.h"
#import "SMDecoder.h"
#import "NSDataAdditions.h"
#import "SMUploadObserver.h"

@interface SMRequest (Private)
-(NSURLConnection *)connection;
-(void)setConnection:(NSURLConnection *)c;
-(NSMutableData *)response;
-(void)setResponse:(NSMutableData *)data;
-(void)appendToResponse:(NSData *)data;
-(void)setWasSuccessful:(BOOL)v;
-(SEL)callback;
-(void)setCallback:(SEL)c;
-(id)target;
-(void)setTarget:(id)t;
-(void)setErrror:(NSError *)err;
-(NSObject<SMDecoder> *)decoder;
-(void)setDecoder:(NSObject<SMDecoder> *)aDecoder;
+(NSString *)UserAgent;
-(void)appendToResponse;
-(void)transferComplete;
-(NSString *)domainStringForError:(CFStreamError *)err;
-(void)errorOccurred:(CFStreamError *)err;
-(NSString *)appName;
-(NSString *)userID;
-(BOOL)isUploading;
-(void)setIsUploading:(BOOL)v;
-(void)setImageData:(NSData *)imgData;
-(NSString *)uploadApiVersion;
-(NSString *)uploadResponseType;
-(NSData *)imageData;
-(BOOL)connectionIsOpen;
-(void)setConnectionIsOpen:(BOOL)v;
-(void)destroyUploadResources;
@end

@interface NSURLRequest (NSURLRequestAdditions)
+(NSURLRequest *)smRequestWithURL:(NSURL *)aUrl;
@end


@implementation NSURLRequest (NSURLRequestAdditions)
+(NSURLRequest *)smRequestWithURL:(NSURL *)aUrl {
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:aUrl];
	[req setValue:[SMRequest UserAgent] forHTTPHeaderField:@"User-Agent"];
	return req;
}
@end

double UploadProgressTimerInterval = 0.125/2.0;

static const CFOptionFlags DAClientNetworkEvents = 
kCFStreamEventOpenCompleted     |
kCFStreamEventHasBytesAvailable |
kCFStreamEventEndEncountered    |
kCFStreamEventErrorOccurred;

static void ReadStreamClientCallBack(CFReadStreamRef stream, CFStreamEventType type, void *clientCallBackInfo) {
	switch (type) {
		case kCFStreamEventHasBytesAvailable:
			[(SMRequest *)clientCallBackInfo appendToResponse];
			break;			
		case kCFStreamEventEndEncountered:
			[(SMRequest *)clientCallBackInfo transferComplete];
			break;
		case kCFStreamEventErrorOccurred: {
			CFStreamError err = CFReadStreamGetError(stream);
			[(SMRequest *)clientCallBackInfo errorOccurred:&err];
			break;
		} default:
			break;
	}
}

@implementation SMRequest

-(id)initWithDecoder:(NSObject<SMDecoder> *)aDecoder {
	if(![super init])
		return nil;
	
	[self setDecoder:aDecoder];
	[self setWasSuccessful:NO];
	[self setConnectionIsOpen:NO];
	
	return self;
}

+(SMRequest *)SMRequest:(NSObject<SMDecoder> *)aDecoder {
	return [[[[self class] alloc] initWithDecoder:aDecoder] autorelease];
}

+(NSString *)UserAgent {
	return [[NSString alloc] initWithFormat:@"iPhoto SMExportPlugin/%@", [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"]];
}

-(void)dealloc {
	[[self connection] release];
	[[self error] release];
	[[self decoder] release];
	[[self imageData] release];
	[[self response] release];
	[[self requestUrl] release];
	[[self requestDict] release];
	
	[super dealloc];
}

-(NSString *)appName {
	return @"SMExportPlugin";
}

-(NSString *)uploadApiVersion {
	return @"1.2.0";
}

-(NSString *)uploadResponseType {
	return @"JSON";
}

-(NSString *)postUploadURL:(NSString *)filename  {
	return @"http://upload.smugmug.com/photos/xmlrawadd.mg";
}

-(NSObject<SMDecoder> *)decoder {
	return decoder;
}

-(NSObject<SMUploadObserver> *)observer {
	return observer;
}

-(void)setObserver:(NSObject<SMUploadObserver> *)anObserver {
	observer = anObserver;
}

-(void)setDecoder:(NSObject<SMDecoder> *)aDecoder {
	if([self decoder] != nil)
		[[self decoder] release];
	
	decoder = [aDecoder retain];
}

-(NSDictionary *)requestDict {
	return requestDict;
}

-(void)setRequestDict:(NSDictionary *)dict {
	if([self requestDict] != nil)
		[[self requestDict] release];
	
	requestDict = [dict retain];
}

-(NSURL *)requestUrl {
	return requestUrl;
}

-(void)setRequestUrl:(NSURL *)url {
	if([self requestUrl] != nil) 
		[[self requestUrl] release];
	
	requestUrl = [url retain];
}

-(BOOL)isUploading {
	return isUploading;
}

-(void)setIsUploading:(BOOL)v {
	isUploading = v;
}

-(NSMutableData *)response {
	return response;
}

-(void)setImageData:(NSData *)data {
	if([self imageData] != nil)
		[[self imageData] release];
	
	imageData = [data retain];
}

-(NSData *)imageData {
	return imageData;
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
	if([self error] != nil)
		[[self error] release];
	
	error = [e retain];
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

-(void)invokeMethodWithURL:(NSURL *)baseUrl keys:(NSArray *)keys values:(NSArray *)values responseCallback:(SEL)callbackSel responseTarget:(id)responseTarget {
	
	[self setRequestDict:[NSDictionary dictionaryWithObjects:values	forKeys:keys]];
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
	[self setConnectionIsOpen:NO];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)e {
	[self setWasSuccessful:NO];
	[self setError:e];
	[[self target] performSelector:callback withObject:self];
	[self setConnectionIsOpen:NO];
}

-(NSDictionary *)decodedResponse {	
	if(IsNetworkTracingEnabled()) {
		NSString *responseAsString = [[[NSString alloc] initWithData:[self response] 
															encoding:NSUTF8StringEncoding] autorelease];
		NSLog(@"response: %@", responseAsString);
	}
	
	return [[self decoder] decodedResponse:[self response]];
}

#pragma mark Upload Methods
-(void)cancelUpload {
	[self setIsUploading:NO];
	[[self observer] uploadCanceled:self];
	[self destroyUploadResources];
}

-(void)appendToResponse {
	
	UInt8 buffer[4096];
	
	if(![self isUploading])
		return;
	
	CFIndex bytesRead = CFReadStreamRead(readStream, buffer, sizeof(buffer));
	
	if (bytesRead < 0)
		NSLog(@"Warning: Error (< 0b from CFReadStreamRead");
	else
		[[self response] appendBytes:(void *)buffer length:(unsigned)bytesRead];
}

-(void)destroyUploadResources {
	[self setIsUploading:NO];
	
	if(readStream != NULL) {
		CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
		CFReadStreamClose(readStream);
		CFRelease(readStream);
		readStream = NULL;
	}
	
	[self setResponse:nil];
}

-(void)beingUploadProgressTracking {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSTimer *uploadProgressTimer  = [NSTimer timerWithTimeInterval:UploadProgressTimerInterval target:self selector:@selector(trackUploadProgress:) userInfo:nil repeats:YES];
	
	[[NSRunLoop currentRunLoop] addTimer:uploadProgressTimer forMode:NSModalPanelRunLoopMode];
	
	while ( [[NSRunLoop currentRunLoop] runMode:NSModalPanelRunLoopMode
									 beforeDate:[NSDate distantFuture]] &&
			[self isUploading]);
	
	[pool release];
}

-(void)trackUploadProgress:(NSTimer *)timer {
	
	if(![self isUploading] || readStream == NULL) {
		[timer invalidate];
		return;
	}
	
	CFNumberRef bytesWrittenProperty = (CFNumberRef)CFReadStreamCopyProperty (readStream, kCFStreamPropertyHTTPRequestBytesWrittenCount); 
	
	int bytesWritten;
	CFNumberGetValue (bytesWrittenProperty, 3, &bytesWritten);
	CFRelease(bytesWrittenProperty);
	
	[[self observer] uploadMadeProgress:self bytesWritten:bytesWritten ofTotalBytes:[[self imageData] length]];

	if(bytesWritten >= [[self imageData] length])
		[timer invalidate];
}

-(void)transferComplete {
	[[self observer] uploadSucceeded:self];
	[self destroyUploadResources];
}

-(NSString *)domainStringForError:(CFStreamError *)err {
	
	if (err->domain == kCFStreamErrorDomainCustom) {
		return NSLocalizedString(@"Custom error", @"Custom error");
	} else if (err->domain == kCFStreamErrorDomainPOSIX) {
		return NSLocalizedString(@"POSIX error", @"POSIX error");
	} else if (err->domain == kCFStreamErrorDomainMacOSStatus) {
		return [NSString stringWithFormat:@"OS error" @"OS error"];
	} else if (err->domain == kCFStreamErrorDomainNetDB) {
		return NSLocalizedString(@"NetDB error", @"NetDB error");
	} else if (err->domain == kCFStreamErrorDomainMach) {
		return NSLocalizedString(@"Mach error", @"Mach error");
	} else if (err->domain == kCFStreamErrorDomainHTTP) {
		return NSLocalizedString(@"HTTP error", @"HTTP error");
	}  else if (err->domain == kCFStreamErrorDomainSOCKS) {
		return NSLocalizedString(@"SOCKS error", @"SOCKS error");
	} else if (err->domain == kCFStreamErrorDomainSystemConfiguration) {
		return NSLocalizedString(@"System Configuration error", @"System Configuration error");
	} else if (err->domain == kCFStreamErrorDomainSSL) {
		return NSLocalizedString(@"System Configuration error", @"System Configuration error");
	}
	
	return NSLocalizedString(@"Unknown domain", @"Default stream error domain.");
}

-(NSString *)errorDescriptionForError:(CFStreamError *)err {

	if(err->domain == kCFStreamErrorDomainPOSIX) {
		return [NSString stringWithFormat:@"%d : %s", err->error, strerror(err->error)];
	} else {
		return [NSString stringWithFormat:@"%d", err->error];
	}
		
}

-(NSString *)errorTextForError:(CFStreamError *)err {
	NSString *domain = [self domainStringForError:err];
	NSString *desc = [self errorDescriptionForError:err];
	return [NSString stringWithFormat:@"%@ : %@", domain, desc];
}

-(void)errorOccurred: (CFStreamError *)err {
	NSString *errorText = [self errorTextForError:err];// domainStringForError:err errorNumber:err->error];

	[[self observer] uploadFailed:self withError:errorText];
	[self destroyUploadResources];
}

-(NSString *)imageHeadersForRequest:(CFHTTPMessageRef *)myRequest {
	NSDictionary *headers = (NSDictionary *)CFHTTPMessageCopyAllHeaderFields(*myRequest);
	NSEnumerator *enumerator = [headers keyEnumerator];
	NSMutableString *result = [NSMutableString string];
	NSString *key;
	while(key = [enumerator nextObject])
		[result appendFormat:@"%@: %@\n", key, [headers objectForKey:key]];
		
	[headers release];
	return result;
}

-(NSString *)cleanNewlines:(NSString *)aString {
	// adding a newline to a header will cause the sent request to be invalid.
	// use carriage returns instead of newlines.
	NSMutableString *cleanedString = [NSMutableString stringWithString:aString];
	[cleanedString replaceOccurrencesOfString:@"\n"
								   withString:@"\r"
									  options:nil
										range:NSMakeRange(0, [cleanedString length])];
	return [NSString stringWithString:cleanedString];
}

-(void)uploadImageData:(NSData *)theImageData
			  filename:(NSString *)filename
			 sessionId:(NSString *)sessionId
			   albumID:(NSString *)albumId 
			   caption:(NSString *)caption
			  keywords:(NSArray *)keywords
			  observer:(NSObject<SMUploadObserver> *)anObserver {

	[self setObserver:anObserver];
	[self setImageData:theImageData];
	
	if(IsNetworkTracingEnabled()) {
		NSLog(@"Posting image to %@", [self postUploadURL:filename]);
	}
	
	CFHTTPMessageRef myRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("POST"), (CFURLRef)[NSURL URLWithString:[self postUploadURL:filename]], kCFHTTPVersion1_1);
	
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("User-Agent"), (CFStringRef)[SMRequest UserAgent]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("Content-Length"), (CFStringRef)[NSString stringWithFormat:@"%d", [theImageData length]]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("Content-MD5"), (CFStringRef)[theImageData md5HexString]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-SessionID"), (CFStringRef)sessionId);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-Version"), (CFStringRef)[self uploadApiVersion]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-ResponseType"), (CFStringRef)[self uploadResponseType]);	
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-FileName"), (CFStringRef)[self cleanNewlines:filename]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-AlbumID"), (CFStringRef)albumId);
	
	if(!IsEmpty(caption))
		CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-Caption"), (CFStringRef)[self cleanNewlines:caption]);
	
	if(!IsEmpty(keywords))
		CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-Keywords"), (CFStringRef)[self cleanNewlines:[keywords componentsJoinedByString:@" "]]);
	
	if(IsNetworkTracingEnabled()) {
		NSLog(@"Image headers: %@", [self imageHeadersForRequest:&myRequest]);
	}
	
	CFHTTPMessageSetBody(myRequest, (CFDataRef)theImageData);
	
	readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, myRequest);
	CFRelease(myRequest);
	
	CFStreamClientContext ctxt = {0, self, NULL, NULL, NULL};
	if (!CFReadStreamSetClient(readStream, DAClientNetworkEvents, ReadStreamClientCallBack, &ctxt)) {
		CFRelease(readStream);
		readStream = NULL;
		NSLog(@"CFReadStreamSetClient returned null on start of upload");
		return;
	}
	
	CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	
	[self setIsUploading:YES];
	[self setResponse:[NSMutableData data]];
	
	CFReadStreamOpen(readStream);
	
	[NSThread detachNewThreadSelector:@selector(beingUploadProgressTracking) toTarget:self withObject:nil];
}

@end
