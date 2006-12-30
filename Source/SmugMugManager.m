//
//  SmugMugManager.m
//  SmugMugExport
//
//  Created by Aaron Evans on 10/7/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import "SmugMugManager.h"
#import <CURLHandle/CURLHandle.h>
#import "XMLRPCCall.h"
#import "NSDataAdditions.h"

static const CFOptionFlags DAClientNetworkEvents = 
kCFStreamEventOpenCompleted     |
kCFStreamEventHasBytesAvailable |
kCFStreamEventEndEncountered    |
kCFStreamEventErrorOccurred;

@interface SmugMugManager (Private)
-(void)loadFramework;
-(CURLHandle *)curlHandle;
-(void)setCurlHandle:(CURLHandle *)h;
-(NSString *)sessionID;
-(void)setSessionID:(NSString *)anID;
-(NSString *)version;
-(NSString *)apiKey;
-(NSString *)appName;
-(NSString *)XMLRPCURL;
-(NSString *)XMLRPCUploadURL;
-(NSString *)CURLFrameworkPath;
-(NSString *)userID;
-(void)setAlbums:(NSArray *)a;
-(void)setUserID:(NSString *)anID;
-(NSString *)passwordHash;
-(void)setPasswordHash:(NSString *)p;
-(BOOL)CURLIsLoaded;
-(void)unloadFramework;
-(void)loadFramework;
-(NSString *)contentTypeForPath:(NSString *)path;
-(NSLock *)uploadLock;
-(void)setUploadLock:(NSLock *)aLock;
-(NSData *)postBodyForImageAtPath:(NSString *)path albumId:(NSString *)albumId caption:(NSString *)caption;
-(void)appendToResponse;
-(void)transferComplete;
-(void)errorOccurred;
-(NSString *)postUploadURL;
-(void)setIsLoggingIn:(BOOL)v;
-(void)setIsLoggedIn:(BOOL)v;
-(NSDictionary *)defaultNewAlbumPreferences;
-(NSDictionary *)selectedCategory;
-(void)setSelectedCategory:(NSDictionary *)d;
-(void)createNewAlbum;
-(void)createNewAlbumCallback:(SEL)callback;
-(void)newAlbumCreationDidComplete:(XMLRPCCall *)rpcCall;
-(void)destroyUploadResources;

-(NSMutableData *)responseData;
-(void)setResponseData:(NSMutableData *)d;
-(void)setCategories:(NSArray *)categories;
-(void)setSubcategories:(NSArray *)anArray;

-(NSMutableDictionary *)newAlbumPreferences;
-(void)setNewAlbumPreferences:(NSMutableDictionary *)a;
-(NSDictionary *)newAlbumPrefDictionary;

-(void)loginWithCallback:(SEL)loginDidEndSelector;
-(void)logoutWithCallback:(SEL)logoutDidEndSelector;
-(void)logoutCompletedNowLogin:(XMLRPCCall *)rpcCall;
-(void)loginCompletedBuildAlbumList:(XMLRPCCall *)rpcCall;
-(void)buildAlbumListWithCallback:(SEL)callback;
-(void)buildAlbumsListDidComplete:(XMLRPCCall *)rpcCall;
-(void)buildCategoryListWithCallback:(SEL)callback;
-(void)categoryGetDidComplete:(XMLRPCCall *)rpcCall;
-(void)buildSubCategoryListWithCallback:(SEL)callback;
-(void)subcateogryGetDidComplete:(XMLRPCCall *)rpcCall;
-(void)deleteAlbumWithCallback:(SEL)callback albumId:(NSNumber *)albumId;

-(NSString *)smugMugNewAlbumKeyForPref:(NSString *)preferenceKey;

@end

static void ReadStreamClientCallBack(CFReadStreamRef stream, CFStreamEventType type, void *clientCallBackInfo) {
	switch (type) {
		case kCFStreamEventHasBytesAvailable:
			[(SmugMugManager *)clientCallBackInfo appendToResponse];
			break;			
		case kCFStreamEventEndEncountered:
			[(SmugMugManager *)clientCallBackInfo transferComplete];
			break;
		case kCFStreamEventErrorOccurred:
			[(SmugMugManager *)clientCallBackInfo errorOccurred];
			break;
		default:
			break;
	}
}

static inline BOOL IsEmpty(id thing) {
    return thing == nil
	|| ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
	|| ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}

