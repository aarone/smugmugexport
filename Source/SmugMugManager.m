//
//  SmugMugManager.m
//  SmugMugExport
//
//  Created by Aaron Evans on 10/7/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import "SmugMugManager.h"
#import "NSDataAdditions.h"
#import "JSONRequest.h"
#import "Globals.h"
#import "SmugMugAccess.h"
#import "NSUserDefaultsAdditions.h"
#import <QuartzCore/CIImage.h>

static const CFOptionFlags DAClientNetworkEvents = 
kCFStreamEventOpenCompleted     |
kCFStreamEventHasBytesAvailable |
kCFStreamEventEndEncountered    |
kCFStreamEventErrorOccurred;

@interface SmugMugManager (Private)
-(NSString *)sessionID;
-(void)setSessionID:(NSString *)anID;
-(NSString *)apiKey;
-(NSString *)appName;
-(NSString *)userID;
-(void)setAlbums:(NSArray *)a;
-(void)setUserID:(NSString *)anID;
-(NSString *)passwordHash;
-(void)setPasswordHash:(NSString *)p;


-(NSURL *)SmugMugAccessURL;

-(BOOL)smResponseWasSuccessful:(SmugMugAccess *)req;
-(void)evaluateLoginResponse:(id)response;

-(NSString *)contentTypeForPath:(NSString *)path;
-(NSData *)postBodyForImageAtPath:(NSString *)path 
						  albumId:(NSString *)albumId 
							title:(NSString *)title 
						 comments:(NSString *)comments 
						 keywords:(NSArray *)keywords 
						  caption:(NSString *)caption;
-(void)appendToResponse;
-(void)transferComplete;

-(NSString *)domainStringForError:(CFStreamError *)err;
-(void)errorOccurred:(CFStreamError *)err;
	
-(NSString *)postUploadURL;
-(void)setIsLoggingIn:(BOOL)v;
-(void)setIsLoggedIn:(BOOL)v;
-(NSDictionary *)defaultNewAlbumPreferences;
-(NSDictionary *)selectedCategory;
-(void)setSelectedCategory:(NSDictionary *)d;
-(void)createNewAlbum;
-(void)createNewAlbumCallback:(SEL)callback;
-(void)newAlbumCreationDidComplete:(SmugMugAccess *)req;
-(void)destroyUploadResources;

-(NSMutableData *)responseData;
-(void)setResponseData:(NSMutableData *)d;
-(void)setCategories:(NSArray *)categories;
-(void)setSubcategories:(NSArray *)anArray;

-(NSMutableDictionary *)newAlbumPreferences;
-(void)setNewAlbumPreferences:(NSMutableDictionary *)a;
-(NSDictionary *)newAlbumOptionalPrefDictionary;

-(void)loginWithCallback:(SEL)loginDidEndSelector;
-(void)logoutWithCallback:(SEL)logoutDidEndSelector;
-(void)logoutCompletedNowLogin:(SmugMugAccess *)req;
-(void)loginCompletedBuildAlbumList:(SmugMugAccess *)req;
-(void)buildAlbumListWithCallback:(SEL)callback;
-(void)buildAlbumsListDidComplete:(SmugMugAccess *)req;
-(void)buildCategoryListWithCallback:(SEL)callback;
-(void)categoryGetDidComplete:(SmugMugAccess *)req;
-(void)buildSubCategoryListWithCallback:(SEL)callback;
-(void)subcategoryGetDidComplete:(SmugMugAccess *)req;
-(void)deleteAlbumWithCallback:(SEL)callback albumId:(NSString *)albumId;
-(void)getImageUrlsWithCallback:(SEL)callback imageId:(NSString *)imageId;
-(void)getImageUrlsDidComplete:(SmugMugAccess *)req;

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
		case kCFStreamEventErrorOccurred: {
			CFStreamError err = CFReadStreamGetError(stream);
			[(SmugMugManager *)clientCallBackInfo errorOccurred:&err];
			break;
		} default:
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

double UploadProgressTimerInterval = 0.125/2.0;
static const NSTimeInterval AlbumRefreshDelay = 1.0;

@interface NSDictionary (SMAdditions)
-(NSComparisonResult)compareByAlbumId:(NSDictionary *)aDict;
@end

