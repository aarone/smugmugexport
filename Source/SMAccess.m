//
//  SMAccess.m
//  SmugMugExport
//
//  Created by Aaron Evans on 10/7/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import "SMAccess.h"
#import "SMGlobals.h"
#import "SMRequest.h"
#import "SMDecoder.h"
#import "NSUserDefaultsAdditions.h"
#import "SMJSONDecoder.h"
#import "SMAlbum.h"
#import "SMImageRef.h"
#import "SMAlbumInfo.h"

@interface SMAccess (Private)
-(NSString *)sessionID;
-(void)setSessionID:(NSString *)anID;
-(void)setAlbums:(NSArray *)a;
-(void)setUserID:(NSString *)anID;
-(NSString *)passwordHash;
-(void)setPasswordHash:(NSString *)p;

-(BOOL)requestWasSuccessful:(SMRequest *)req;
-(void)evaluateLoginResponse:(id)response;

-(NSURL *)baseRequestUrl;

-(void)setIsLoggingIn:(BOOL)v;
-(void)setIsLoggedIn:(BOOL)v;
-(NSDictionary *)defaultNewAlbumPreferences;
-(void)newAlbumCreationDidComplete:(SMRequest *)req;

-(void)setCategories:(NSArray *)categories;
-(void)setSubcategories:(NSArray *)anArray;

-(void)loginWithCallback:(SEL)loginDidEndSelector;
-(void)logoutWithCallback:(SEL)logoutDidEndSelector;
-(void)logoutCompletedNowLogin:(SMRequest *)req;
-(void)loginCompletedBuildAlbumList:(SMRequest *)req;
-(void)buildAlbumListWithCallback:(SEL)callback;
-(void)buildAlbumsListDidComplete:(SMRequest *)req;
-(void)buildCategoryListWithCallback:(SEL)callback;
-(void)categoryGetDidComplete:(SMRequest *)req;
-(void)buildSubCategoryListWithCallback:(SEL)callback;
-(void)subcategoryGetDidComplete:(SMRequest *)req;
-(void)deleteAlbumWithCallback:(SEL)callback albumRef:(SMAlbumRef *)albumRef;
-(void)getImageUrlsWithCallback:(SEL)callback imageRef:(SMImageRef *)ref;
-(void)createNewAlbumCallback:(SEL)callback withInfo:(SMAlbumInfo *)info;
-(void)getImageUrlsDidComplete:(SMRequest *)req;
-(NSString *)smugMugNewAlbumKeyForPref:(NSString *)preferenceKey;
-(NSObject<SMDecoder> *)decoder;
-(SMRequest *)createRequest;
-(SMRequest *)lastUploadRequest;
-(void)setLastUploadRequest:(SMRequest *)request;	
-(void)fetchAlbumWithCallback:(SEL)callback forAlbum:(SMAlbumRef *)ref;
-(void)notifyDelegateOfAlbumInfoCompletionWithArgs:(NSArray *)args;
-(void)initializeAlbumsFromResponse:(id)response;
-(void)notifyDelegateOfEditCompletionWithArgs:(NSArray *)args;
@end

static const NSTimeInterval AlbumRefreshDelay = 1.0;

@interface NSDictionary (SMAdditions)
-(NSComparisonResult)compareByAlbumId:(NSDictionary *)aDict;
@end

@implementation NSDictionary (SMAdditions)
-(NSComparisonResult)compareByAlbumId:(NSDictionary *)aDict {
	
	if([self objectForKey:@"id"] == nil)
		return NSOrderedAscending;
	
	if([aDict objectForKey:@"id"] == nil)
		return NSOrderedDescending;
		
	return [[aDict objectForKey:@"id"] intValue] - [[self objectForKey:@"id"] intValue];
}

-(NSComparisonResult)compareByTitle:(NSDictionary *)aDict {
	return [[self objectForKey:@"Title"] caseInsensitiveCompare:[aDict objectForKey:@"Title"]];
}
@end