static NSString *Boundary = @"_aBoundAry_$";

static NSString *IsPublicPref = @"IsPublic";
static NSString *ShowFilenamesPref = @"ShowFilenames";
static NSString *AllowCommentsPref = @"AllowComments";
static NSString *AllowExternalLinkingPref = @"AllowExternalLinking";
static NSString *DisplayEXIFInfoPref = @"DisplayEXIFInfo";
static NSString *EnableEasySharePref = @"EnableEasySharing";
static NSString *AllowPurchasingPref = @"AllowPurchasing";
static NSString *AllowOriginalsToBeViewedPref = @"AllowOriginalsToBeViewed";
static NSString *AllowFriendsToEditPref = @"AllowFriendsToEdit";
static NSString *AlbumTitlePref = @"AlbumTitle";
static NSString *AlbumDescriptionPref = @"AlbumDescription";
static NSString *AlbumKeywordsPref = @"AlbumKeywords";
static NSString *AlbumCategoryPref = @"AlbumCategory";

@implementation SmugMugManager

+(SmugMugManager *)smugmugManager {
	return [[[[self class] alloc] init] autorelease];
}

-(id)init {
	if(![super init])
		return nil;

//	[self setUsername:uname];
//	[self setPassword:p];
	[self loadFramework];
	[self setUploadLock:[[[NSLock alloc] init] autorelease]];
	[self setNewAlbumPreferences:[NSMutableDictionary dictionaryWithDictionary:[self defaultNewAlbumPreferences]]]; 
	
	return self;
}

-(void)dealloc {
	[self unloadFramework];

	[[self newAlbumPreferences] release];
	[[self categories] release];
	[[self curlHandle] release];
	[[self albums] release];
	[[self password] release];
	[[self username] release];
	[[self sessionID] release];
	[[self uploadLock] release];
	[[self subcategories] release];
	[[self selectedCategory] release];

	[super dealloc];
}

-(NSDictionary *)defaultNewAlbumPreferences {
	NSNumber *Set = [NSNumber numberWithBool:YES];
//	NSNumber *NotSet = [NSNumber numberWithBool:NO];

	return [NSDictionary dictionaryWithObjectsAndKeys:
		Set, IsPublicPref,
		Set, ShowFilenamesPref,
		Set, AllowCommentsPref,
		Set, AllowExternalLinkingPref,
		Set, DisplayEXIFInfoPref,
		Set, EnableEasySharePref,
		Set, AllowPurchasingPref,
		Set, AllowOriginalsToBeViewedPref,
		Set, AllowFriendsToEditPref,
		nil];

		// unset:
//		nil, @"Title",
//		nil, @"Description",
//		nil, @"Keywords",
//		nil, @"Category"
}

-(NSLock *)uploadLock {
	return uploadLock;
}

-(void)setUploadLock:(NSLock *)aLock {
	if([self uploadLock] != nil)
		[[self uploadLock] release];
	
	uploadLock = [aLock retain];
}

-(void)setIsLoggedIn:(BOOL)v {
	isLoggedIn = v;
}

-(BOOL)isLoggedIn {
	return isLoggedIn;
}

-(void)setIsLoggingIn:(BOOL)v {
	isLoggingIn = v;
}

-(BOOL)isLoggingIn {
	return isLoggingIn;
}

-(void)setDelegate:(id)d {
	delegate = d;
}

-(id)delegate {
	return delegate;
}

-(NSString *)CURLFrameworkPath {
	return [[[NSBundle bundleForClass:[self class]] privateFrameworksPath] stringByAppendingPathComponent:@"/CURLHandle.framework"];
}

-(void)unloadFramework {
	if([self CURLIsLoaded])
		[CURLHandle curlGoodbye];
}

-(void)loadFramework {
	if([self CURLIsLoaded])
		return;

	NSBundle *framework = [NSBundle bundleWithPath:[self CURLFrameworkPath]];
	[framework load];

	CURLHandle *h = [[[CURLHandle alloc] init] autorelease];
	[self setCurlHandle:h];
	[CURLHandle curlHelloSignature:@"XxXx" acceptAll:YES];
}

-(BOOL)CURLIsLoaded {
	NSBundle *frameworkBundle = [NSBundle bundleWithPath:[self CURLFrameworkPath]];
    
	return frameworkBundle != nil && [frameworkBundle isLoaded];
}
	
