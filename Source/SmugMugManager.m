//
//  SmugMugManager.m
//  SmugMugExport
//
//  Created by Aaron Evans on 10/7/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import "SmugMugManager.h"
#import "NSDataAdditions.h"
#import "RESTCall.h"

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


-(NSURL *)RESTURL;
-(NSURL *)RESTUploadURL;

-(BOOL)smResponseWasSuccessful:(RESTCall *)call;
-(void)evaluateLoginResponse:(NSXMLDocument *)d;

-(NSString *)contentTypeForPath:(NSString *)path;
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
-(void)newAlbumCreationDidComplete:(RESTCall *)rpcCall;
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
-(void)logoutCompletedNowLogin:(RESTCall *)rpcCall;
-(void)loginCompletedBuildAlbumList:(RESTCall *)rpcCall;
-(void)buildAlbumListWithCallback:(SEL)callback;
-(void)buildAlbumsListDidComplete:(RESTCall *)call;
-(void)buildCategoryListWithCallback:(SEL)callback;
-(void)categoryGetDidComplete:(RESTCall *)rpcCall;
-(void)buildSubCategoryListWithCallback:(SEL)callback;
-(void)subcategoryGetDidComplete:(RESTCall *)rpcCall;
-(void)deleteAlbumWithCallback:(SEL)callback albumId:(NSString *)albumId;

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

static NSString *AlbumId = @"AlbumID";

@interface NSDictionary (SMAdditions)
-(NSComparisonResult)compareByAlbumId:(NSDictionary *)aDict;
@end