@implementation SMAccess

+(SMAccess *)smugmugManager {
	return [[[[self class] alloc] init] autorelease];
}

-(void)dealloc {

	[[self categories] release];
	[[self albums] release];
	[[self password] release];
	[[self username] release];
	[[self sessionID] release];
	[[self subcategories] release];
	[[self lastUploadRequest] release];
	
	[super dealloc];
}

-(NSObject<SMDecoder> *)decoder {
	return [SMJSONDecoder decoder];
}

-(SMRequest *)createRequest {
	return [SMRequest SMRequest:[self decoder]];
}

#pragma mark Miscellaneous Get/Set Methods

-(NSURL *)baseRequestUrl {
	return [NSURL URLWithString:@"https://api.smugmug.com/hack/json/1.2.0/"];
}

-(NSString *)apiKey {
	return @"98LHI74dS6P0A8cQ1M6h0R1hXsbIPDXc";
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

-(NSArray *)albums {
	return albums;
}

-(void)setAlbums:(NSArray *)a {
	if(albums != nil) {
		[[self albums] release];
	}
	albums = [a retain];
}

-(SMRequest *)lastUploadRequest {
	return lastUploadRequest;
}

-(void)setLastUploadRequest:(SMRequest *)request {
	if([self lastUploadRequest] != nil)
		[[self lastUploadRequest] release];
	
	lastUploadRequest = [request retain];
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

-(void)logoutCompletedNowLogin:(SMRequest *)req {
	if(req == nil || ([req wasSuccessful] && [self requestWasSuccessful:req])) {
		[self setIsLoggedIn:NO];
	}

	[self setIsLoggingIn:YES];
	[self loginWithCallback:@selector(loginCompletedBuildAlbumList:)];	
}

-(void)logout {
	[self logoutWithCallback:@selector(logoutCallback:)];
}

-(void)loginCompletedBuildAlbumList:(SMRequest *)req {
	if ([self requestWasSuccessful:req]) {
		[self evaluateLoginResponse:[req decodedResponse]];
		[self buildAlbumListWithCallback:@selector(buildAlbumsListDidComplete:)];
	} else {
		[self setIsLoggedIn:NO];
		[self setIsLoggingIn:NO];
		[self performSelectorOnMainThread:@selector(notifyDelegateOfLoginCompleted:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
	}	
}

-(void)evaluateLoginResponse:(id)response {
	NSString *sessId = [[[response objectForKey:@"Login"] objectForKey:@"Session"] objectForKey:@"id"];
	NSString *passHash = [[response objectForKey:@"Login"] objectForKey:@"PasswordHash"];
	NSNumber *uid = [[[response objectForKey:@"Login"] objectForKey:@"User"] objectForKey:@"id"];
	
	NSAssert(sessId != nil && passHash != nil && uid != nil, NSLocalizedString(@"Unexpected response for login", @"Error string when the response returned by the login method is malformed."));
	
	[self setSessionID:sessId];
	[self setPasswordHash:passHash];
	[self setUserID:[uid stringValue]];
}

#pragma mark Album Fetch
-(void)fetchAlbums {
	[self buildAlbumListWithCallback:@selector(fetchAlbumsComplete:)];
}

-(void)fetchAlbumsComplete:(SMRequest *)req {
	if([self requestWasSuccessful:req])
		[self initializeAlbumsFromResponse:[req decodedResponse]];
	
	[[self delegate] performSelectorOnMainThread:@selector(albumsFetchDidComplete:) withObject:[NSNumber numberWithBool:[self requestWasSuccessful:req]] waitUntilDone:NO];	
}

/* 
 * This method is called to build the list of known albums and after an album is 
 * added or deleted.  See the workaround below.
 */
-(void)buildAlbumListWithCallback:(SEL)callback {
	SMRequest *req = [self createRequest];

	/*
	 * If we add or delete an album and then refresh the list using this method,
	 * we occasionally get a list returned that includes the deleted album or 
	 * doesn't include the album that was just added.  My suspicion is that this
	 * is because I'm refreshing the list too quickly after modifying the album
	 * list.  To workaround this, we insert a delay here and hope for the best.
	 */
	if(EnableAlbumFetchDelay())
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:AlbumRefreshDelay]];
	
	[req invokeMethodWithURL:[self baseRequestUrl] 
						  keys:[NSArray arrayWithObjects:@"method", @"SessionID", nil]
						values:[NSArray arrayWithObjects:@"smugmug.albums.get", [self sessionID], nil]
			  responseCallback:callback
				responseTarget:self];
}

// transform an array of dicts given to use by SM to an array of SMAlbum
-(NSArray *)transformSMAlbums:(NSArray *)smAlbums {
	NSMutableArray *result = [NSMutableArray array];
	
	NSEnumerator *albumEnum = [smAlbums objectEnumerator];
	NSDictionary *anAlbum = nil;
	while(anAlbum = [albumEnum nextObject])
		[result addObject:[SMAlbum albumWithSMResponse:anAlbum]];
	
	return [NSArray arrayWithArray:result];
}

-(void)initializeAlbumsFromResponse:(id)response {
	NSMutableArray *returnedAlbums = [NSMutableArray arrayWithArray:[response objectForKey:@"Albums"]];
	[returnedAlbums sortUsingSelector:@selector(compareByAlbumId:)];
	
	[self performSelectorOnMainThread:@selector(setAlbums:)	
							   withObject:[self transformSMAlbums:returnedAlbums] waitUntilDone:false];
}

-(void)notifyDelegateOfLoginCompleted:(NSNumber *)wasSuccessful {
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(loginDidComplete:)])
		[[self delegate] performSelectorOnMainThread:@selector(loginDidComplete:) withObject:wasSuccessful waitUntilDone:NO];
}