-(NSString *)sessionID {
	return sessionID;
}

-(void)setSessionID:(NSString *)anID {
	if([self sessionID] != nil)
		[[self sessionID] release];
	
	sessionID = [anID retain];
}

#pragma mark Login/Logout Methods

/* logout if necessary , login, then build album list for user */
-(void)login {
	[self logoutWithCallback:@selector(logoutCompletedNowLogin:)];
}

-(void)logoutCompletedNowLogin:(XMLRPCCall *)rpcCall {
	if(rpcCall == nil || [rpcCall succeeded])
		[self setIsLoggedIn:NO];

	[self setIsLoggingIn:YES];
	[self loginWithCallback:@selector(loginCompletedBuildAlbumList:)];	
}

-(void)logout {
	[self logoutWithCallback:@selector(logoutCallback:)];
}

-(void)loginCompletedBuildAlbumList:(XMLRPCCall *)rpcCall {
	if ([rpcCall succeeded]) {
		NSDictionary *v = (NSDictionary *)[rpcCall returnedObject];
		[self setSessionID:[v objectForKey:@"SessionID"]];
		[self setPasswordHash:[v objectForKey:@"PaswordHash"]];
		[self setUserID:[v objectForKey:@"UserID"]];
		[self setIsLoggedIn:YES];
	} else {
		[self setIsLoggedIn:NO];
	}
	[self buildAlbumListWithCallback:@selector(buildAlbumsListDidComplete:)];
}

-(void)buildAlbumListWithCallback:(SEL)callback {
	XMLRPCCall *call = [[XMLRPCCall alloc] initWithURLString:[self XMLRPCURL]];
	[call setMethodName:@"smugmug.albums.get"];
	[call setParameters:[NSArray arrayWithObjects:[self sessionID], nil]];
	[call invokeInNewThread:self callbackSelector:callback];
}

-(void)buildAlbumsListDidComplete:(XMLRPCCall *)rpcCall {

	if([rpcCall succeeded]) {
		[self setAlbums:[rpcCall returnedObject]];
	}

	[self setIsLoggingIn:NO];
	[self setIsLoggedIn:YES];

	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(loginDidComplete:)])
		[[self delegate] loginDidComplete:[rpcCall succeeded]];
}

-(void)loginWithCallback:(SEL)loginDidEndSelector {
	[self loadFramework];
	[self logout]; // logout from the current session
	[self setIsLoggingIn:YES];
	XMLRPCCall *call = [[XMLRPCCall alloc] initWithURLString:[self XMLRPCURL]];
	[call setMethodName:@"smugmug.login.withPassword"];
	[call setParameters:[NSArray arrayWithObjects:[self username], [self password], [self version], [self apiKey], nil]];
	[call invokeInNewThread:self callbackSelector:loginDidEndSelector];	
}

-(void)logoutWithCallback:(SEL)logoutDidEndSelector {
	if([self sessionID] == nil || ![self isLoggedIn]) {
		[self performSelectorOnMainThread:logoutDidEndSelector withObject:nil waitUntilDone:NO];
		return;
	}

	[self loadFramework];
	XMLRPCCall *call = [[XMLRPCCall alloc] initWithURLString:[self XMLRPCURL]];
	[call setMethodName:@"smugmug.logout"];
	[call setParameters:[NSArray arrayWithObjects:[self sessionID], nil]];
	[call invokeInNewThread:self callbackSelector:logoutDidEndSelector];
}

-(void)loginCallback:(XMLRPCCall *)rpcCall {

	[self setIsLoggingIn:NO];
	
	if ([rpcCall succeeded]) {
		NSDictionary *v = (NSDictionary *)[rpcCall returnedObject];
		[self setSessionID:[v objectForKey:@"SessionID"]];
		[self setPasswordHash:[v objectForKey:@"PaswordHash"]];
		[self setUserID:[v objectForKey:@"UserID"]];
		[self setIsLoggedIn:YES];
	}

	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(loginDidComplete:)])
		[[self delegate] loginDidComplete:[rpcCall succeeded]];
	
	//	[rpcCall release];
}

-(void)logoutCallback:(XMLRPCCall *)rpcCall {
	
	[self setIsLoggedIn:NO];
	
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(logoutDidComplete:)])
		[[self delegate] logoutDidComplete:[rpcCall succeeded]];
	
	//	[rpcCall release];
}

