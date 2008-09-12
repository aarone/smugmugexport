//
//  SMEUploadRequest.m
//  SmugMugExport
//
//  Created by Aaron Evans on 7/13/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMEUploadRequest.h"
#import "SMEImage.h"
#import "SMESession.h"
#import "SMEDataAdditions.h"
#import "SMEAlbumRef.h"
#import "SMEGlobals.h"
#import "SMEUserDefaultsAdditions.h"
#import "SMESession.h"

@interface SMEUploadRequest (Private)

-(void)startImageUpload;

-(BOOL)isUploading;
-(void)setIsUploading:(BOOL)v;

-(void)setObserver:(NSObject<SMEUploadRequestObserver> *)anObserver;
-(NSObject<SMEUploadRequestObserver> *)observer;

-(void)setWasSuccessful:(BOOL)v;
-(void)setError:(NSError *)err;

-(void)setSession:(SMESession *)anId;
-(void)setAlbumRef:(SMEAlbumRef *)ref;
-(void)setImage:(SMEImage *)anImage;


-(NSMutableData *)response;
-(void)setResponse:(NSMutableData *)data;

-(void)appendToResponse;

-(void)transferComplete;
-(void)errorOccurred:(CFStreamError *)err;

-(NSString *)uploadApiVersion;
-(NSString *)uploadResponseType;

-(void)destroyUploadResources;
-(NSString *)cleanKeywords:(NSArray *)keywords;
@end

static double SMEUploadProgressTimerInterval = 0.125/2.0;

static const CFOptionFlags DAClientNetworkEvents = 
										kCFStreamEventOpenCompleted     |
										kCFStreamEventHasBytesAvailable |
										kCFStreamEventEndEncountered    |
										kCFStreamEventErrorOccurred;

static void ReadStreamClientCallBack(CFReadStreamRef stream, CFStreamEventType type, void *clientCallBackInfo) {
	switch (type) {
		case kCFStreamEventHasBytesAvailable:
			[(SMEUploadRequest *)clientCallBackInfo appendToResponse];
			break;			
		case kCFStreamEventEndEncountered:
			[(SMEUploadRequest *)clientCallBackInfo transferComplete];
			break;
		case kCFStreamEventErrorOccurred: {
			CFStreamError err = CFReadStreamGetError(stream);
			[(SMEUploadRequest *)clientCallBackInfo errorOccurred:&err];
			break;
		} default:
			break;
	}
}


@implementation SMEUploadRequest

+(SMEUploadRequest *)uploadRequest {
	return [[[[self class] alloc] init] autorelease];
}

-(void)dealloc {
	[self setImage:nil];
	[self setResponse:nil];
	[self setError:nil];
	
	[super dealloc];
}

-(void)setObserver:(NSObject<SMEUploadRequestObserver> *)anObserver {
	observer = anObserver;
}