-(void)buildAlbumsListDidComplete:(SMRequest *)req {

	if([self requestWasSuccessful:req])
		[self initializeAlbumsFromResponse:[req decodedResponse]];

	[self setIsLoggingIn:NO];
	[self setIsLoggedIn:YES];

	[self performSelectorOnMainThread:@selector(notifyDelegateOfLoginCompleted:) withObject:[NSNumber numberWithBool:[self requestWasSuccessful:req]] waitUntilDone:NO];
}

-(void)loginWithCallback:(SEL)loginDidEndSelector {
	[self setIsLoggingIn:YES];
	SMRequest *request = [self createRequest];

	[request invokeMethodWithURL:[self baseRequestUrl] 
						  keys:[NSArray arrayWithObjects:@"method", @"EmailAddress",@"Password", @"APIKey", nil]
						values:[NSArray arrayWithObjects:@"smugmug.login.withPassword", [self username], [self password], [self apiKey], nil]
			  responseCallback:loginDidEndSelector
				responseTarget:self];
}

-(BOOL)requestWasSuccessful:(SMRequest *)req {
	if(![req wasSuccessful])
		return NO;
	
	return [[[req decodedResponse] objectForKey:@"stat"] isEqualToString:@"ok"];
}

-(void)loginCompleted:(SMRequest *)req {
	if([self requestWasSuccessful:req]) {
		[self evaluateLoginResponse:[req decodedResponse]];
	}
}

-(void)logoutWithCallback:(SEL)logoutDidEndSelector {
	if([self sessionID] == nil || ![self isLoggedIn]) {
		[self performSelectorOnMainThread:logoutDidEndSelector withObject:nil waitUntilDone:NO];
		return;
	}

	SMRequest *req = [self createRequest];	
	[req invokeMethodWithURL:[self baseRequestUrl] 
						  keys:[NSArray arrayWithObjects:@"method", @"SessionID", nil]
						values:[NSArray arrayWithObjects:@"smugmug.logout", [self sessionID], nil]
			  responseCallback:logoutDidEndSelector
				responseTarget:self];
}