@implementation NSDictionary (SMAdditions)
-(NSComparisonResult)compareByAlbumId:(NSDictionary *)aDict {
	
	if([self objectForKey:AlbumId] == nil)
		return NSOrderedAscending;
	
	if([aDict objectForKey:AlbumId] == nil)
		return NSOrderedDescending;
		
	return [[aDict objectForKey:AlbumId] intValue] - [[self objectForKey:AlbumId] intValue];
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

-(NSURL *)RESTURL {
	return [NSURL URLWithString:@"https://api.smugmug.com/hack/rest/1.1.1/"];
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

-(void)logoutCompletedNowLogin:(RESTCall *)call {
	if(call == nil || ([call wasSuccessful] && [self smResponseWasSuccessful:call])) {
		[self setIsLoggedIn:NO];
	}

	[self setIsLoggingIn:YES];
	[self loginWithCallback:@selector(loginCompletedBuildAlbumList:)];	
}

-(void)logout {
	[self logoutWithCallback:@selector(logoutCallback:)];
}

-(void)loginCompletedBuildAlbumList:(RESTCall *)call {
	if ([self smResponseWasSuccessful:call]) {
		[self evaluateLoginResponse:[call document]];
		[self buildAlbumListWithCallback:@selector(buildAlbumsListDidComplete:)];
	} else {
		[self setIsLoggedIn:NO];
		[self setIsLoggingIn:NO];
		[self performSelectorOnMainThread:@selector(notifyDelegateOfLoginCompleted:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
	}

	
}

-(void)evaluateLoginResponse:(NSXMLDocument *)d {
	NSXMLElement *root = [d rootElement];
	NSError *error = nil;
	NSString *sessId = [[[root nodesForXPath:@"//Login/SessionID" error:&error] objectAtIndex:0] stringValue];
	NSString *passHash = [[[root nodesForXPath:@"//Login/PasswordHash" error:&error] objectAtIndex:0] stringValue];
	NSString *uid = [[[root nodesForXPath:@"//Login/UserID" error:&error] objectAtIndex:0] stringValue];
				
	NSAssert(sessId != nil && passHash != nil && uid != nil, NSLocalizedString(@"Unexpected XML response for login", @"Error string when the xml returned by the login method is malformed."));
	[self setSessionID:sessId];
	[self setPasswordHash:passHash];
	[self setUserID:uid];
}

-(void)buildAlbumListWithCallback:(SEL)callback {
	RESTCall *call = [RESTCall RESTCall];
	[call invokeMethodWithURL:[self RESTURL] 
						  keys:[NSArray arrayWithObjects:@"method", @"SessionID", nil]
						values:[NSArray arrayWithObjects:@"smugmug.albums.get", [self sessionID], nil]
			  responseCallback:callback
				responseTarget:self];
}

/*
 <?xml version="1.0" encoding="utf-8"?>
 <rsp stat="ok">
 <method>smugmug.albums.get</method>
 <Albums>
	 <Album id="1973549">
		 <Title>Our Wedding</Title>
		 <Category id="23">
			<Title>Weddings</Title>
		 </Category>
	 </Album>
	 <Album id="1986684">
		 <Title>Molly &amp; Tom's Wedding</Title>
		 <Category id="23">
			<Title>Weddings</Title>
		 </Category>
	 </Album>
	 <Album id="1884785">
		 <Title>honeymoon</Title>
		 <Category id="33">
			<Title>Vacation</Title>
		 </Category>
	 </Album>
 </Albums>
 </rsp>
 */
-(void)initializeAlbumsFromResponse:(NSXMLDocument *)doc {

	/*
	 int "AlbumID"
	 String "Title"
	 String "Category"
	 int "CategoryID"
	 String "SubCategory" optional
	 int "SubCategoryID" optional
	 */
	NSXMLElement *root = [doc rootElement];
	NSError *error = nil;
	NSArray *albumNodes = [root nodesForXPath:@"//Albums/Album" error:&error ];
	NSXMLNode *node;
	NSEnumerator *nodeEnumertor = [albumNodes objectEnumerator];
	NSMutableArray *returnedAlbums = [NSMutableArray array];
	while(node = [nodeEnumertor nextObject]) {
		NSXMLNode *albumAttr = [(NSXMLElement *)node attributeForName:@"id"];
		NSString *albumId = [albumAttr stringValue];
		NSString *albumTitle = [[[(NSXMLElement *)node elementsForName:@"Title"] objectAtIndex:0] stringValue];

		NSAssert(albumId != nil && albumTitle != nil, NSLocalizedString(@"Unexpected XML response for album get", @"Error string when the xml returned by the album get method is malformed."));
		
		[returnedAlbums addObject:[NSDictionary dictionaryWithObjectsAndKeys:albumId, @"AlbumID", albumTitle, @"Title", nil]];
	}
	
	[returnedAlbums sortUsingSelector:@selector(compareByAlbumId:)];
	[self performSelectorOnMainThread:@selector(setAlbums:)	withObject:[NSArray arrayWithArray:returnedAlbums] waitUntilDone:false];
}

-(void)notifyDelegateOfLoginCompleted:(NSNumber *)wasSuccessful {
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(loginDidComplete:)])
		[[self delegate] loginDidComplete:[wasSuccessful boolValue]];
}

-(void)buildAlbumsListDidComplete:(RESTCall *)call {

	if([self smResponseWasSuccessful:call])
		[self initializeAlbumsFromResponse:[call document]];

	[self setIsLoggingIn:NO];
	[self setIsLoggedIn:YES];

	[self performSelectorOnMainThread:@selector(notifyDelegateOfLoginCompleted:) withObject:[NSNumber numberWithBool:[self smResponseWasSuccessful:call]] waitUntilDone:NO];
}

-(void)loginWithCallback:(SEL)loginDidEndSelector {
	[self setIsLoggingIn:YES];
	RESTCall *call = [RESTCall RESTCall];

	[call invokeMethodWithURL:[self RESTURL] 
						  keys:[NSArray arrayWithObjects:@"method", @"EmailAddress",@"Password", @"APIKey", nil]
						values:[NSArray arrayWithObjects:@"smugmug.login.withPassword", [self username], [self password], [self apiKey], nil]
			  responseCallback:loginDidEndSelector
				responseTarget:self];
}

-(BOOL)smResponseWasSuccessful:(RESTCall *)call {
	if(![call wasSuccessful])
		return NO;

	NSXMLElement *root = [[call document] rootElement];
	return [[[root attributeForName:@"stat"] stringValue] isEqualToString:@"ok"];
}

-(void)loginCompleted:(RESTCall *)call {
	if([self smResponseWasSuccessful:call]) {
		[self evaluateLoginResponse:[call document]];
	}
}

-(void)logoutWithCallback:(SEL)logoutDidEndSelector {
	if([self sessionID] == nil || ![self isLoggedIn]) {
		[self performSelectorOnMainThread:logoutDidEndSelector withObject:nil waitUntilDone:NO];
		return;
	}

	RESTCall *call = [RESTCall RESTCall];	
	[call invokeMethodWithURL:[self RESTURL] 
						  keys:[NSArray arrayWithObjects:@"method", @"SessionID", nil]
						values:[NSArray arrayWithObjects:@"smugmug.logout", [self sessionID], nil]
			  responseCallback:logoutDidEndSelector
				responseTarget:self];
}

-(void)notifyDelegaeOfLogout:(NSNumber *)wasSuccessful {
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(logoutDidComplete:)])
		[[self delegate] logoutDidComplete:[wasSuccessful boolValue]];
}

