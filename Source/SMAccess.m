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
-(void)deleteAlbumWithCallback:(SEL)callback albumId:(NSString *)albumId;
-(void)getImageUrlsWithCallback:(SEL)callback imageId:(NSString *)imageId;
-(void)createNewAlbumCallback:(SEL)callback
				 withCategory:(NSString *)categoryId 
				  subcategory:(NSString *)subCategoryId
						title:(NSString *)title 
			  albumProperties:(NSDictionary *)properties;
-(void)getImageUrlsDidComplete:(SMRequest *)req;
-(NSString *)smugMugNewAlbumKeyForPref:(NSString *)preferenceKey;
-(NSObject<SMDecoder> *)decoder;
-(SMRequest *)createRequest;
-(SMRequest *)lastUploadRequest;
-(void)setLastUploadRequest:(SMRequest *)request;	
-(NSPredicate *)createRelevantSubCategoryFilterForCategory:(NSDictionary *)aCategory;
@end

NSString *IsPublicPref = @"IsPublic";
NSString *ShowFilenamesPref = @"ShowFilenames";
NSString *AllowCommentsPref = @"AllowComments";
NSString *AllowExternalLinkingPref = @"AllowExternalLinking";
NSString *DisplayEXIFInfoPref = @"DisplayEXIFInfo";
NSString *EnableEasySharePref = @"EnableEasySharing";
NSString *AllowPurchasingPref = @"AllowPurchasing";
NSString *AllowOriginalsToBeViewedPref = @"AllowOriginalsToBeViewed";
NSString *AllowFriendsToEditPref = @"AllowFriendsToEdit";
NSString *AlbumTitlePref = @"AlbumTitle";
NSString *AlbumDescriptionPref = @"AlbumDescription";
NSString *AlbumKeywordsPref = @"AlbumKeywords";
NSString *AlbumCategoryPref = @"AlbumCategory";

static const NSTimeInterval AlbumRefreshDelay = 1.0;

@interface NSDictionary (SMAdditions)
-(NSComparisonResult)compareByAlbumId:(NSDictionary *)aDict;
@end

@implementation NSDictionary (SMAdditions)
-(NSComparisonResult)compareByAlbumId:(NSDictionary *)aDict {
	
	if([self objectForKey:SMAlbumID] == nil)
		return NSOrderedAscending;
	
	if([aDict objectForKey:SMAlbumID] == nil)
		return NSOrderedDescending;
		
	return [[aDict objectForKey:SMAlbumID] intValue] - [[self objectForKey:SMAlbumID] intValue];
}

-(NSComparisonResult)compareByTitle:(NSDictionary *)aDict {
	return [[self objectForKey:@"Title"] caseInsensitiveCompare:[aDict objectForKey:@"Title"]];
}
@end

@implementation SMAccess

+(SMAccess *)smugmugManager {
	return [[[[self class] alloc] init] autorelease];
}