#pragma mark Misc SM Info Methods

-(void)buildCategoryList {
	[self buildCategoryListWithCallback:@selector(categoryGetDidComplete:)];
}

-(void)buildCategoryListWithCallback:(SEL)callback {
	XMLRPCCall *call = [[XMLRPCCall alloc] initWithURLString:[self XMLRPCURL]];
	[call setMethodName:@"smugmug.categories.get"];
	[call setParameters:[NSArray arrayWithObjects:[self sessionID], nil]];
	[call invokeInNewThread:self callbackSelector:callback];
}

-(void)categoryGetDidComplete:(XMLRPCCall *)rpcCall {
	if([rpcCall succeeded]) {
		[self setCategories:[rpcCall returnedObject]];

		// default to the first visible category
		if([[self categories] count] > 0)
			[[self newAlbumPreferences] setObject:[[self categories] objectAtIndex:0] forKey:AlbumCategoryPref];
	}
}

-(void)buildSubCategoryList {
	[self buildSubCategoryListWithCallback:@selector(subcategoryGetDidComplete:)];
}

-(void)buildSubCategoryListWithCallback:(SEL)callback {
	XMLRPCCall *call = [[XMLRPCCall alloc] initWithURLString:[self XMLRPCURL]];
	[call setMethodName:@"smugmug.subcategories.getAll"];
	[call setParameters:[NSArray arrayWithObjects:[self sessionID], nil]];
	[call invokeInNewThread:self callbackSelector:callback];
}

-(void)subcategoryGetDidComplete:(XMLRPCCall *)rpcCall {
	if([rpcCall succeeded]) {
		[self setSubcategories:[rpcCall returnedObject]];
	}
}

#pragma mark Delete Album Methods
-(void)deleteAlbum:(NSNumber *)albumId {
	if(![self isLoggedIn] || IsEmpty(albumId) ) {
	    NSBeep();
		NSLog(@"Cannot delete an album without a title");
		return;
	}
	
	[self deleteAlbumWithCallback:@selector(albumDeleteDidEnd:) albumId:albumId];
}

-(void)deleteAlbumWithCallback:(SEL)callback albumId:(NSNumber *)albumId {
	XMLRPCCall *call = [[XMLRPCCall alloc] initWithURLString:[self XMLRPCURL]];
	[call setMethodName:@"smugmug.albums.delete"];

	[call setParameters:[NSArray arrayWithObjects:[self sessionID], albumId, nil]];
	[call invokeInNewThread:self callbackSelector:callback];	
}

-(void)albumDeleteDidEnd:(XMLRPCCall *)rpcCall {
	if([rpcCall succeeded]) {
		[self buildAlbumListWithCallback:@selector(postAlbumDeleteAlbumSyncDidComplete:)];
	}
}

-(void)postAlbumDeleteAlbumSyncDidComplete:(XMLRPCCall *)rpcCall {
	if([rpcCall succeeded])
		[self setAlbums:[rpcCall returnedObject]];

	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(deleteAlbumDidComplete:)])
		[[self delegate] deleteAlbumDidComplete:[rpcCall succeeded]];
}

#pragma mark New Album Creation Methods

-(void)createNewAlbum {
	if(![self isLoggedIn] ||
	   IsEmpty([[self newAlbumPreferences] objectForKey:AlbumTitlePref])) {
		NSBeep();
		NSLog(@"Cannot create an album without a title");
		return;
	}

	[self createNewAlbumCallback:@selector(newAlbumCreationDidComplete:)];
}

-(void)createNewAlbumCallback:(SEL)callback {
	XMLRPCCall *call = [[XMLRPCCall alloc] initWithURLString:[self XMLRPCURL]];
	[call setMethodName:@"smugmug.albums.create"];
	int selectedCategoryIndex = [selectedCategoryIndices firstIndex];
	[call setParameters:[NSArray arrayWithObjects:[self sessionID], [[self newAlbumPreferences] objectForKey:AlbumTitlePref], [[self categories] objectAtIndex:selectedCategoryIndex], [self newAlbumPrefDictionary], nil]];
	[call invokeInNewThread:self callbackSelector:callback];
}