-(void)logoutCallback:(RESTCall *)call {

	[self setIsLoggedIn:NO];

	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(logoutDidComplete:)])
		[[self delegate] performSelectorOnMainThread:@selector(logoutDidComplete:) withObject:[NSNumber numberWithBool:[self smResponseWasSuccessful:call]] waitUntilDone:NO];
}

#pragma mark Misc SM Info Methods

-(void)buildCategoryList {
	[self buildCategoryListWithCallback:@selector(categoryGetDidComplete:)];
}

-(void)buildCategoryListWithCallback:(SEL)callback {
	RESTCall *call = [RESTCall RESTCall];
	[call invokeMethodWithURL:[self RESTURL]
						  keys:[NSArray arrayWithObjects:@"method", @"SessionID", nil]
						values:[NSArray arrayWithObjects:@"smugmug.categories.get", [self sessionID], nil]
			  responseCallback:callback
				responseTarget:self];
}

-(void)initializeCategoriesWithDocument:(NSXMLDocument *)doc {
	NSXMLElement *root = [doc rootElement];
	NSError *error = nil;
	NSArray *categoryNodes = [root nodesForXPath:@"//Categories/Category" error:&error ];

	NSXMLNode *node;
	NSEnumerator *nodeEnumertor = [categoryNodes objectEnumerator];
	NSMutableArray *returnedCategories = [NSMutableArray array];
	while(node = [nodeEnumertor nextObject]) {
		NSString *categoryId = [[(NSXMLElement *)node attributeForName:@"id"] stringValue];
		NSString *categoryTitle = [[[(NSXMLElement *)node elementsForName:@"Title"] objectAtIndex:0] stringValue];

		NSAssert(categoryId != nil && categoryTitle != nil, NSLocalizedString(@"Unexpected XML response for category get", @"Error string when the xml returned by the category get method is malformed."));

		[returnedCategories addObject:[NSDictionary dictionaryWithObjectsAndKeys:categoryId, @"CategoryID", categoryTitle, @"Title", nil]];
	}

	[self performSelectorOnMainThread:@selector(setCategories:)	withObject:[NSArray arrayWithArray:returnedCategories] waitUntilDone:false];
}

-(void)categoryGetDidComplete:(RESTCall *)call {
	if([self smResponseWasSuccessful:call])
		[self initializeCategoriesWithDocument:[call document]];
	
}

-(void)buildSubCategoryList {
	[self buildSubCategoryListWithCallback:@selector(subcategoryGetDidComplete:)];
}

-(void)buildSubCategoryListWithCallback:(SEL)callback {
	RESTCall *call = [RESTCall RESTCall];
	[call invokeMethodWithURL:[self RESTURL]
						  keys:[NSArray arrayWithObjects:@"method", @"SessionID", nil]
						values:[NSArray arrayWithObjects:@"smugmug.subcategories.getAll", [self sessionID], nil]
			  responseCallback:callback
				responseTarget:self];
}