-(void)notifyDelegaeOfLogout:(NSNumber *)wasSuccessful {
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(logoutDidComplete:)])
		[[self delegate] performSelectorOnMainThread:@selector(logoutDidComplete:) withObject:wasSuccessful waitUntilDone:NO];
}

-(void)logoutCallback:(SMRequest *)req {

	[self setIsLoggedIn:NO];
	[self setAlbums:[NSArray array]];
	[self setIsLoggedIn:NO];
	[self setCategories:[NSArray array]];
	[self setSubcategories:[NSArray array]];
	
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(logoutDidComplete:)])
		[[self delegate] performSelectorOnMainThread:@selector(logoutDidComplete:) withObject:[NSNumber numberWithBool:[self requestWasSuccessful:req]] waitUntilDone:NO];
}

#pragma mark Upload 

-(void)uploadImageData:(NSData *)imageData
			  filename:(NSString *)filename
				 album:(SMAlbumRef *)albumRef
			  caption:(NSString *)caption
			  keywords:(NSArray *)keywords {
	
	SMRequest *uploadRequest = [self createRequest];
	[self setLastUploadRequest:uploadRequest];
	[uploadRequest uploadImageData:imageData
						  filename:filename
						 sessionId:[self sessionID]
							 album:albumRef
						  caption:caption
						  keywords:keywords
						  observer:self];
}

-(void)notifyDelegateOfProgress:(NSArray *)args {
	[[self delegate] uploadMadeProgress:[args objectAtIndex:0]
						   bytesWritten:[[args objectAtIndex:1] longValue]
						   ofTotalBytes:[[args objectAtIndex:2] longValue]];
}

-(void)uploadMadeProgress:(SMRequest *)request bytesWritten:(long)numberOfBytes ofTotalBytes:(long)totalBytes {
	[self performSelectorOnMainThread:@selector(notifyDelegateOfProgress:) 
						   withObject:[NSArray arrayWithObjects:[request imageData], [NSNumber numberWithLong:numberOfBytes], [NSNumber numberWithLong:totalBytes], nil]
						waitUntilDone:NO];
}

-(void)notifyDelegateOfUploadFailure:(NSArray *)args {
	[[self delegate] uploadDidFail:[args objectAtIndex:0] reason:[args objectAtIndex:1]];
}


-(void)uploadCanceled:(SMRequest *)request {
	[[self delegate] performSelectorOnMainThread:@selector(uploadWasCanceled)
						   withObject:nil
						waitUntilDone:NO];	
}

-(void)uploadFailed:(SMRequest *)request withError:(NSString *)reason {
	[self performSelectorOnMainThread:@selector(notifyDelegateOfUploadFailure:)
						   withObject:[NSArray arrayWithObjects:[request imageData], reason, nil]
						waitUntilDone:NO];	
}

-(void)notifyDelegateOfUploadSuccess:(NSArray *)args {
	[[self delegate] uploadDidSucceeed:[args objectAtIndex:0] 
							  imageRef:[SMImageRef refWithId:[args objectAtIndex:1] key:[args objectAtIndex:2]]
						   requestDict:[args objectAtIndex:3]];
}

-(void)uploadSucceeded:(SMRequest *)request {
	[self performSelectorOnMainThread:@selector(notifyDelegateOfUploadSuccess:)
						   withObject:[NSArray arrayWithObjects:[request imageData], [[[request decodedResponse] objectForKey:@"Image"] objectForKey:@"id"], [[[request decodedResponse] objectForKey:@"Image"] objectForKey:@"Key"], [request requestDict], nil]
						waitUntilDone:NO];
}

-(void)stopUpload {
	[[self lastUploadRequest] cancelUpload];
}

#pragma mark Misc SM Info Methods

-(void)fetchImageUrls:(SMImageRef *)ref {
	[self getImageUrlsWithCallback:@selector(getImageUrlsDidComplete:) imageRef:ref];
}