-(NSObject<SMEUploadRequestObserver> *)observer {
	return observer;
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

-(NSString *)cleanKeywords:(NSArray *)theKeywords {
	return [NSString stringWithFormat:@"\"%@\"", [theKeywords componentsJoinedByString:@"\" \""]];
}

-(void)uploadImage:(SMEImage *)theImage
	   withSession:(SMESession *)theSession
		 intoAlbum:(SMEAlbumRef *)anAlbumRef
		  observer:(NSObject<SMEUploadRequestObserver> *)anObserver {
	
	[self setImage:theImage];
	[self setSession:theSession];
	[self setAlbumRef:anAlbumRef];
	[self setObserver:anObserver];	
	[NSThread detachNewThreadSelector:@selector(startImageUpload) 
							 toTarget:self 
						   withObject:nil];
}

-(void)startImageUpload {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
	if(IsNetworkTracingEnabled()) {
		NSLog(@"Posting image to %@", [self postUploadURL:[[self image] title]]);
	}
	
	NSURL *requestUrl = [NSURL URLWithString:[self postUploadURL:[[self image] title]]];
	CFHTTPMessageRef myRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("POST"), (CFURLRef)requestUrl, kCFHTTPVersion1_1);
	
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("User-Agent"), (CFStringRef)[SMESession UserAgent]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("Content-Length"), (CFStringRef)[NSString stringWithFormat:@"%d", [[[self image] imageData] length]]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("Content-MD5"), (CFStringRef)[[[self image] imageData] md5HexString]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-SessionID"), (CFStringRef)[[self session] sessionID]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-Version"), (CFStringRef)[self uploadApiVersion]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-ResponseType"), (CFStringRef)[self uploadResponseType]);	
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-FileName"), (CFStringRef)[self cleanNewlines:[[self image] title]]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-AlbumID"), (CFStringRef)[[self albumRef] albumId]);
	
	if(!IsEmpty([[self image] caption]))
		CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-Caption"), (CFStringRef)[self cleanNewlines:[[self image] caption]]);
	
	if(!IsEmpty([[self image] keywords]))
		CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("X-Smug-Keywords"), (CFStringRef)[self cleanKeywords:[[self image] keywords]]);
	
	if(IsNetworkTracingEnabled()) {
		NSLog(@"Image headers: %@", [self imageHeadersForRequest:&myRequest]);
	}
	
	CFHTTPMessageSetBody(myRequest, (CFDataRef)[[self image] imageData]);
	
	readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, myRequest);
	CFRelease(myRequest);
	
	CFStreamClientContext ctxt = {0, self, NULL, NULL, NULL};
	if (!CFReadStreamSetClient(readStream, DAClientNetworkEvents, ReadStreamClientCallBack, &ctxt)) {
		CFRelease(readStream);
		readStream = NULL;
		NSLog(@"CFReadStreamSetClient returned null on start of upload");
		[pool release];
		return;
	}
	
	CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	uploadRunLoop = CFRunLoopGetCurrent();

	@synchronized(self) {
		[self setIsUploading:YES];
	}
	[self setResponse:[NSMutableData data]];
	
	CFReadStreamOpen(readStream);
	
	[NSThread detachNewThreadSelector:@selector(beingUploadProgressTracking) toTarget:self withObject:nil];
	
	// CFRunLoop is not toll-free bridges to NSRunLoop
	while ([self isUploading])
		CFRunLoopRun();
	
	[pool release];
}


-(void)destroyUploadResources {
	@synchronized(self) {
		[self setIsUploading:NO];
	}
	
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
	NSTimer *uploadProgressTimer  = [NSTimer timerWithTimeInterval:SMEUploadProgressTimerInterval target:self selector:@selector(trackUploadProgress:) userInfo:nil repeats:YES];
	
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
	
	[[self observer] uploadMadeProgress:self bytesWritten:bytesWritten ofTotalBytes:[[[self image] imageData] length]];
	
	if(bytesWritten >= [[[self image] imageData] length])
		[timer invalidate];
}

-(void)transferComplete {
	[self setWasSuccessful:YES];
	[self setError:nil];
	[[self observer] uploadComplete:self];
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

-(void)cancelUpload {
	@synchronized(self) {
		if(![self isUploading]) {
			// we're stuck in the upload completed state
			[[self observer] uploadCanceled:self];	
			[self destroyUploadResources];
			return;
		}
		
		// we're in the middle of an upload
		[self setIsUploading:NO];
		[self setWasSuccessful:NO];
	}
	
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


-(void)errorOccurred: (CFStreamError *)err {
	NSString *errorText = [self errorDescriptionForError:err];
	[self setWasSuccessful:NO];
	[[self observer] uploadFailed:self withError:errorText];
	[self destroyUploadResources];
}

-(NSMutableData *)response {
	return response;
}

-(void)setResponse:(NSMutableData *)data {
	if(data != response) {
		[response release];
		response = [data retain];
	}
}

-(BOOL)isUploading {
	return isUploading;
}

-(void)setIsUploading:(BOOL)v {
	isUploading = v;
}
	
-(SMEImage *)image {
	return image;
}

-(void)setImage:(SMEImage *)anImage {
	if(image != anImage) {
		[image release];
		image = [anImage retain];
	}
}
	
-(SMESession *)session {
	return session;
}

-(void)setSession:(SMESession *)aSession {
	if(aSession != session) {
		[session release];
		session = [aSession retain];
	}
}

-(SMEAlbumRef *)albumRef {
	return albumRef;
}

-(void)setAlbumRef:(SMEAlbumRef *)ref {
	if(ref != albumRef) {
		[albumRef release];
		albumRef = [ref retain];
	}
}
		
-(BOOL)wasSuccessful {
	return wasSuccessful;
}

-(void)setWasSuccessful:(BOOL)v {
	wasSuccessful = v;
}

-(NSError *)error {
	return error;
}

-(void)setError:(NSError *)err {
	if(err != error) {
		[error release];
		error = [err retain];
	}
}

-(NSData *)responseData {
	return [NSData dataWithData:[self response]];
}

@end
