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
+(NSString *)UserAgent;
-(void)appendToResponse;
-(void)transferComplete;
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
-(NSString *)cleanKeywords:(NSArray *)keywords;
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

NSString *SMUploadKeyImageData = @"SMImageData";
NSString *SMUploadKeyFilename = @"SMFilename";
NSString *SMUploadKeySessionId = @"SMESessionId";
NSString *SMUploadKeyCaption = @"SMCaption";
NSString *SMUploadKeyKeywords = @"SMKeywords";
NSString *SMUploadKeyAlbumRef = @"SMAlbumRef";
NSString *SMUploadKeyObserver = @"SMUploadKeyObserver";

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

-(id)init {
	if((self = [super init]) == nil)
		return nil;
	
	[self setWasSuccessful:NO];
	[self setConnectionIsOpen:NO];
	
	return self;
}

+(SMRequest *)request {
	return [[[[self class] alloc] init] autorelease];
}

+(NSString *)UserAgent {
	return [[[NSString alloc] initWithFormat:@"iPhoto SMExportPlugin/%@", [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:(NSString *)kCFBundleShortVersionStringKey]] autorelease];
}

-(void)dealloc {
	[[self connection] release];
	[[self error] release];
	[[self imageData] release];
	[[self response] release];
	[[self requestUrl] release];
	[[self requestDict] release];
	[[self target] release];
	
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

-(NSString *)postUploadURL:(NSString *)filename {
	return @"http://upload.smugmug.com/photos/xmlrawadd.mg";
}

-(NSObject<SMUploadRequestObserver> *)observer {
	return observer;
}

-(void)setObserver:(NSObject<SMUploadRequestObserver> *)anObserver {
	observer = anObserver;
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
		CFReadStreamUnscheduleFromRunLoop(readStream, uploadRunLoop, kCFRunLoopCommonModes);
		CFReadStreamClose(readStream);
		CFRelease(readStream);
		readStream = NULL;
	}
	
	if(uploadRunLoop != NULL) {
	   CFRunLoopStop(uploadRunLoop);
	   uploadRunLoop = NULL;
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

-(void)updateProgress:(NSArray *)args {
	[[self observer] uploadMadeProgress:self bytesWritten:[[args objectAtIndex:0] intValue]
						   ofTotalBytes:[[args objectAtIndex: 1] intValue]];										 
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

-(NSString *)errorDescriptionForError:(CFStreamError *)err {

	if(err->domain == kCFStreamErrorDomainPOSIX) {
		return [NSString stringWithFormat:@"%d : %s", err->error, strerror(err->error)];
	} else if (err->domain == kCFStreamErrorDomainMacOSStatus) {
		return [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"Mac Error", @"Mac Error"), err->error ];
	} else if (err->domain == kCFStreamErrorDomainNetDB) {
		return [NSString stringWithFormat:@"%d: %s", err->error, hstrerror(err->error)];
	} else if (err->domain == kCFStreamErrorDomainMach) {
		return [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"Mach Error", @"Mach Error"), err->error ];
	} else if (err->domain == kCFStreamErrorDomainHTTP) {
		return [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"HTTP Error", @"HTTP Error"), err->error ];
	}  else if (err->domain == kCFStreamErrorDomainSOCKS) {
		return [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"SOCKS Error", @"SOCKS Error"), err->error ];
	} else if (err->domain == kCFStreamErrorDomainSystemConfiguration) {
		return [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"System Configuration error", @"System Configuration error"), err->error ];
	} else if (err->domain == kCFStreamErrorDomainSSL) {
		return [NSString stringWithFormat:@"%@ %d", NSLocalizedString(@"SSL error", @"SSL error"), err->error ];
	} else {
		return [NSString stringWithFormat:@"%d", err->error];
	}
		
}

-(void)reportError:(NSString *)err {
	[[self observer] uploadFailed:self withError:err];
}

-(void)errorOccurred: (CFStreamError *)err {
	NSString *errorText = [self errorDescriptionForError:err];
	
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

-(NSString *)cleanKeywords:(NSArray *)keywords {
	return [NSString stringWithFormat:@"\"%@\"", [keywords componentsJoinedByString:@"\" \""]];
}

-(void)uploadImageData:(NSData *)theImageData
			  filename:(NSString *)filename
			 sessionId:(NSString *)sessionId
				 album:(SMAlbumRef *)albumRef
			   caption:(NSString *)caption
			  keywords:(NSArray *)keywords
			  observer:(NSObject<SMUploadRequestObserver> *)anObserver {
	NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
								 theImageData, SMUploadKeyImageData,
								 filename, SMUploadKeyFilename,
								 sessionId, SMUploadKeySessionId,
								 albumRef, SMUploadKeyAlbumRef,
								 caption, SMUploadKeyCaption,
								 keywords, SMUploadKeyKeywords,
								 anObserver, SMUploadKeyObserver, 
						  nil];
	[self setRequestDict:args];
	[NSThread detachNewThreadSelector:@selector(startImageUpload:) 
							 toTarget:self 
						   withObject:args];
}

-(void)startImageUpload:(NSDictionary *)args {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSData *theImageData = [args objectForKey:SMUploadKeyImageData];
	NSString *filename = [args objectForKey:SMUploadKeyFilename];
	NSString *sessionId = [args objectForKey:SMUploadKeySessionId];
	SMAlbumRef *albumRef = [args objectForKey: SMUploadKeyAlbumRef];
	NSString *caption = [args objectForKey:SMUploadKeyCaption];
	NSArray *keywords = [args objectForKey:SMUploadKeyKeywords];
	NSObject<SMUploadRequestObserver> *anObserver = [args objectForKey:SMUploadKeyObserver];

	[self setObserver:anObserver];
	[self setImageData:theImageData];
	
	if(IsNetworkTracingEnabled()) {
		NSLog(@"Posting image to %@", [self postUploadURL:filename]);
	}
	
	[self setRequestUrl:[NSURL URLWithString:[self postUploadURL:filename]]];
	CFHTTPMessageRef myRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("POST"), (CFURLRef)[self requestUrl], kCFHTTPVersion1_1);
	
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("User-Agent"), (CFStringRef)[SMRequest UserAgent]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("Content-Length"), (CFStringRef)[NSString stringWithFormat:@"%d", [theImageData length]]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("Content-MD5"), (CFStringRef)[theImageData md5HexString]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-SessionID"), (CFStringRef)sessionId);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-Version"), (CFStringRef)[self uploadApiVersion]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-ResponseType"), (CFStringRef)[self uploadResponseType]);	
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-FileName"), (CFStringRef)[self cleanNewlines:filename]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-AlbumID"), (CFStringRef)[albumRef albumId]);
	
	if(!IsEmpty(caption))
		CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-Caption"), (CFStringRef)[self cleanNewlines:caption]);
	
	if(!IsEmpty(keywords))
		CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-Keywords"), (CFStringRef)[self cleanKeywords:keywords]);
	
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
	uploadRunLoop = CFRunLoopGetCurrent();
	[self setIsUploading:YES];
	[self setResponse:[NSMutableData data]];
	
	CFReadStreamOpen(readStream);
	
	[NSThread detachNewThreadSelector:@selector(beingUploadProgressTracking) toTarget:self withObject:nil];

	// CFRunLoop is not toll-free bridges to NSRunLoop
	while ([self isUploading])
		CFRunLoopRun();
	
	[pool release];
}

-(NSData *)data {
	return [NSData dataWithData:response];
}

@end