-(NSDictionary *)newAlbumPrefDictionary {
	NSMutableDictionary *returnDict = [NSMutableDictionary dictionary];
	NSArray *prefKeys = [NSArray arrayWithObjects: IsPublicPref,ShowFilenamesPref,AllowCommentsPref,AllowExternalLinkingPref,DisplayEXIFInfoPref,EnableEasySharePref,AllowPurchasingPref,AllowOriginalsToBeViewedPref,AllowFriendsToEditPref,AlbumDescriptionPref,AlbumKeywordsPref,nil];
	NSEnumerator *keyEnumerator = [prefKeys objectEnumerator];
	NSString *thisKey;
	while(thisKey = [keyEnumerator nextObject]) {
		if(!IsEmpty([newAlbumPreferences objectForKey:thisKey])) {
			[returnDict setObject:[newAlbumPreferences objectForKey:thisKey]
						   forKey:[self smugMugNewAlbumKeyForPref:thisKey]];
		}
	}

	return [NSDictionary dictionaryWithDictionary:returnDict];
}

-(NSString *)smugMugNewAlbumKeyForPref:(NSString *)preferenceKey {
	
	if([preferenceKey isEqualToString:IsPublicPref])
		return @"Public";
	else if([preferenceKey isEqualToString:ShowFilenamesPref])
		return @"Filenames";
	else if([preferenceKey isEqualToString:AllowCommentsPref])
		return @"Comments";
	else if([preferenceKey isEqualToString:AllowExternalLinkingPref])
		return @"External";
	else if([preferenceKey isEqualToString:DisplayEXIFInfoPref])
		return @"EXIF";
	else if([preferenceKey isEqualToString:EnableEasySharePref])
		return @"Share";
	else if([preferenceKey isEqualToString:AllowPurchasingPref])
		return @"Printable";
	else if([preferenceKey isEqualToString:AllowOriginalsToBeViewedPref])
		return @"Originals";
	else if([preferenceKey isEqualToString:AllowFriendsToEditPref])
		return @"FamilyEdit";
	else if([preferenceKey isEqualToString:AlbumTitlePref])
		return @"Title";
	else if([preferenceKey isEqualToString:AlbumDescriptionPref])
		return @"Description";
	else if([preferenceKey isEqualToString:AlbumKeywordsPref])
		return @"Keywords";
	else if([preferenceKey isEqualToString:AlbumCategoryPref])
		return @"CategoryID";
	
	return nil;
}

-(void)newAlbumCreationDidComplete:(XMLRPCCall *)rpcCall {
	if([rpcCall succeeded]) {
		[self buildAlbumListWithCallback:@selector(postAlbumCreateAlbumSyncDidComplete:)];
	}
}

-(void)postAlbumCreateAlbumSyncDidComplete:(XMLRPCCall *)rpcCall {
	if([rpcCall succeeded]) {
		[self setAlbums:[rpcCall returnedObject]];
	}

	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(createNewAlbumDidComplete:)])
		[[self delegate] createNewAlbumDidComplete:[rpcCall succeeded]];
}

-(void)clearAlbumCreationState {
	[[self newAlbumPreferences] removeObjectForKey:AlbumTitlePref];
	[[self newAlbumPreferences] removeObjectForKey:AlbumDescriptionPref];
	[[self newAlbumPreferences] removeObjectForKey:AlbumKeywordsPref];
}

#pragma mark Upload Methods

/**
 *
 */
-(void)uploadImageAtPath:(NSString *)path albumWithID:(NSNumber *)albumId caption:(NSString *)caption {
	
	NSData *postData = [self postBodyForImageAtPath:path albumId:[albumId stringValue] caption:caption];

	CFHTTPMessageRef myRequest;
	myRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("POST"), (CFURLRef)[NSURL URLWithString:[self postUploadURL]], kCFHTTPVersion1_1);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("Content-Type"), (CFStringRef)[NSString stringWithFormat:@"multipart/form-data; boundary=%@", Boundary]);
	CFHTTPMessageSetBody(myRequest, (CFDataRef)postData);

	readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, myRequest);
	CFRelease(myRequest);
	CFStreamClientContext ctxt = {0, self, NULL, NULL, NULL};

	if (!CFReadStreamSetClient(readStream, DAClientNetworkEvents, ReadStreamClientCallBack, &ctxt)) {
		CFRelease(readStream);
		readStream = NULL;
	}

	currentPathForUpload = [path retain];
	CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);

	isUploading = YES;
	uploadSize = [[[[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES]  objectForKey:NSFileSize] longValue];
	[self setResponseData:[NSMutableData data]];

	CFReadStreamOpen(readStream);

	[NSThread detachNewThreadSelector:@selector(beingUploadProgressTracking) toTarget:self withObject:nil];
}