-(void)initializeSubcategoriesWithDocument:(NSXMLDocument *)doc {
	NSXMLElement *root = [doc rootElement];
	NSError *error = nil;
	NSArray *subcategoryNodes = [root nodesForXPath:@"//SubCategories/SubCategory" error:&error ];

	NSXMLNode *node;
	NSEnumerator *nodeEnumertor = [subcategoryNodes objectEnumerator];
	NSMutableArray *returnedSubCategories = [NSMutableArray array];
	while(node = [nodeEnumertor nextObject]) {
		NSString *categoryId = [[(NSXMLElement *)node attributeForName:@"id"] stringValue];
		NSString *categoryTitle = [[[(NSXMLElement *)node elementsForName:@"Title"] objectAtIndex:0] stringValue];
			
		NSAssert(categoryId != nil && categoryTitle != nil, NSLocalizedString(@"Unexpected XML response for category get", @"Error string when the xml returned by the subcategory get method is malformed."));
		
		[returnedSubCategories addObject:[NSDictionary dictionaryWithObjectsAndKeys:categoryId, @"CategoryID", categoryTitle, @"Title", nil]];
	}

	[self performSelectorOnMainThread:@selector(setSubcategories:)	withObject:[NSArray arrayWithArray:returnedSubCategories] waitUntilDone:false];	
}

-(void)subcategoryGetDidComplete:(RESTCall *)call {
	if([self smResponseWasSuccessful:call])
		[self initializeSubcategoriesWithDocument:[call document]];
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
	RESTCall *call = [RESTCall RESTCall];
	[call invokeMethodWithURL:[self RESTURL]
						  keys:[NSArray arrayWithObjects:@"method", @"SessionID", @"AlbumID", nil]
						values:[NSArray arrayWithObjects:@"smugmug.albums.delete", [self sessionID], albumId, nil]
			  responseCallback:callback
				responseTarget:self];
}

-(void)notifyDelegateOfAlbumSyncCompletion:(NSNumber *)wasSuccessful {
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(deleteAlbumDidComplete:)])
		[[self delegate] deleteAlbumDidComplete:[wasSuccessful boolValue]];	
}

-(void)notifyDelegateOfAlbumCompletion:(NSNumber *)wasSuccessful {
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(createNewAlbumDidComplete:)])
		[[self delegate] createNewAlbumDidComplete:[wasSuccessful boolValue]];
}

-(void)albumDeleteDidEnd:(RESTCall *)call {
	if([self smResponseWasSuccessful:call]) {
		[self buildAlbumListWithCallback:@selector(postAlbumDeleteAlbumSyncDidComplete:)];
	} else {
		[self notifyDelegateOfAlbumCompletion:[NSNumber numberWithBool:NO]];
	}
}

-(void)postAlbumDeleteAlbumSyncDidComplete:(RESTCall *)call {

	if([self smResponseWasSuccessful:call])
		[self initializeAlbumsFromResponse:[call document]];

	[self notifyDelegateOfAlbumSyncCompletion:[NSNumber numberWithBool:[self smResponseWasSuccessful:call]]];
}

#pragma mark New Album Creation Methods