@implementation NSDictionary (SMAdditions)
-(NSComparisonResult)compareByAlbumId:(NSDictionary *)aDict {
	
	if([self objectForKey:AlbumID] == nil)
		return NSOrderedAscending;
	
	if([aDict objectForKey:AlbumID] == nil)
		return NSOrderedDescending;
		
	return [[aDict objectForKey:AlbumID] intValue] - [[self objectForKey:AlbumID] intValue];
}

-(NSComparisonResult)compareByTitle:(NSDictionary *)aDict {
	return [[self objectForKey:@"Title"] caseInsensitiveCompare:[aDict objectForKey:@"Title"]];
}
@end

@implementation SmugMugManager

+(SmugMugManager *)smugmugManager {
	return [[[[self class] alloc] init] autorelease];
}

-(id)init {
	if(![super init])
		return nil;

	[self setNewAlbumPreferences:[NSMutableDictionary dictionaryWithDictionary:[self defaultNewAlbumPreferences]]]; 
	
	return self;
}

-(void)dealloc {

	[[self newAlbumPreferences] release];
	[[self categories] release];
	[[self albums] release];
	[[self password] release];
	[[self username] release];
	[[self sessionID] release];
	[[self subcategories] release];
	[[self selectedCategory] release];

	[super dealloc];
}

-(Class)storeAccessClass {
	return [JSONRequest class];
}

#pragma mark Miscellaneous Get/Set Methods
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

-(NSArray *)albums {
	return albums;
}

-(void)setAlbums:(NSArray *)a {
	if(albums != nil) {
		[[self albums] release];
	}
	albums = [a retain];
}

-(NSString *)apiKey {
	return @"98LHI74dS6P0A8cQ1M6h0R1hXsbIPDXc";
}

-(NSString *)appName {
	return @"SmugMugExport";
}

-(NSURL *)SmugMugAccessURL {
	return [NSURL URLWithString:@"https://api.smugmug.com/hack/json/1.2.0/"];
}