-(void)getImageUrlsWithCallback:(SEL)callback imageRef:(SMImageRef *)ref {
	SMRequest *req = [self createRequest];
	[req invokeMethodWithURL:[self baseRequestUrl]
						 keys:[NSArray arrayWithObjects:@"method", @"SessionID", @"ImageID", @"ImageKey", nil]
					   values:[NSArray arrayWithObjects:@"smugmug.images.getURLs", [self sessionID], [ref imageId], [ref imageKey], nil]
			 responseCallback:callback
			   responseTarget:self];
}

-(void)getImageUrlsDidComplete:(SMRequest *)req {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	SMImageRef *ref = [SMImageRef refWithId:[[req requestDict] objectForKey:@"ImageID"]
											 key:[[req requestDict] objectForKey:@"ImageKey"]];
	[dict setObject:ref forKey:@"ImageRef"];

	if([self requestWasSuccessful:req]) {
		[dict setObject:[[req decodedResponse] objectForKey:@"Image"] forKey:@"Urls"];
	}
	
	[self performSelectorOnMainThread:@selector(notifyDelegateOfFetchImageUrlCompletion:)
						   withObject:dict
						waitUntilDone:NO];
}

-(void)notifyDelegateOfFetchImageUrlCompletion:(NSDictionary *)args {
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(imageUrlFetchDidCompleteForImageRef:imageUrls:)])
		[[self delegate] imageUrlFetchDidCompleteForImageRef:[args objectForKey:@"ImageRef"]
												  imageUrls:[args objectForKey:@"Urls"]];
}

-(void)buildCategoryList {
	[self buildCategoryListWithCallback:@selector(categoryGetDidComplete:)];
}

-(void)buildCategoryListWithCallback:(SEL)callback {
	SMRequest *req = [self createRequest];
	[req invokeMethodWithURL:[self baseRequestUrl]
						  keys:[NSArray arrayWithObjects:@"method", @"SessionID", nil]
						values:[NSArray arrayWithObjects:@"smugmug.categories.get", [self sessionID], nil]
			  responseCallback:callback
				responseTarget:self];
}

-(void)initializeCategoriesWithResponse:(id)response {
	NSMutableArray *returnedCategories = [NSMutableArray arrayWithArray:[response objectForKey:@"Categories"]];
	[returnedCategories sortUsingSelector:@selector(compareByTitle:)];
	[self performSelectorOnMainThread:@selector(setCategories:)	withObject:[NSArray arrayWithArray:returnedCategories] waitUntilDone:false];
}

-(void)categoryGetDidComplete:(SMRequest *)req {
	if([self requestWasSuccessful:req])
		[self initializeCategoriesWithResponse:[req decodedResponse]];
	
}

-(void)buildSubCategoryList {
	[self buildSubCategoryListWithCallback:@selector(subcategoryGetDidComplete:)];
}

-(void)buildSubCategoryListWithCallback:(SEL)callback {
	SMRequest *req = [self createRequest];
	[req invokeMethodWithURL:[self baseRequestUrl]
						  keys:[NSArray arrayWithObjects:@"method", @"SessionID", nil]
						values:[NSArray arrayWithObjects:@"smugmug.subcategories.getAll", [self sessionID], nil]
			  responseCallback:callback
				responseTarget:self];
}

-(void)initializeSubcategoriesWithResponse:(id)response {
	NSMutableArray *returnedSubCategories = [NSMutableArray arrayWithArray:[response objectForKey:@"SubCategories"]];
	[returnedSubCategories sortUsingSelector:@selector(compareByTitle:)];
	[self performSelectorOnMainThread:@selector(setSubcategories:)	withObject:[NSArray arrayWithArray:returnedSubCategories] waitUntilDone:false];	
}

-(void)subcategoryGetDidComplete:(SMRequest *)req {
	if([self requestWasSuccessful:req])
		[self initializeSubcategoriesWithResponse:[req decodedResponse]];
}