-(void)beingUploadProgressTracking {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSTimer *uploadProgressTimer  = [NSTimer timerWithTimeInterval:0.10 target:self selector:@selector(trackUploadProgress:) userInfo:nil repeats:YES];
	
	[[NSRunLoop currentRunLoop] addTimer:uploadProgressTimer forMode:NSModalPanelRunLoopMode];

	while ( [[NSRunLoop currentRunLoop] runMode:NSModalPanelRunLoopMode
									 beforeDate:[NSDate distantFuture]] );

	[pool release];
}

-(void)trackUploadProgress:(NSTimer *)timer {

	if(!isUploading) {
		[timer invalidate];
		return;
	}

	CFNumberRef bytesWrittenProperty = (CFNumberRef)CFReadStreamCopyProperty (readStream, kCFStreamPropertyHTTPRequestBytesWrittenCount); 
	
	int bytesWritten;
	CFNumberGetValue (bytesWrittenProperty, 3, &bytesWritten);

	[self performSelectorOnMainThread:@selector(updateProgress:) withObject:[NSArray arrayWithObjects:currentPathForUpload, [NSNumber numberWithLong:(long)bytesWritten], [NSNumber numberWithLong:uploadSize], nil] waitUntilDone:NO];
}

-(void)updateProgress:(NSArray *)args {
	long bytesWritten = [(NSNumber *)[args objectAtIndex:1] longValue];
	long totalBytes = [(NSNumber *)[args objectAtIndex:2] longValue];
	
	// notify delegate of progress
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(uploadMadeProgressForFile:bytesWritten:totalBytes:)])
		[[self delegate] uploadMadeProgressForFile:[args objectAtIndex:0] bytesWritten:bytesWritten totalBytes:totalBytes];
}

-(void)appendToResponse {

	UInt8 buffer[2048];
	
	if(!isUploading)
		return;

	CFIndex bytesRead = CFReadStreamRead(readStream, buffer, sizeof(buffer));
	
	if (bytesRead < 0)
		NSLog(@"Warning: Error (< 0b from CFReadStreamRead");
	else if (bytesRead)
		[[self responseData] appendBytes:(void *)buffer length:(unsigned)bytesRead];
}

-(void)stopUpload {
	[self destroyUploadResources];
	
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(uploadDidCompleteForFile:withError:)]) {
		[[self delegate] uploadDidCompleteForFile:currentPathForUpload withError:NSLocalizedString(@"Upload was cancelled.", @"Error strinng for cancelled upload")];
	}
}

-(NSMutableData *)responseData {
	return responseData;
}

-(void)setResponseData:(NSMutableData *)d {
	if([self responseData] != nil)
		[[self responseData] release];
	
	responseData = [d retain];
}

-(void)destroyUploadResources {
	isUploading = NO;
	CFRelease(readStream);
	[self setResponseData:nil];
	[currentPathForUpload release];
}

-(void)transferComplete {

	XMLRPCResponse *response = [[[XMLRPCResponse alloc] initWithData:[self responseData]] autorelease];

	NSString *errorString = nil;
	if([response isFault]) 
		errorString = [response faultString];

	[self destroyUploadResources];

	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(uploadDidCompleteForFile:withError:)]) {
		[[self delegate] uploadDidCompleteForFile:currentPathForUpload withError:errorString];
	}
}

-(void)errorOccurred {
	[self destroyUploadResources];	

	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(uploadDidCompleteForFile:withError:)]) {
		[[self delegate] uploadDidCompleteForFile:currentPathForUpload withError:NSLocalizedString(@"Upload Failed", @"The upload was interrupted in progress.")];
	}
}