-(id)init {
	if(![super init])
		return nil;

	return self;
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

-(NSArray *)subCategoriesForCategory:(NSDictionary *)aCategory {
	NSArray *relevantSubCategories = [[self subcategories] filteredArrayUsingPredicate:[self createRelevantSubCategoryFilterForCategory:aCategory]];
	return (relevantSubCategories == nil) ? [NSArray array] : relevantSubCategories;
}

-(NSPredicate *)createRelevantSubCategoryFilterForCategory:(NSDictionary *)aCategory {
	if(IsEmpty([self categories]) || IsEmpty([self subcategories]) || aCategory == nil)
		return [NSPredicate predicateWithValue:YES];
	
	return [NSPredicate predicateWithFormat:@"Category.id = %@", [aCategory objectForKey:@"id"]];
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

/* 
 * This method is called to build the list of known albums and after an album is 
 * added or deleted.  See the workaround below.
 */
-(void)buildAlbumListWithCallback:(SEL)callback {
	SMRequest *req = [self createRequest];

	/*
	 * If we add or delete an album and then refresh the list using this method,
	 * we occaisonally get a list returned that includes the deleted album or 
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

-(void)initializeAlbumsFromResponse:(id)response {
	NSMutableArray *returnedAlbums = [NSMutableArray arrayWithArray:[response objectForKey:@"Albums"]];
	[returnedAlbums sortUsingSelector:@selector(compareByAlbumId:)];
	
	[self performSelectorOnMainThread:@selector(setAlbums:)	
							   withObject:[NSArray arrayWithArray:returnedAlbums] waitUntilDone:false];	
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
		   albumWithID:(NSString *)albumId 
			  caption:(NSString *)caption
			  keywords:(NSArray *)keywords {
	
	SMRequest *uploadRequest = [self createRequest];
	[self setLastUploadRequest:uploadRequest];
	[uploadRequest uploadImageData:imageData
						  filename:filename
						 sessionId:[self sessionID]
						   albumID:albumId
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
	[[self delegate] uploadDidSucceeed:[args objectAtIndex:0] imageId:[args objectAtIndex:1]];
}

-(void)uploadSucceeded:(SMRequest *)request {
	[self performSelectorOnMainThread:@selector(notifyDelegateOfUploadSuccess:)
						   withObject:[NSArray arrayWithObjects:[request imageData], [[[request decodedResponse] objectForKey:@"Image"] objectForKey:@"id"],  nil]
						waitUntilDone:NO];
}

-(void)stopUpload {
	[[self lastUploadRequest] cancelUpload];
}

#pragma mark Misc SM Info Methods

-(void)fetchImageUrls:(NSString *)imageId {
	[self getImageUrlsWithCallback:@selector(getImageUrlsDidComplete:) imageId:imageId];
}

-(void)getImageUrlsWithCallback:(SEL)callback imageId:(NSString *)imageId {
	SMRequest *req = [self createRequest];
	[req invokeMethodWithURL:[self baseRequestUrl]
						 keys:[NSArray arrayWithObjects:@"method", @"SessionID", @"ImageID", nil]
					   values:[NSArray arrayWithObjects:@"smugmug.images.getURLs", [self sessionID], imageId, nil]
			 responseCallback:callback
			   responseTarget:self];
}

-(void)getImageUrlsDidComplete:(SMRequest *)req {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[[req requestDict] objectForKey:@"ImageID"] forKey:@"ImageID"];

	if([self requestWasSuccessful:req])
		[dict setObject:[[req decodedResponse] objectForKey:@"Image"] forKey:@"Urls"];

	[self performSelectorOnMainThread:@selector(notifyDelegateOfFetchImageUrlCompletion:)
						   withObject:dict
						waitUntilDone:NO];
}

-(void)notifyDelegateOfFetchImageUrlCompletion:(NSDictionary *)args {
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(imageUrlFetchDidCompleteForImageId:imageUrls:)])
		[[self delegate] imageUrlFetchDidCompleteForImageId:[args objectForKey:@"ImageID"]
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

-(NSDictionary *)createNullSubcategory {
	return [NSDictionary dictionaryWithObjectsAndKeys:@"None", @"Title",
		@"0", @"id", nil];
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
-(void)deleteAlbum:(NSString *)albumId {
	if(![self isLoggedIn] || IsEmpty(albumId) ) {
	    NSBeep();
		NSLog(@"Cannot delete an album without a title");
		return;
	}
	
	[self deleteAlbumWithCallback:@selector(albumDeleteDidEnd:) albumId:albumId];
}

-(void)deleteAlbumWithCallback:(SEL)callback albumId:(NSString *)albumId {
	SMRequest *req = [self createRequest];
	[req invokeMethodWithURL:[self baseRequestUrl]
						  keys:[NSArray arrayWithObjects:@"method", @"SessionID", @"AlbumID", nil]
						values:[NSArray arrayWithObjects:@"smugmug.albums.delete", [self sessionID], albumId, nil]
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

-(NSDictionary *)resovleNewAlbumPreferenceKeys:(NSDictionary *)smePrefs {
	NSMutableDictionary *returnDict = [NSMutableDictionary dictionary];
	NSArray *prefKeys = [NSArray arrayWithObjects: IsPublicPref,ShowFilenamesPref,AllowCommentsPref,AllowExternalLinkingPref,DisplayEXIFInfoPref,EnableEasySharePref,AllowPurchasingPref,AllowOriginalsToBeViewedPref,AllowFriendsToEditPref,AlbumDescriptionPref,AlbumKeywordsPref,nil];
	NSEnumerator *keyEnumerator = [prefKeys objectEnumerator];
	NSString *thisKey;
	while(thisKey = [keyEnumerator nextObject]) {
		if(!IsEmpty([smePrefs objectForKey:thisKey])) {
			[returnDict setObject:[smePrefs objectForKey:thisKey]
						   forKey:[self smugMugNewAlbumKeyForPref:thisKey]];
		}
	}
	
	return [NSDictionary dictionaryWithDictionary:returnDict];
}

-(void)createNewAlbumWithCategory:(NSString *)categoryId subcategory:(NSString *)subCategoryId title:(NSString *)title albumProperties:(NSDictionary *)newAlbumProperties {
		
	// don't try to create an album if we're not logged in
	if(![self isLoggedIn])
		[self performSelectorOnMainThread:@selector(notifyDelegateOfAlbumCompletion:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
	else {
		[self createNewAlbumCallback:@selector(newAlbumCreationDidComplete:) withCategory:categoryId subcategory:subCategoryId  title:title albumProperties:newAlbumProperties];
	}
}

-(NSDictionary *)smNewAlbuMKeysForNewAlbumPrefs:(NSDictionary *)newAlbumProps {
	NSMutableDictionary *returnDict = [NSMutableDictionary dictionaryWithCapacity:[[newAlbumProps allKeys] count]];
	
	NSEnumerator *keyEnumerator = [newAlbumProps keyEnumerator];
	NSString *aKey;
	while(aKey = [keyEnumerator nextObject])
		if([self smugMugNewAlbumKeyForPref:aKey] != nil)
			[returnDict setObject:[newAlbumProps objectForKey:aKey] forKey:[self smugMugNewAlbumKeyForPref:aKey]];

	return returnDict;
}

-(void)createNewAlbumCallback:(SEL)callback withCategory:(NSString *)categoryId subcategory:(NSString *)subCategoryId title:(NSString *)title albumProperties:(NSDictionary *)properties {
	
	SMRequest *req = [self createRequest];
	NSMutableDictionary *newAlbumProperties = [NSMutableDictionary dictionaryWithDictionary:[self smNewAlbuMKeysForNewAlbumPrefs:properties]];
	
	[newAlbumProperties setObject:@"smugmug.albums.create" forKey:@"method"];
	[newAlbumProperties setObject:categoryId forKey:@"CategoryID"];
	[newAlbumProperties setObject:subCategoryId forKey:@"SubCategoryID"];
	[newAlbumProperties setObject:[self sessionID] forKey:@"SessionID"];
	[newAlbumProperties setObject:title forKey:@"Title"];
	
	[req invokeMethodWithURL:[self baseRequestUrl]
						  keys:[newAlbumProperties allKeys]
					 valueDict:newAlbumProperties
			  responseCallback:callback
				responseTarget:self];
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

@end