#pragma mark Delete Album Methods
-(void)deleteAlbum:(SMAlbumRef *)albumRef {
	if(![self isLoggedIn] || IsEmpty([albumRef albumId]) ) {
	    NSBeep();
		NSLog(@"Cannot delete an album without a title");
		return;
	}
	
	[self deleteAlbumWithCallback:@selector(albumDeleteDidEnd:) albumRef:albumRef];
}

-(void)deleteAlbumWithCallback:(SEL)callback albumRef:(SMAlbumRef *)albumRef {
	SMRequest *req = [self createRequest];
	[req invokeMethodWithURL:[self baseRequestUrl]
						  keys:[NSArray arrayWithObjects:@"method", @"SessionID", @"AlbumID", nil]
						values:[NSArray arrayWithObjects:@"smugmug.albums.delete", [self sessionID], [albumRef albumId], nil]
			  responseCallback:callback
				responseTarget:self];
}

-(void)notifyDelegateOfAlbumSyncCompletion:(NSNumber *)wasSuccessful {
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(deleteAlbumDidComplete:)])
		[[self delegate] performSelectorOnMainThread:@selector(deleteAlbumDidComplete:) withObject:wasSuccessful waitUntilDone:NO];
}

-(void)notifyDelegateOfAlbumCompletion:(NSNumber *)wasSuccessful {
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(createNewAlbumDidComplete:)])
		[[self delegate] performSelectorOnMainThread:@selector(createNewAlbumDidComplete:) withObject:wasSuccessful waitUntilDone:NO];
}

-(void)albumDeleteDidEnd:(SMRequest *)req {
	if([self requestWasSuccessful:req]) {
		[self buildAlbumListWithCallback:@selector(postAlbumDeleteAlbumSyncDidComplete:)];
	} else {
		[self notifyDelegateOfAlbumCompletion:[NSNumber numberWithBool:NO]];
	}
}

-(void)postAlbumDeleteAlbumSyncDidComplete:(SMRequest *)req {

	if([self requestWasSuccessful:req])
		[self initializeAlbumsFromResponse:[req decodedResponse]];

	[self notifyDelegateOfAlbumSyncCompletion:[NSNumber numberWithBool:[self requestWasSuccessful:req]]];
}

#pragma mark New Album Creation Methods