-(NSString *)postUploadURL {
	return @"http://upload.SmugMug.com/photos/xmladd.mg";
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

-(void)logoutCompletedNowLogin:(SmugMugAccess *)req {
	if(req == nil || ([req wasSuccessful] && [self smResponseWasSuccessful:req])) {
		[self setIsLoggedIn:NO];
	}

	[self setIsLoggingIn:YES];
	[self loginWithCallback:@selector(loginCompletedBuildAlbumList:)];	
}

-(void)logout {
	[self logoutWithCallback:@selector(logoutCallback:)];
}

-(void)loginCompletedBuildAlbumList:(SmugMugAccess *)req {
	if ([self smResponseWasSuccessful:req]) {
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
	SmugMugAccess *req = [[self storeAccessClass] request];

	/*
	 * If we add or delete an album and then refresh the list using this method,
	 * we occaisonally get a list returned that includes the deleted album or 
	 * doesn't include the album that was just added.  My suspicion is that this
	 * is because I'm refreshing the list too quickly after modifying the album
	 * list.  To workaround this, we insert a delay here and hope for the best.
	 */
	if(EnableAlbumFetchDelay())
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:AlbumRefreshDelay]];
	
	[req invokeMethodWithURL:[self SmugMugAccessURL] 
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

-(void)buildAlbumsListDidComplete:(SmugMugAccess *)req {

	if([self smResponseWasSuccessful:req])
		[self initializeAlbumsFromResponse:[req decodedResponse]];

	[self setIsLoggingIn:NO];
	[self setIsLoggedIn:YES];

	[self performSelectorOnMainThread:@selector(notifyDelegateOfLoginCompleted:) withObject:[NSNumber numberWithBool:[self smResponseWasSuccessful:req]] waitUntilDone:NO];
}

-(void)loginWithCallback:(SEL)loginDidEndSelector {
	[self setIsLoggingIn:YES];
	SmugMugAccess *request = [[self storeAccessClass] request];

	[request invokeMethodWithURL:[self SmugMugAccessURL] 
						  keys:[NSArray arrayWithObjects:@"method", @"EmailAddress",@"Password", @"APIKey", nil]
						values:[NSArray arrayWithObjects:@"smugmug.login.withPassword", [self username], [self password], [self apiKey], nil]
			  responseCallback:loginDidEndSelector
				responseTarget:self];
}

-(BOOL)smResponseWasSuccessful:(SmugMugAccess *)req {
	if(![req wasSuccessful])
		return NO;
	
	return [[[req decodedResponse] objectForKey:@"stat"] isEqualToString:@"ok"];
}

-(void)loginCompleted:(SmugMugAccess *)req {
	if([self smResponseWasSuccessful:req]) {
		[self evaluateLoginResponse:[req decodedResponse]];
	}
}

-(void)logoutWithCallback:(SEL)logoutDidEndSelector {
	if([self sessionID] == nil || ![self isLoggedIn]) {
		[self performSelectorOnMainThread:logoutDidEndSelector withObject:nil waitUntilDone:NO];
		return;
	}

	SmugMugAccess *req = [[self storeAccessClass] request];	
	[req invokeMethodWithURL:[self SmugMugAccessURL] 
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

-(void)logoutCallback:(SmugMugAccess *)req {

	[self setIsLoggedIn:NO];

	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(logoutDidComplete:)])
		[[self delegate] performSelectorOnMainThread:@selector(logoutDidComplete:) withObject:[NSNumber numberWithBool:[self smResponseWasSuccessful:req]] waitUntilDone:NO];
}

#pragma mark Misc SM Info Methods

-(void)fetchImageUrls:(NSString *)imageId {
	[self getImageUrlsWithCallback:@selector(getImageUrlsDidComplete:) imageId:imageId];
}

-(void)getImageUrlsWithCallback:(SEL)callback imageId:(NSString *)imageId {
	SmugMugAccess *req = [[self storeAccessClass] request];
	[req invokeMethodWithURL:[self SmugMugAccessURL]
						 keys:[NSArray arrayWithObjects:@"method", @"SessionID", @"ImageID", nil]
					   values:[NSArray arrayWithObjects:@"smugmug.images.getURLs", [self sessionID], imageId, nil]
			 responseCallback:callback
			   responseTarget:self];
}

-(void)getImageUrlsDidComplete:(SmugMugAccess *)req {
	if([self smResponseWasSuccessful:req]) {
		NSDictionary *dict = [[req decodedResponse] objectForKey:@"Image"];
		 
		if([self delegate] != nil &&
			[[self delegate] respondsToSelector:@selector(imageUrlFetchDidComplete:)])
			[[self delegate] performSelectorOnMainThread:@selector(imageUrlFetchDidComplete:) withObject:dict waitUntilDone:NO];
	}
}

-(void)buildCategoryList {
	[self buildCategoryListWithCallback:@selector(categoryGetDidComplete:)];
}

-(void)buildCategoryListWithCallback:(SEL)callback {
	SmugMugAccess *req = [[self storeAccessClass] request];
	[req invokeMethodWithURL:[self SmugMugAccessURL]
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

-(void)categoryGetDidComplete:(SmugMugAccess *)req {
	if([self smResponseWasSuccessful:req])
		[self initializeCategoriesWithResponse:[req decodedResponse]];
	
}

-(void)buildSubCategoryList {
	[self buildSubCategoryListWithCallback:@selector(subcategoryGetDidComplete:)];
}

-(void)buildSubCategoryListWithCallback:(SEL)callback {
	SmugMugAccess *req = [[self storeAccessClass] request];
	[req invokeMethodWithURL:[self SmugMugAccessURL]
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

-(void)subcategoryGetDidComplete:(SmugMugAccess *)req {
	if([self smResponseWasSuccessful:req])
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
	SmugMugAccess *req = [[self storeAccessClass] request];
	[req invokeMethodWithURL:[self SmugMugAccessURL]
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

-(void)albumDeleteDidEnd:(SmugMugAccess *)req {
	if([self smResponseWasSuccessful:req]) {
		[self buildAlbumListWithCallback:@selector(postAlbumDeleteAlbumSyncDidComplete:)];
	} else {
		[self notifyDelegateOfAlbumCompletion:[NSNumber numberWithBool:NO]];
	}
}

-(void)postAlbumDeleteAlbumSyncDidComplete:(SmugMugAccess *)req {

	if([self smResponseWasSuccessful:req])
		[self initializeAlbumsFromResponse:[req decodedResponse]];

	[self notifyDelegateOfAlbumSyncCompletion:[NSNumber numberWithBool:[self smResponseWasSuccessful:req]]];
}

#pragma mark New Album Creation Methods

-(void)createNewAlbum {
	// don't try to create an album if we're not logged in or there is no album title or if we're already trying to create an album
	if(![self isLoggedIn] || IsEmpty([[self newAlbumPreferences] objectForKey:AlbumTitlePref]))
		[self performSelectorOnMainThread:@selector(notifyDelegateOfAlbumCompletion:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
	else {
		[self createNewAlbumCallback:@selector(newAlbumCreationDidComplete:)];
	}
}

-(void)createNewAlbumCallback:(SEL)callback {
	SmugMugAccess *req = [[self storeAccessClass] request];
	
	int selectedCategoryIndex = [selectedCategoryIndices firstIndex];
	NSDictionary *basicNewAlbumPrefs = [self newAlbumOptionalPrefDictionary];
	NSMutableDictionary *newAlbumProerties = [NSMutableDictionary dictionaryWithDictionary:basicNewAlbumPrefs];
	[newAlbumProerties setObject:[[[self categories] objectAtIndex:selectedCategoryIndex] objectForKey:CategoryID]
						  forKey:@"CategoryID"];
	[newAlbumProerties setObject:@"smugmug.albums.create" forKey:@"method"];
	[newAlbumProerties setObject:[self sessionID] forKey:@"SessionID"];
	[newAlbumProerties setObject:[[self newAlbumPreferences] objectForKey:AlbumTitlePref] forKey:@"Title"];
	NSMutableArray *orderedKeys = [NSMutableArray arrayWithObjects:@"method", @"SessionID", @"Title", @"CategoryID", nil];
	[orderedKeys addObjectsFromArray:[basicNewAlbumPrefs allKeys]];

	[req invokeMethodWithURL:[self SmugMugAccessURL]
						  keys:orderedKeys
					 valueDict:newAlbumProerties
			  responseCallback:callback
				responseTarget:self];
}

-(NSDictionary *)newAlbumOptionalPrefDictionary {
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

-(void)newAlbumCreationDidComplete:(SmugMugAccess *)req {
	if([self smResponseWasSuccessful:req])
		[self buildAlbumListWithCallback:@selector(postAlbumCreateAlbumSyncDidComplete:)];
	else {
		[self performSelectorOnMainThread:@selector(notifyDelegateOfAlbumCompletion:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
	}
}


-(void)postAlbumCreateAlbumSyncDidComplete:(SmugMugAccess *)req {
	if([self smResponseWasSuccessful:req])
		[self initializeAlbumsFromResponse:[req decodedResponse]];

	[self performSelectorOnMainThread:@selector(notifyDelegateOfAlbumCompletion:) withObject:[NSNumber numberWithBool:[self smResponseWasSuccessful:req]] waitUntilDone:NO];
}

-(void)clearAlbumCreationState {
	[[self newAlbumPreferences] removeObjectForKey:AlbumTitlePref];
	[[self newAlbumPreferences] removeObjectForKey:AlbumDescriptionPref];
	[[self newAlbumPreferences] removeObjectForKey:AlbumKeywordsPref];
}

#pragma mark Upload Methods

-(void)uploadImageAtPath:(NSString *)path 
			 albumWithID:(NSString *)albumId 
				   title:(NSString *)title
				comments:(NSString *)comments
				keywords:(NSArray *)keywords
				 caption:(NSString *)caption {
	
	NSData *postData = [self postBodyForImageAtPath:path albumId:albumId title:title comments:comments keywords:keywords caption:caption];

	if(IsNetworkTracingEnabled()) {
		NSLog(@"Posting image to %@", [self postUploadURL]);
	}
	
	CFHTTPMessageRef myRequest;
	myRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("POST"), (CFURLRef)[NSURL URLWithString:[self postUploadURL]], kCFHTTPVersion1_1);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("Content-Type"), (CFStringRef)[NSString stringWithFormat:@"multipart/form-data; boundary=%@", Boundary]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("User-Agent"), (CFStringRef)[SmugMugAccess userAgent]);
	
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
	uploadSize = [postData length];
	[self setResponseData:[NSMutableData data]];

	CFReadStreamOpen(readStream);

	[NSThread detachNewThreadSelector:@selector(beingUploadProgressTracking) toTarget:self withObject:nil];
}

-(void)beingUploadProgressTracking {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSTimer *uploadProgressTimer  = [NSTimer timerWithTimeInterval:UploadProgressTimerInterval target:self selector:@selector(trackUploadProgress:) userInfo:nil repeats:YES];

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

	NSArray *args = [NSArray arrayWithObjects:currentPathForUpload, [NSNumber numberWithLong:(long)bytesWritten], [NSNumber numberWithLong:uploadSize], nil];
	[self performSelectorOnMainThread:@selector(notifyDelegateOfUploadProgress:) withObject:args waitUntilDone:NO];
	
	if(bytesWritten >= uploadSize)
		[timer invalidate];
//		isUploading = NO; // stop the timer. we're not getting any more data from the socket for this image
}

-(void)notifyDelegateOfUploadProgress:(NSArray *)args {
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(uploadMadeProgressWithArgs:)])
		[[self delegate] uploadMadeProgressWithArgs:args];
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

-(void)notifyDelegateOfUploadCompletion:(NSArray *)args {
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(uploadDidCompleteWithArgs:)])
		[[self delegate] uploadDidCompleteWithArgs:args];
}

-(void)stopUpload {
	NSArray *args = [NSArray arrayWithObjects:currentPathForUpload, [NSNull null], NSLocalizedString(@"Upload was cancelled.", @"Error strinng for cancelled upload"), nil];
	[self performSelectorOnMainThread:@selector(notifyDelegateOfUploadCompletion:) withObject:args waitUntilDone:YES];
	[self destroyUploadResources];
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
	
	CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	CFReadStreamClose(readStream);
	CFRelease(readStream);
	[self setResponseData:nil];
	[currentPathForUpload release];
}

-(void)transferComplete {

	NSError *error = nil;	
	NSXMLDocument *response = [[[NSXMLDocument alloc] initWithData:[self responseData] options:0 error:&error] autorelease];
	NSString *errorString = nil;

	NSArray *uploadedImageIds = [[response rootElement] nodesForXPath:@"//value/int" error:&error ];
	
	NSXMLNode *node;
	NSEnumerator *nodeEnumertor = [uploadedImageIds objectEnumerator];
	NSString *imageId = nil;
	while(node = [nodeEnumertor nextObject]) {
		imageId = [(NSXMLElement *)node stringValue];
		break;
	}

	NSMutableArray *args = [NSMutableArray arrayWithObjects:currentPathForUpload, imageId, nil];
	if(errorString != nil)
		[args addObject:errorString];

	[self performSelectorOnMainThread:@selector(notifyDelegateOfUploadCompletion:) withObject:args waitUntilDone:NO];
	[self destroyUploadResources];
}

-(void)notifyDelegateOfUploadError:(NSArray *)args {	
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(uploadDidCompleteWithArgs:)]) {
		[[self delegate] performSelectorOnMainThread:@selector(uploadDidCompleteWithArgs:) withObject:args waitUntilDone:NO];
	}	
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

-(void)errorOccurred: (CFStreamError *)err {
	NSString *errorText = [NSString stringWithFormat:@"%@ : %d", [self domainStringForError:err], err->error];
	NSArray *args = [NSArray arrayWithObjects:currentPathForUpload, [NSNull null], errorText, nil];
	[self performSelectorOnMainThread:@selector(notifyDelegateOfUploadError:) withObject:args waitUntilDone:NO];
	[self destroyUploadResources];
}

-(NSData *)postDataWithName:(NSString *)aName postContents:(NSString *)postContents {
	NSMutableData *data = [NSMutableData data];
	[data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", aName] dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[postContents dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",Boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	return data;
}

-(NSData *)imageDataForPath:(NSString *)pathToImage {
	
	NSString *application = nil;
	NSString *filetype = nil;
	BOOL result = [[NSWorkspace sharedWorkspace] getInfoForFile:pathToImage
													application:&application
														   type:&filetype];
	if(result == NO) {
		NSLog(@"Error getting file type for file (%@).  This image will not be exported.", pathToImage);
		return nil;
	}
	
	BOOL isJpeg = [[filetype lowercaseString] isEqual:@"jpg"];
	
	if(!isJpeg && ShouldScaleImages())
		NSLog(@"The image (%@) is not a jpeg and cannot be scaled by this program (yet).", pathToImage);
		
	if(isJpeg && ShouldScaleImages()) {
		int maxWidth = [[[NSUserDefaults smugMugUserDefaults] objectForKey:SMImageScaleWidth] intValue];
		int maxHeight = [[[NSUserDefaults smugMugUserDefaults] objectForKey:SMImageScaleHeight] intValue];

		// allow no input and treat it like infinity
		if(maxWidth == 0)
			maxWidth = INT_MAX;
		if(maxHeight == 0)
			maxHeight = INT_MAX;
		
		// we use core image (gpu) to do scaling (because it's more fun than using the cpu)
		CIImage *img = [CIImage imageWithData:[NSData dataWithContentsOfFile:pathToImage]];

		CGRect imageExtent = [img extent];
		int inputImageWidth = imageExtent.size.width;
		int inputImageHeight = imageExtent.size.height;
		
		if(inputImageWidth < maxWidth && inputImageHeight < maxHeight) {
			return [NSData dataWithContentsOfFile:pathToImage];	
		}
		
		float scaleFactor = 1.0;
		if( inputImageWidth > maxWidth || inputImageHeight > maxHeight ) {
			int heightDifferential = inputImageWidth - maxWidth;
			int widthDifferential = inputImageHeight - maxHeight;
			// scale the dimension with the greatest difference
			scaleFactor = (heightDifferential > widthDifferential) ? 
				(float)maxHeight/(float)inputImageHeight : 
				(float)maxWidth/(float)inputImageWidth;
		}
		
		NSAssert(scaleFactor > 0.0 && scaleFactor <= 1.0, @"This is a bug.  The scaling factor should never be negative.");
		
		// get the image rep
		NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:[NSData dataWithContentsOfFile:pathToImage]];
		
		// we copy the properties that relate to jpegs
		NSSet *propertiesToTransfer = [NSSet setWithObjects:NSImageEXIFData, NSImageColorSyncProfileData, 
			NSImageProgressive, nil];
		NSMutableDictionary *outgoingImageProperties = [NSMutableDictionary dictionary];
		[outgoingImageProperties setObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
		NSEnumerator *propertyEnumerator = [propertiesToTransfer objectEnumerator];
		id key;
		while(key = [propertyEnumerator nextObject]) {
			id inVal = [rep valueForProperty:key];
			if(inVal != nil)
				[outgoingImageProperties setObject:inVal forKey:key];
		}
		
		// do the scale here
		CGAffineTransform trans = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
		CIImage* outputImage = [img imageByApplyingTransform:trans];
		
		int outputWidth = [outputImage extent].size.width;
		int outputHeight = [outputImage extent].size.height;
		
		NSImage *resizedImage = [[NSImage alloc] initWithSize: NSMakeSize(outputWidth, outputHeight)];
		[resizedImage addRepresentation:[NSCIImageRep imageRepWithCIImage:outputImage]];

		NSBitmapImageRep *renderedImage = [NSBitmapImageRep imageRepWithData:[resizedImage TIFFRepresentation]];

		NSData *photoData = [renderedImage representationUsingType:NSJPEGFileType properties:outgoingImageProperties];
		[resizedImage release];
		return photoData;
	}
	
	// the default operation
	return [NSData dataWithContentsOfFile:pathToImage];	
}

-(NSData *)postBodyForImageAtPath:(NSString *)path albumId:(NSString *)albumId title:(NSString *)title
						 comments:(NSString *)comments keywords:(NSArray *)keywords caption:(NSString *)caption {
	
	NSData *imageData = [self imageDataForPath:path];
	NSAssert(imageData != nil, @"cannot create image from data");
	
	NSMutableData *postBody = [NSMutableData data];
	[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",Boundary] dataUsingEncoding:NSUTF8StringEncoding]];

	
	[postBody appendData:[self postDataWithName:@"AlbumID" postContents:albumId]];
	[postBody appendData:[self postDataWithName:@"SessionID" postContents:[self sessionID]]];
	[postBody appendData:[self postDataWithName:@"ByteCount" postContents:[NSString stringWithFormat:@"%d", [imageData length]]]];
	[postBody appendData:[self postDataWithName:@"MD5Sum" postContents:[imageData md5HexString]]];

	if(caption != nil)
		[postBody appendData:[self postDataWithName:@"Caption" postContents:caption]];
	
	// NSString *filename = [path lastPathComponent];
	NSMutableString *filename = [NSMutableString stringWithString:title];
	[filename replaceOccurrencesOfString:@"\""	withString:@"\\\"" options:0 range: NSMakeRange(0, [title length])];
	[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"Image\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Type: image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:imageData];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",Boundary] dataUsingEncoding:NSUTF8StringEncoding]];

	return postBody;
}

-(NSString *)contentTypeForPath:(NSString *)path {
	
	// is there a better way to do this?
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

@end