-(NSData *)postDataWithName:(NSString *)aName postContents:(NSString *)postContents {
	NSMutableData *data = [NSMutableData data];
	[data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", aName] dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[postContents dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",Boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	return data;
}

-(NSData *)postBodyForImageAtPath:(NSString *)path albumId:(NSString *)albumId caption:(NSString *)caption {
	NSData *imageData = [NSData dataWithContentsOfFile:path];
	NSAssert(imageData != nil, @"cannot create image from data");

	NSMutableData *postBody = [NSMutableData data];
	[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",Boundary] dataUsingEncoding:NSUTF8StringEncoding]];

	[postBody appendData:[self postDataWithName:@"AlbumID" postContents:albumId]];
	[postBody appendData:[self postDataWithName:@"SessionID" postContents:[self sessionID]]];
	[postBody appendData:[self postDataWithName:@"ByteCount" postContents:[NSString stringWithFormat:@"%d", [imageData length]]]];
	[postBody appendData:[self postDataWithName:@"MD5Sum" postContents:[imageData md5HexString]]];

	if(caption != nil)
		[postBody appendData:[self postDataWithName:@"Caption" postContents:caption]];

	[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"Image\"; filename=\"%@\"\r\n", [path lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Type: image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:imageData];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",Boundary] dataUsingEncoding:NSUTF8StringEncoding]];

	return postBody;	
}

-(NSString *)contentTypeForPath:(NSString *)path {
	if([[path lowercaseString] hasSuffix:@"jpg"] ||
	   [[path lowercaseString] hasSuffix:@"jpeg"] ||
	   [[path lowercaseString] hasSuffix:@"jpe"])
		return @"image/jpeg";
	else if([[path lowercaseString] hasSuffix:@"tiff"] ||
			[[path lowercaseString] hasSuffix:@"tif"])
		return @"image/tiff";
	else if([[path lowercaseString] hasSuffix:@"png"])
		return @"image/png";
	else if([[path lowercaseString] hasSuffix:@"gif"])
		return @"image/gif";

	return @"image/jpeg"; // guess??
}	

-(NSMutableDictionary *)newAlbumPreferences {
	return newAlbumPreferences;
}



-(void)setSelectedCategory:(NSDictionary *)d {
	if([self selectedCategory] != nil)
		[[self selectedCategory] release];
	
	selectedCategory = [d retain];
}

-(void)setNewAlbumPreferences:(NSMutableDictionary *)a {
	if([self newAlbumPreferences] != nil)
		[[self newAlbumPreferences] release];
	
	newAlbumPreferences = [a retain];
}

-(NSArray *)subcategories {
	return subcategories;
}

-(void)setSubcategories:(NSArray *)anArray {
	if([self subcategories] != nil)
		[[self subcategories] release];
	
	subcategories = [anArray retain];
}

-(NSArray *)categories {
	return categories;
}

-(void)setCategories:(NSArray *)anArray {
	if([self categories] != nil)
		[[self categories] release];
	
	categories = [anArray retain];
}

-(NSString *)userID {
	return userID;
}

-(void)setUserID:(NSString *)anID {

	if([self userID] != nil)
		[[self userID] release];

	userID = [anID retain];
}

-(NSString *)passwordHash {
	return passwordHash;
}

-(void)setPasswordHash:(NSString *)p {
	if([self passwordHash] != nil)
		[[self passwordHash] release];
	
	passwordHash = [p retain];
}

-(NSString *)username {
	return username;
}

-(void)setUsername:(NSString *)n {
	if([self username] != nil)
		[[self username] release];
	
	username = [n retain];
}
		
-(NSString *)password {
	return password;
}

-(void)setPassword:(NSString *)p {
	if([self password] != nil)
		[[self password] release];
	
	password = [p retain];
}

-(CURLHandle *)curlHandle {
	return curlHandle;
}

-(void)setCurlHandle:(CURLHandle *)h {
	if([self curlHandle] != nil)
		[[self curlHandle] release];
	
	curlHandle = [h retain];
}

-(NSString *)version {
	return @"1.1.0";
}

-(void)setAlbums:(NSArray *)a {
	if([self albums] != nil)
		[[self albums] release];
	
	albums = [a retain];
}

-(NSArray *)albums {
	return albums;
}

-(NSString *)apiKey {
	return @"98LHI74dS6P0A8cQ1M6h0R1hXsbIPDXc";
}

-(NSString *)appName {
	return @"SmugMugExport";
}

-(NSString *)XMLRPCURL {
	return @"https://api.SmugMug.com/hack/xmlrpc/";
}

-(NSString *)XMLRPCUploadURL {
	return @"http://upload.SmugMug.com/hack/xmlrpc/";
}

-(NSString *)postUploadURL {
	return @"http://upload.SmugMug.com/photos/xmladd.mg";
}

@end