-(void)createNewAlbum:(SMAlbumInfo *)info {		
	// don't try to create an album if we're not logged in
	if(![self isLoggedIn])
		[self performSelectorOnMainThread:@selector(notifyDelegateOfAlbumCompletion:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
	else {
		[self createNewAlbumCallback:@selector(newAlbumCreationDidComplete:) withInfo:info];
	}
}

-(void)createNewAlbumCallback:(SEL)callback withInfo:(SMAlbumInfo *)info {
	
	SMRequest *req = [self createRequest];
	
	NSMutableDictionary *props = [NSMutableDictionary dictionaryWithDictionary:[info toDictionary]];
	[props setObject:@"smugmug.albums.create" forKey:@"method"];
	[props setObject:[self sessionID] forKey:@"SessionID"];
	
	[req invokeMethodWithURL:[self baseRequestUrl]
						keys:[props allKeys]
				   valueDict:props
			responseCallback:callback
			  responseTarget:self];
}


-(void)newAlbumCreationDidComplete:(SMRequest *)req {
	if([self requestWasSuccessful:req])
		[self buildAlbumListWithCallback:@selector(postAlbumCreateAlbumSyncDidComplete:)];
	else {
		[self performSelectorOnMainThread:@selector(notifyDelegateOfAlbumCompletion:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
	}
}

-(void)postAlbumCreateAlbumSyncDidComplete:(SMRequest *)req {
	if([self requestWasSuccessful:req])
		[self initializeAlbumsFromResponse:[req decodedResponse]];

	[self performSelectorOnMainThread:@selector(notifyDelegateOfAlbumCompletion:) withObject:[NSNumber numberWithBool:[self requestWasSuccessful:req]] waitUntilDone:NO];
}

#pragma mark Album Info Fetch Methods
-(void)fetchAlbumInfo:(SMAlbumRef *)ref {
	if(![self isLoggedIn])
		[self performSelectorOnMainThread:@selector(notifyDelegateOfAlbumInfoCompletionWithArgs:) 
							   withObject:[NSArray arrayWithObjects:[NSNumber numberWithBool:NO], ref, [NSNull null], nil]
							waitUntilDone:NO];
	[self fetchAlbumWithCallback:@selector(albumFetchDidComplete:) forAlbum:ref];
}

-(void)fetchAlbumWithCallback:(SEL)callback forAlbum:(SMAlbumRef *)ref{
	SMRequest *req = [self createRequest];
	
	NSMutableDictionary *props = [NSMutableDictionary dictionaryWithCapacity:5];
	[props setObject:@"smugmug.albums.getInfo" forKey:@"method"];
	[props setObject:[self sessionID] forKey:@"SessionID"];
	[props setObject:[ref albumId] forKey:@"AlbumID"];
	[props setObject:[ref albumKey] forKey:@"AlbumKey"];
	
	[req setContext:[ref retain]];
	[req invokeMethodWithURL:[self baseRequestUrl]
						keys:[props allKeys]
				   valueDict:props
			responseCallback:callback
			  responseTarget:self];
	
}

-(void)albumFetchDidComplete:(SMRequest *)req {
	SMAlbumRef *ref = (SMAlbumRef *)[req context];
	[ref release];
	id info = [req wasSuccessful] ? 
						 (id)[SMAlbumInfo albumInfoWithSMResponse:[[req decodedResponse] objectForKey:@"Album"]
												   categories:categories
												subcategories:subcategories] : (id)[NSNull null];
	
	[self performSelectorOnMainThread:@selector(notifyDelegateOfAlbumInfoCompletionWithArgs:) 
						   withObject:[NSArray arrayWithObjects:[NSNumber numberWithBool:[self requestWasSuccessful:req]], ref, info, nil] 
						waitUntilDone:NO];
}

-(void)notifyDelegateOfAlbumInfoCompletionWithArgs:(NSArray *)args {	
	[[self delegate] albumInfoFetchDidComplete:[args objectAtIndex:0]
									  forAlbum:[args objectAtIndex:1]
										  info:[args objectAtIndex:2]];
}

#pragma mark Edit Album

-(void)editAlbum:(SMAlbumInfo *)info {
	SMRequest *req = [self createRequest];
	
	[req setContext:[[info ref] retain]];
	NSMutableDictionary *args = [NSMutableDictionary dictionaryWithDictionary:[info toDictionary]];
	[args setObject:[self sessionID] forKey:@"SessionID"];
	[args setObject:@"smugmug.albums.changeSettings" forKey:@"method"];
	[req invokeMethodWithURL:[self baseRequestUrl]
						keys:[args allKeys]
				   valueDict:args
			responseCallback:@selector(editDidComplete:)
			  responseTarget:self];
}

-(void)editDidComplete:(SMRequest *)req {
	SMAlbumInfo *info = (SMAlbumInfo *)[req context];
	SMAlbumRef *ref = [SMAlbumRef refWithId:[info albumId]  key:[info albumKey]];
	[(SMAlbumInfo *)[req context] release];
	[self notifyDelegateOfEditCompletionWithArgs:[NSArray arrayWithObjects:[NSNumber numberWithBool:[req wasSuccessful]], ref, nil]];
}
		 
-(void)notifyDelegateOfEditCompletionWithArgs:(NSArray *)args {
	 SEL delegateCallback = @selector(albumEditDidComplete:forAlbum:);
	 if([self delegate] == nil || ![[self delegate] respondsToSelector:delegateCallback])
		 return;
	
	[[self delegate] albumEditDidComplete:[args objectAtIndex:0] forAlbum:[args objectAtIndex:1]];
}
		 


@end