-(void)createNewAlbum {
	
	// don't try to create an album if we're not logged in or there is no album title
	if(![self isLoggedIn] || IsEmpty([[self newAlbumPreferences] objectForKey:AlbumTitlePref]))
		[self performSelectorOnMainThread:@selector(notifyDelegateOfAlbumCompletion:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
	else
		[self createNewAlbumCallback:@selector(newAlbumCreationDidComplete:)];
}

-(void)createNewAlbumCallback:(SEL)callback {
	RESTCall *call = [RESTCall RESTCall];
	
	int selectedCategoryIndex = [selectedCategoryIndices firstIndex];
	NSDictionary *basicNewAlbumPrefs = [self newAlbumOptionalPrefDictionary];
	NSMutableDictionary *newAlbumProerties = [NSMutableDictionary dictionaryWithDictionary:basicNewAlbumPrefs];
	[newAlbumProerties setObject:[[[self categories] objectAtIndex:selectedCategoryIndex] objectForKey:@"CategoryID"]
						  forKey:@"CategoryID"];
	[newAlbumProerties setObject:@"smugmug.albums.create" forKey:@"method"];
	[newAlbumProerties setObject:[self sessionID] forKey:@"SessionID"];
	[newAlbumProerties setObject:[[self newAlbumPreferences] objectForKey:AlbumTitlePref] forKey:@"Title"];
	NSMutableArray *orderedKeys = [NSMutableArray arrayWithObjects:@"method", @"SessionID", @"Title", @"CategoryID", nil];
	[orderedKeys addObjectsFromArray:[basicNewAlbumPrefs allKeys]];

	[call invokeMethodWithURL:[self RESTURL]
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

-(void)newAlbumCreationDidComplete:(RESTCall *)call {

	if([self smResponseWasSuccessful:call])
		[self buildAlbumListWithCallback:@selector(postAlbumCreateAlbumSyncDidComplete:)];
	else {
		[self performSelectorOnMainThread:@selector(notifyDelegateOfAlbumCompletion:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
	}
}


-(void)postAlbumCreateAlbumSyncDidComplete:(RESTCall *)call {
	if([self smResponseWasSuccessful:call])
		[self initializeAlbumsFromResponse:[call document]];

	[self performSelectorOnMainThread:@selector(notifyDelegateOfAlbumCompletion:) withObject:[NSNumber numberWithBool:[self smResponseWasSuccessful:call]] waitUntilDone:NO];
}

-(void)clearAlbumCreationState {
	[[self newAlbumPreferences] removeObjectForKey:AlbumTitlePref];
	[[self newAlbumPreferences] removeObjectForKey:AlbumDescriptionPref];
	[[self newAlbumPreferences] removeObjectForKey:AlbumKeywordsPref];
}

#pragma mark Upload Methods

-(void)uploadImageAtPath:(NSString *)path albumWithID:(NSString *)albumId caption:(NSString *)caption {
	
	NSData *postData = [self postBodyForImageAtPath:path albumId:albumId caption:caption];

	CFHTTPMessageRef myRequest;
	myRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("POST"), (CFURLRef)[NSURL URLWithString:[self postUploadURL]], kCFHTTPVersion1_1);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("Content-Type"), (CFStringRef)[NSString stringWithFormat:@"multipart/form-data; boundary=%@", Boundary]);
	CFHTTPMessageSetHeaderFieldValue(myRequest, CFSTR("User-Agent"), (CFStringRef)UserAgent);
	
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
	NSTimer *uploadProgressTimer  = [NSTimer timerWithTimeInterval:0.125 target:self selector:@selector(trackUploadProgress:) userInfo:nil repeats:YES];

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
	   [[self delegate] respondsToSelector:@selector(uploadMadeProgressForFile:bytesWritten:totalBytes:)])
		[[self delegate] uploadMadeProgressForFile:[args objectAtIndex:0] bytesWritten:[[args objectAtIndex:1] longValue] totalBytes:[[args objectAtIndex:2] longValue]];
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
	NSString *error = [args count] > 1 ? [args objectAtIndex:1] : nil;
	
	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(uploadDidCompleteForFile:withError:)])
		[[self delegate] uploadDidCompleteForFile:[args objectAtIndex:0] withError:error];
}

-(void)stopUpload {
	NSArray *args = [NSArray arrayWithObjects:currentPathForUpload, NSLocalizedString(@"Upload was cancelled.", @"Error strinng for cancelled upload"), nil];
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

//	NSError *error = nil;
//	NSXMLDocument *response = [[[NSXMLDocument alloc] initWithData:[self responseData] options:0 error:&error] autorelease];
	NSString *errorString = nil;
	// TODO get an error string (if it exists) from the response

	NSMutableArray *args = [NSMutableArray arrayWithObject:currentPathForUpload];
	if(errorString != nil)
		[args addObject:errorString];

	[self performSelectorOnMainThread:@selector(notifyDelegateOfUploadCompletion:) withObject:args waitUntilDone:NO];
	[self destroyUploadResources];
}

-(void)notifyDelegateOfUploadError:(NSArray *)args {
	NSString *error = [args count] > 1 ? [args objectAtIndex:1] : nil;

	if([self delegate] != nil &&
	   [[self delegate] respondsToSelector:@selector(uploadDidCompleteForFile:withError:)]) {
		[[self delegate] uploadDidCompleteForFile:[args objectAtIndex:0] withError:error];
	}	
}

-(void)errorOccurred {
	NSArray *args = [NSArray arrayWithObjects:currentPathForUpload, NSLocalizedString(@"Upload Failed", @"The upload was interrupted in progress."), nil];
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
