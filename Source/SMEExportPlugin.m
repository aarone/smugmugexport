//
//  SMExportPlugin.m
//  SMExportPlugin
//
//  Created by Aaron Evans on 10/7/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import "SMEExportPlugin.h"
#import "SMESession.h"
#import "ExportPluginProtocol.h"
#import "ExportMgr.h"
#import "SMEAlbumEditController.h"
#import "SMEAccountManager.h"
#import "SMEGlobals.h"
#import "SMEBitmapImageRepAdditions.h"
#import "SMEUserDefaultsAdditions.h"
#import "SMEDataAdditions.h"
#import "SMEStringAdditions.h"
#import "SMERequest.h"
#import "SMEAlbum.h"
#import "SMEResponse.h"
#import "SMESubCategory.h"
#import "SMECategory.h"
#import "SMEImageURLs.h"

@interface SMEExportPlugin (Private)
-(ExportMgr *)exportManager;
-(void)setExportManager:(ExportMgr *)m;
-(SMESession *)session;
-(void)setSession:(SMESession *)m;
-(SMESessionInfo *)sessionInfo;
-(void)setSessionInfo:(SMESessionInfo *)m;
-(NSString *)username;
-(void)setUsername:(NSString *)n;
-(NSString *)password;
-(void)setPassword:(NSString *)p;
-(NSString *)sessionUploadStatusText;
-(void)setSessionUploadStatusText:(NSString *)t;
-(NSNumber *)fileUploadProgress;
-(void)setFileUploadProgress:(NSNumber *)v;
-(NSNumber *)sessionUploadProgress;
-(void)setSessionUploadProgress:(NSNumber *)v;
-(int)imagesUploaded;
-(void)setImagesUploaded:(int)v;
-(void)resizeWindow;
-(SMEAccountManager *)accountManager;
-(void)setAccountManager:(SMEAccountManager *)mgr;
-(void)registerDefaults;
-(BOOL)loginAttempted;
-(void)setLoginAttempted:(BOOL)v;
-(void)performPostLoginTasks;
-(NSString *)loginSheetStatusMessage;
-(void)setLoginSheetStatusMessage:(NSString *)m;
-(void)setSelectedAccount:(NSString *)account;
-(NSString *)selectedAccount;
-(SMEAlbum *)selectedAlbum;
-(NSString *)statusText;
-(void)setStatusText:(NSString *)t;
-(BOOL)isBusy;
-(void)setIsBusy:(BOOL)v;
-(BOOL)isLoggedIn;
-(BOOL)isLoggingIn;
-(void)setIsLoggingIn:(BOOL)v;
-(BOOL)isDeletingAlbum;
-(void)setIsDeletingAlbum:(BOOL)v;	
-(void)login;
-(NSImage *)currentThumbnail;
-(void)setCurrentThumbnail:(NSImage *)d;
-(void)setInsertionPoint:(NSWindow *)aWindow;
-(void)presentError:(NSString *)errorText;
-(BOOL)isUploading;
-(void)setIsUploading:(BOOL)v;
-(void)beginAlbumDelete;
-(BOOL)browserOpenedInGallery;
-(void)setBrowserOpenedInGallery:(BOOL)v;	
-(NSString *)imageUploadProgressText;
-(void)setImageUploadProgressText:(NSString *)text;
-(NSPanel *)uploadPanel;
-(NSPanel *)loginPanel;
-(BOOL)sheetIsDisplayed;
-(void)uploadCurrentImage;
-(void)openLastGalleryInBrowser;
-(NSInvocation *)postLogoutInvocation;
-(void)setPostLogoutInvocation:(NSInvocation *)inv;
-(void)accountChangedTasks:(NSString *)account;
-(NSPredicate *)createRelevantSubCategoryPredicate;
+(void)initializeLocalizableStrings;
-(BOOL)siteUrlHasBeenFetched;
-(void)setSiteUrlHasBeenFetched:(BOOL)v;
-(NSURL *)uploadSiteUrl;
-(void)setUploadSiteUrl:(NSURL *)url;
-(void)selectFirstSubCategory;
-(SMEAlbumEditController *)albumEditController;
-(void)setAlbumEditController:(SMEAlbumEditController *)aController;	
-(NSArray *)albums;
-(void)setAlbums:(NSArray *)a;
-(NSArray *)categories;
-(void)setCategories:(NSArray *)v;
-(NSArray *)subcategories;
-(void)setSubcategories:(NSArray *)v;	

-(NSArray *)filenameSelectionOptions;
-(NSString *)chooseUploadFilename:(NSString *)filename title:(NSString *)imageTitle;
-(void)displayUserUpdatePolicy;
-(BOOL)isUpdateInProgress;
-(void)setIsUpdateInProgress:(BOOL)v;
-(void)remoteVersionInfoWasFetch:(NSDictionary *)remoteInfo;
-(void)displayUpdateAvailable:(NSDictionary *)remoteInfo;
-(void)displayNoUpdateAvailable;
-(int)albumUrlFetchAttemptCount;
-(void)incrementAlbumUrlFetchAttemptCount;
-(void)resetAlbumUrlFetchAttemptCount;
-(void)performUploadCompletionTasks:(BOOL)wasSuccessful;
-(void)uploadNextImage;

-(NSString *)GrowlFrameworkPath;
-(BOOL)isGrowlLoaded;
-(void)loadGrowl;
-(void)unloadGrowl;
-(BOOL)isFrameworkLoaded:(NSString *)fwPath;
-(NSString *)JSONFrameworkPath;
-(BOOL)isJSONLoaded;
-(void)loadJSON;
-(void)unloadJSON;
-(void)unloadFramework:(NSString *)fwPath;

-(void)notifyImageUploaded:(NSString *)imageFilename image:(NSData *)image;
-(NSData *)notificationThumbnail:(NSData *)fullsizeImageData;

-(void)presentRemoteError:(SMEResponse *)resp;
@end

@interface SMEExportPlugin (GrowlDelegate)
-(NSDictionary *) registrationDictionaryForGrowl;
-(NSString *) applicationNameForGrowl;
-(NSData *) applicationIconDataForGrowl;
-(void) growlIsReady;
-(void) growlNotificationWasClicked:(id)clickContext;
-(void) growlNotificationTimedOut:(id)clickContext;
-(void)notifyLogin:(NSString *)account;
-(void)notifyLougout:(NSString *)account;
-(void)notifyUploadCompleted;
-(void)notifyUploadError:(NSString *)error;
@end

// UI keys
NSString *ExistingAlbumTabIdentifier = @"existingAlbum";
NSString *NewAlbumTabIdentifier = @"newAlbum";

// UI strings
NSString *NewAccountLabel;
NSString *NullSubcategoryLabel;

NSString *SMUploadedFilenameOptionFilename;
NSString *SMUploadedFilenameOptionTitle;

// defaults keys
NSString *SMESelectedTabIdDefaultsKey = @"SMESelectedTabId";
NSString *SMEAccountsDefaultsKey = @"SMEAccounts";
NSString *SMESelectedAccountDefaultsKey = @"SMESelectedAccount";
NSString *SMOpenInBrowserAfterUploadCompletion = @"SMOpenInBrowserAfterUploadCompletion";
NSString *SMCloseExportWindowAfterUploadCompletion = @"SMCloseExportWindowAfterUploadCompletion";
NSString *SMStorePasswordInKeychain = @"SMStorePasswordInKeychain";
NSString *SMSelectedScalingTag = @"SMSelectedScalingTag";
NSString *SMUseKeywordsAsTags = @"SMUseKeywordsAsTags";
NSString *SMImageScaleWidth = @"SMImageScaleWidth";
NSString *SMImageScaleHeight = @"SMImageScaleHeight";
NSString *SMShowAlbumDeleteAlert = @"SMShowAlbumDeleteAlert";
NSString *SMEnableNetworkTracing = @"SMEnableNetworkTracing";
NSString *SMEnableAlbumFetchDelay = @"SMEnableAlbumFetchDelay";
NSString *SMJpegQualityFactor = @"SMJpegQualityFactor";
NSString *SMRemoteInfoURL = @"SMRemoteInfoURL";
NSString *SMCheckForUpdates = @"SMCheckForUpdates";
NSString *SMUserHasSeenUpdatePolicy = @"SMUserHasSeenUpdatePolicy";
NSString *SMAutomaticallyCheckForUpdates = @"SMAutomaticallyCheckForUpdates";
NSString *SMUploadedFilename = @"SMUploadFilename";
NSString *SMLastUpdateCheck = @"SMLastUpdateCheck";
NSString *SMUpdateCheckInterval = @"SMUpdateCheckInterval";
NSString *SMContinueUploadOnFileIOError = @"SMContinueUploadOnFileIOError";

// Growl Notification Keys
NSString *SMGrowlUploadCompleted = nil;
NSString *SMGrowlUploadError = nil;
NSString *SMGrowlImageUploaded = nil;
NSString *SMGrowlLogin = nil;
NSString *SMGrowlLogout = nil;

static const int AlbumUrlFetchRetryCount = 5;
static const int SMDefaultScaledHeight = 2592;
static const int SMDefaultScaledWidth = 2592;
static const NSTimeInterval SMDefaultUpdateCheckInterval = 24.0*60.0*60.0;

NSString *defaultRemoteVersionInfo = @"http://s3.amazonaws.com/smugmugexport/versionInfo.plist";

@implementation SMEExportPlugin

-(id)initWithExportImageObj:(id)exportMgr {
	if((self = [super init]) == nil)
		return nil; // fail!
	
	exportManager = exportMgr;	
	[self loadGrowl];
	[self loadJSON];
	
	[NSBundle loadNibNamed: @"SmugMugExport" owner:self];
	
	
	[self setAccountManager:[SMEAccountManager accountManager]];
	[self setSession:[SMESession session]];
	[self setAlbumEditController:[SMEAlbumEditController controller]];
	[albumEditController setDelegate:self];
	[self setLoginAttempted:NO];
	[self setSiteUrlHasBeenFetched:NO];
	[self setImagesUploaded:0];
	[self setIsUploading:NO];
	[self resetAlbumUrlFetchAttemptCount];
	
	return self;
}

+(void)initializeLocalizableStrings {
	NewAccountLabel = NSLocalizedString(@"New Account...", @"Text for New Account entry in account popup");
	NullSubcategoryLabel = NSLocalizedString(@"None", @"Text for Null SubCategory");
	SMUploadedFilenameOptionFilename = NSLocalizedString(@"filename", @"filename option for upload filename preference");
	SMUploadedFilenameOptionTitle = NSLocalizedString(@"title", @"title option for upload filename preference");
	
	// Growl stuff
	SMGrowlUploadCompleted = NSLocalizedString(@"Upload Completed", @"Upload completed growl notification name");
	SMGrowlUploadError = NSLocalizedString(@"Upload Error", @"Upload error growl notification name");
	SMGrowlImageUploaded = NSLocalizedString(@"Image Uploaded", @"Image uploaded growl notification name");
	SMGrowlLogin = NSLocalizedString(@"Logged In", @"Logged in growl notification name");
	SMGrowlLogout = NSLocalizedString(@"Logged Out", @"Logged out growl notification name");
}

-(void)dealloc {
	[self unloadGrowl];
	[self unloadJSON];
	[[self subcategories] release];
	[[self categories] release];
	[[self albums] release];
	[[self albumEditController] release];
	[[self postLogoutInvocation] release];
	[[self uploadSiteUrl] release];
	[[self session] release];
	[[self username] release];
	[[self password] release];
	[[self sessionUploadStatusText] release];
	[[self fileUploadProgress] release];
	[[self sessionUploadProgress] release];
	[[self accountManager] release];
	[[self loginSheetStatusMessage] release];
	[[self statusText] release];
	[[self currentThumbnail] release];
	[[self imageUploadProgressText] release];
	
	[super dealloc];
}

-(SMEUserDefaults *)defaults {
	return [NSUserDefaults smugMugUserDefaults];
}

+(void)initialize {
	[self initializeLocalizableStrings];
	
	NSNumber *no = [NSNumber numberWithBool:NO];
	NSNumber *yes = [NSNumber numberWithBool:YES];
	
	NSMutableDictionary *defaultsDict = [NSMutableDictionary dictionary];
	[defaultsDict setObject:ExistingAlbumTabIdentifier forKey:SMESelectedTabIdDefaultsKey];
	[defaultsDict setObject:[NSArray array] forKey:SMEAccountsDefaultsKey];
	[defaultsDict setObject:yes forKey:SMOpenInBrowserAfterUploadCompletion];
	[defaultsDict setObject:yes forKey:SMCloseExportWindowAfterUploadCompletion];
	[defaultsDict setObject:yes forKey:SMStorePasswordInKeychain];
	[defaultsDict setObject:no forKey:SMUseKeywordsAsTags];
	[defaultsDict setObject:yes forKey:SMShowAlbumDeleteAlert];
	[defaultsDict setObject:no forKey:SMEnableNetworkTracing];
	[defaultsDict setObject:yes forKey:SMEnableAlbumFetchDelay];
	[defaultsDict setObject:[NSNumber numberWithFloat:[NSBitmapImageRep defaultJpegScalingFactor]] forKey:SMJpegQualityFactor];
	[defaultsDict setObject:[NSNumber numberWithInt:0] forKey:SMSelectedScalingTag];
	[defaultsDict setObject:[NSNumber numberWithInt: SMDefaultScaledWidth] forKey:SMImageScaleWidth];
	[defaultsDict setObject:[NSNumber numberWithInt: SMDefaultScaledHeight] forKey:SMImageScaleHeight];
	[defaultsDict setObject:defaultRemoteVersionInfo forKey:SMRemoteInfoURL];
	[defaultsDict setObject:yes forKey:SMCheckForUpdates];
	[defaultsDict setObject:SMUploadedFilenameOptionFilename forKey:SMUploadedFilename];
	[defaultsDict setObject:no forKey:SMUserHasSeenUpdatePolicy];
	[defaultsDict setObject:no forKey:SMAutomaticallyCheckForUpdates];
	[defaultsDict setObject:[NSDate distantPast] forKey:SMLastUpdateCheck];
	[defaultsDict setObject:[NSNumber numberWithInt:SMDefaultUpdateCheckInterval] forKey:SMUpdateCheckInterval];
	[defaultsDict setObject:no forKey:SMContinueUploadOnFileIOError];
	
	[[NSUserDefaults smugMugUserDefaults] registerDefaults:defaultsDict];
	
	[[self class] setKeys:[NSArray arrayWithObject:@"accountManager.accounts"] triggerChangeNotificationsForDependentKey:@"accounts"];
	[[self class] setKeys:[NSArray arrayWithObject:@"accountManager.selectedAccount"] triggerChangeNotificationsForDependentKey:@"selectedAccount"];
	
}

-(void)awakeFromNib {
	[albumsTableView setTarget:self];
	[albumsTableView setDoubleAction:@selector(showEditAlbumSheet:)];
}

-(BOOL)sheetIsDisplayed {
	return [albumEditController isSheetOpen] ||
		[[self loginPanel] isVisible] ||
		[[self uploadPanel] isVisible] ||
		errorAlertSheetIsVisisble;
}

-(NSString *)versionString {
	NSString *versionString = [NSString stringWithFormat:@"%@ (%@)", [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:(NSString *)kCFBundleShortVersionStringKey], [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey]];
	return versionString;
}

-(NSArray *)filenameSelectionOptions {
	return [NSArray arrayWithObjects:
			 SMUploadedFilenameOptionFilename,
			 SMUploadedFilenameOptionTitle,
			 nil];
}

-(IBAction)donate:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_xclick&business=aaron%40aarone%2eorg&no_shipping=2&no_note=1&currency_code=USD&lc=US&bn=PP%2dBuyNowBF&charset=UTF%2d8"]];
}

#pragma mark Error Handling
-(void)presentError:(NSString *)errorText {
	if([self sheetIsDisplayed]) {
		NSLog(@"%@", errorText);
		return; // TODO display somewhere else
	}
	
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert setMessageText:errorText];
	[alert addButtonWithTitle:@"Continue"];
	
	errorAlertSheetIsVisisble = YES;
	[alert beginSheetModalForWindow:[[self exportManager] window]
					  modalDelegate:self
					 didEndSelector:@selector(errorAlertDidEnd:returnCode:contextInfo:)
						contextInfo:NULL];
}

-(void)errorAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	errorAlertSheetIsVisisble = NO;
	[alert release];
}

#pragma mark Software Update
-(NSDictionary *)remoteVersionInfo {
	NSURL *versionInfoLocation = [NSURL URLWithString:[[self defaults] objectForKey:SMRemoteInfoURL]];
	if(versionInfoLocation == nil) {
		NSLog(@"Cannot find a url for remote version.");
		return nil;
	}
	
	NSData *remoteData = [NSData dataFromModGzUrl:versionInfoLocation];
	NSDictionary *remoteInfo = [NSPropertyListSerialization propertyListFromData:remoteData
																mutabilityOption:NSPropertyListImmutable
																		  format:NULL
																errorDescription:nil];
	return remoteInfo;
}

-(void)displayUserUpdatePolicy {
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:NSLocalizedString(@"Automatically Check", @"Option button text for automatically checking for updates")];
	[alert addButtonWithTitle:NSLocalizedString(@"Manually Check", @"Option button text for automatically checking for updates")];
	[alert setMessageText:NSLocalizedString(@"Automatically check for updates?", @"Message text for update confirmation text")];
	[alert setInformativeText:NSLocalizedString(@"SmugMugExport can automatically check for new versions of the plugin.", @"Informative text to display when user selects whether to check for updates automatically.")];
	[alert setAlertStyle:NSInformationalAlertStyle];
	
	int selectedButton = [alert runModal];
	
	[[self defaults] setObject:[NSNumber numberWithBool:YES] forKey:SMUserHasSeenUpdatePolicy];
	[[self defaults] setObject:[NSNumber numberWithBool:selectedButton == NSAlertFirstButtonReturn] forKey:SMAutomaticallyCheckForUpdates];
	[alert release];
}

-(void)checkForUpdatesIfNecessary {
	if(![[[self defaults] objectForKey:SMCheckForUpdates] boolValue])
		return;
	
	NSDate *lastCheck = [[self defaults] objectForKey:SMLastUpdateCheck];
	NSTimeInterval interval = [[[self defaults] objectForKey:SMUpdateCheckInterval] doubleValue];
	if([[NSDate date] timeIntervalSinceDate:lastCheck] > interval) {
		[NSThread detachNewThreadSelector:@selector(checkForUpdatesInBackground:)
								 toTarget:self
							   withObject:[NSNumber numberWithBool:NO]];
	}
}

-(IBAction)checkForUpdates:(id)sender {
	if([self isUpdateInProgress]) {
		NSBeep();
		return;
	}
	
	[self setIsUpdateInProgress:YES];
	[NSThread detachNewThreadSelector:@selector(checkForUpdatesInBackground:)
							 toTarget:self
						   withObject:[NSNumber numberWithBool:YES]];
}

-(void)checkForUpdatesInBackground:(NSNumber *)displayAlertIfNoUpdateAvailable {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSDictionary *remoteInfo = [self remoteVersionInfo];
	[[self defaults] setObject:[NSDate date] forKey:SMLastUpdateCheck];
	
	[self performSelectorOnMainThread:@selector(remoteVersionInfoWasFetch:)
						   withObject:[NSDictionary dictionaryWithObjectsAndKeys: 
									   remoteInfo , @"remoteInfo",
									   displayAlertIfNoUpdateAvailable, @"displayAlertIfNoUpdateAvailable", nil]
						waitUntilDone:NO];
	[pool release];
}

-(NSBundle *)thisBundle {
	return [NSBundle bundleForClass:[SMEExportPlugin class]];
}

-(void)remoteVersionInfoWasFetch:(NSDictionary *)args {
	[self setIsUpdateInProgress:NO];
	NSDictionary *remoteInfo = [args objectForKey:@"remoteInfo"];
	NSNumber *displayAlertIfNoUpdateAvailable = [args objectForKey:@"displayAlertIfNoUpdateAvailable"];
	// remoteInfo == nil => no check performed
	if(remoteInfo == nil)
		return;
	
	NSString *remoteVersion = [remoteInfo objectForKey:@"remoteVersion"];
	if(remoteVersion == nil) {
		return;
	}
	
	NSString *localVersion = [[[self thisBundle] infoDictionary] objectForKey:(NSString *)kCFBundleShortVersionStringKey];
	if(localVersion == nil) {
		NSLog(@"undefined bundle version found during update.");
		NSBeep();
		return;
	}

	if([localVersion compareVersionToVersion:remoteVersion] == NSOrderedAscending)
		[self displayUpdateAvailable:remoteInfo];
	else if([displayAlertIfNoUpdateAvailable boolValue])
		[self displayNoUpdateAvailable];
}

-(void)displayNoUpdateAvailable {
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:NSLocalizedString(@"Dismiss", @"Dismiss button to dismiss no new version available button.")];
	[alert setMessageText: [NSString stringWithFormat:NSLocalizedString(@"You are running the newest version of SmugMugExport (%@).", @"Message text for no update available text"), [[[self thisBundle] infoDictionary] objectForKey:(NSString *)kCFBundleShortVersionStringKey]]];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert runModal];
	[alert release];	
}

-(void)displayUpdateAvailable:(NSDictionary *)remoteInfo {
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:NSLocalizedString(@"Download New Version", @"Button text to confirm download of a new version.")];
	[alert addButtonWithTitle:NSLocalizedString(@"Later", @"Button text to decline invitation to download a new version.")];
	[alert setMessageText:NSLocalizedString(@"A new version of SmugMugExport is available.", @"Message text for update available text")];
	[alert setAlertStyle:NSInformationalAlertStyle];
	
	int selectedButton = [alert runModal];
	if(selectedButton == NSAlertFirstButtonReturn) {
		// go to the update site
		NSString *updateLocation = [remoteInfo objectForKey:@"remoteLocation"];
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:updateLocation]];
	}
	[alert release];
}

-(NSString *)apiKey {
	return @"98LHI74dS6P0A8cQ1M6h0R1hXsbIPDXc";
}


#pragma mark Login Methods

-(void)attemptLoginIfNecessary {
	// try to automatically show the login sheet 
	
	if([loginPanel isVisible]) // don't try to show the login sheet if it's already showing
		return;
	
	if(![[[self exportManager] window] isKeyWindow])
		return;
	
	/* don't try to login if we're already logged in or attempting to login */
	if([self isLoggedIn] ||
	   [self isLoggingIn])
		return;
	
	/*
	 * Show the login window if we're not logged in and there is no way to autologin
	 */
	if(![self isLoggedIn] && 
	   ![[self accountManager] canAttemptAutoLogin]) {
		
		// show the login panel after some delay
		[self showLoginSheet:self];
		return;
	}
	
	/*
	 *  If we have a saved password for the previously selected account, log in to that account.
	 */
	if(![self isLoggedIn] && 
	   ![self isLoggingIn] &&
	   [[[self accountManager] accounts] count] > 0 &&
	   [[self accountManager] selectedAccount] != nil &&
	   ![self loginAttempted] &&
	   [[self accountManager] passwordExistsInKeychainForAccount:[[self accountManager] selectedAccount]]) {

		[self setLoginAttempted:YES];
		[self performSelectorOnMainThread:@selector(setIsBusyWithNumber:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];	
		[self performSelectorOnMainThread:@selector(setStatusText:) withObject:NSLocalizedString(@"Logging in...", @"Status text for logginng in") waitUntilDone:NO];
		[self setIsLoggingIn:YES];
		
		[[self session] loginWithTarget:self 
							   callback:@selector(autoLoginComplete:)
							   username:[[self accountManager] selectedAccount] 
							   password:[[self accountManager] passwordForAccount:[[self accountManager] selectedAccount]] 
								 apiKey:[self apiKey]];
	}
	
	// if user has seen the update policy this upload session, don't show it again
	// if the user has seen the update policy in the past, don't 
	if(![[[self defaults] objectForKey:SMUserHasSeenUpdatePolicy] boolValue])
		[self displayUserUpdatePolicy];
	else
		[self checkForUpdatesIfNecessary];
	
}

-(IBAction)showLoginSheet:(id)sender {
	if(![[[self exportManager] window] isVisible])
		return;
	
	if([self sheetIsDisplayed])
		return;
	
	[NSApp beginSheet:loginPanel
	   modalForWindow:[[self exportManager] window]
		modalDelegate:self
	   didEndSelector:@selector(loginDidEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];

	[self setInsertionPoint:[self loginPanel]];
	
	// mark that we've shown the user the login sheet at least once
	[self setLoginAttempted:YES];
}

-(void)setInsertionPoint:(NSWindow *)aWindow {
	if([[aWindow firstResponder] respondsToSelector:@selector(setString:)]) {
		// hack to get insertion point to appear in textfield
		[(NSTextView *)[aWindow firstResponder] setString:@""];
	}	
}

-(IBAction)cancelLoginSheet:(id)sender {
	if([[[self accountManager] accounts] count] > 0)
		[self setSelectedAccount:[[[self accountManager] accounts] objectAtIndex:0]];
	
	[self setLoginSheetStatusMessage:@""];
	[self setIsLoggingIn:NO];
	[NSApp endSheet:loginPanel];
}

/** called from the login sheet.  takes username/password values from the textfields */
-(IBAction)performLoginFromSheet:(id)sender {
	if(IsEmpty([self username]) ||
	   IsEmpty([self password])) {
		NSBeep();
	}
	
	[self setLoginSheetStatusMessage:NSLocalizedString(@"Logging In...", @"log in status string")];
	[self setIsLoggingIn:YES];

	[[self session] loginWithTarget:self 
						   callback:@selector(loginComplete:) 
						   username:[self username] 
						   password:[self password]
							 apiKey:[self apiKey]];
}

-(BOOL)commonPostLoginTasks:(SMEResponse *)response {
	[self setIsBusy:NO];
	[self setStatusText:@""];
	[self setIsLoggingIn:NO];
	[self setLoginSheetStatusMessage:@""];
	
	if(! [response wasSuccessful]) {
		NSString *err = NSLocalizedString(@"Login Failed", @"Status text for failed login");
		// login request spawned from login sheet
		if([[self loginPanel] isVisible]) {
			[self setLoginSheetStatusMessage:err];
			/* we act like we haven't atttempted a log in if the login fails. */
			[self setLoginAttempted:NO];			
		} else { // autologin via keychain info
			[self setStatusText:err];
			[self showLoginSheet:self];
		}
		
		[self setSessionInfo:nil];
		return NO;
	}
	
	[self setSessionInfo:(SMESessionInfo *)[response smData]];
	[self setCategories:nil];
	[self setSubcategories:nil];
	[[self session] fetchAlbumsWithTarget:self callback:@selector(albumFetchComplete:)];
	[[self session] fetchCategoriesWithTarget:self callback:@selector(categoryFetchComplete:)];
	[[self session] fetchSubCategoriesWithTarget:self callback:@selector(subcategoryFetchDidComplete:)];
	return YES;
}

-(void)autoLoginComplete:(SMEResponse *)response {
	[self commonPostLoginTasks:response];
}

-(void)loginComplete:(SMEResponse *)response {
	
	if(![self commonPostLoginTasks:response])
		return;

	[[self accountManager] addAccount:[self username] withPassword:[self password]];
	[self setSelectedAccount:[self username]];
	[NSApp endSheet:loginPanel];
	[self notifyLogin:[self selectedAccount]];
}


-(void)loginDidEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

#pragma mark ALbum Fetch Callback

-(void)albumFetchComplete:(SMEResponse *)resp {
	if(![resp wasSuccessful]) {
		// TODO report error
		return;
	}
	
	[self setAlbums:[resp smData]];
	[albumsArrayController setSelectionIndex:0]; 
}

#pragma mark Logout 
-(void)logoutDidComplete:(SMEResponse *)resp {
	[self notifyLougout:[self selectedAccount]];
	[self setSessionInfo:nil];
	[[self postLogoutInvocation] invokeWithTarget:self];
}

#pragma mark Preferences

-(NSPanel *)preferencesPanel {
	return preferencesPanel;
}

-(IBAction)showPreferences:(id)sender {
	[NSApp beginSheet:[self preferencesPanel]
	   modalForWindow:[[self exportManager] window]
		modalDelegate:self
	   didEndSelector:@selector(preferencesSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
}

-(void)preferencesSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[[self preferencesPanel] orderOut:self];
}

-(IBAction)closePreferencesSheet:(id)sender {
	[NSApp endSheet:[self preferencesPanel]];
}

#pragma mark Add Album

-(IBAction)showNewAlbumSheet:(id)sender { // opens the create album sheet
	
	if(![[[self exportManager] window] isVisible])
		return;
	
	if([self sheetIsDisplayed])
		return;
	
	if(![self isLoggedIn] || [self isLoggingIn]) {
		NSBeep();
		return;
	}
	
	[albumEditController showAlbumCreateSheet:[SMEAlbum album] delegate:self forWindow:[[self exportManager] window]];
}

-(void)createAlbum:(SMEAlbum *)album {
	if(IsEmpty([album title])) {
		NSBeep();
		return;
	}
	
	[[self albumEditController] setIsBusy:YES];
	[[self session] createNewAlbum:album withTarget:self callback:@selector(createNewAlbumDidComplete:)];	
}

-(void)createNewAlbumDidComplete:(SMEResponse *)resp {
	
	[[self albumEditController] setIsBusy:NO];
	if([resp wasSuccessful]) {
		[albumEditController closeSheet];
		[albumsArrayController setSelectionIndex:0]; // default to selecting the new album which should be album 0

		// refresh list of albums
		[[self session] fetchAlbumsWithTarget:self callback:@selector(albumFetchComplete:)];
	} else {
		// album creation occurs in a sheet, don't try to show an error dialog in another sheet...
		NSBeep();
		
		//[self presentError:NSLocalizedString(@"Album creation failed.", @"Error message to display when album creation fails.")];
	}
}

#pragma mark Delete Album

-(IBAction)removeAlbum:(id)sender {
	if([[self selectedAlbum] albumId] == nil) { // no album is selected
		NSBeep();
		return;
	}
	
	// not properly logged in, can't remove an album
	if(![self isLoggedIn] || [self isLoggingIn]) {
		NSBeep();
		return;
	}
	
	if([[[NSUserDefaults smugMugUserDefaults] objectForKey:SMShowAlbumDeleteAlert] boolValue]) {
		NSBeginAlertSheet(NSLocalizedString(@"Delete Album", @"Delete Album Sheet Title"),
						  NSLocalizedString(@"Delete", @"Default button title for album delete sheet"),
						  NSLocalizedString(@"Cancel", @"Alternate button title for album delete sheet"),
						  nil,
						  [[self exportManager] window],
						  self,
						  @selector(deleteAlbumSheetDidEnd:returnCode:contextInfo:),
						  @selector(sheetDidDismiss:returnCode:contextInfo:),
						  NULL,
						  NSLocalizedString(@"Are you sure you want to delete this album?  All photos in this album will be deleted from SmugMug.", @"Warning text to display in the delete album alert sheet."));		
	} else {
		[self beginAlbumDelete];
	}
}

-(void)beginAlbumDelete {
	[self setIsBusy:YES];
	[self setIsDeletingAlbum:YES];
	[self setStatusText:NSLocalizedString(@"Deleting Album...", @"Delete album status")];
	
	[[self session] deleteAlbum:[[self selectedAlbum] ref] withTarget:self callback:@selector(deleteAlbumDidComplete:)];
}	

-(void)sheetDidDismiss:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
	
}

-(void)deleteAlbumSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
	if(returnCode == NSAlertDefaultReturn)
		[self beginAlbumDelete];
	
}

-(void)deleteAlbumDidComplete:(SMEResponse *)resp {
	if(![resp wasSuccessful])
		[self presentError:NSLocalizedString(@"Album deletion failed.", 
											 @"Error message to display when album delete fails.")];
	
	[self setIsBusy:NO];
	[self setIsDeletingAlbum:NO];
	[self setStatusText:@""];	
	[[self session] fetchAlbumsWithTarget:self callback:@selector(albumFetchComplete:)];
}

#pragma mark Album Edit
-(IBAction)showEditAlbumSheet:(id)sender {
	if([self selectedAlbum] == nil) {
		NSBeep();
		return;
	}
	
	[self setIsBusy:YES];
	[[self session] fetchExtendedAlbumInfo:[[self selectedAlbum] ref]
								withTarget:self 
								  callback:@selector(albumInfoFetchDidComplete:)];
}

-(SMECategory *)categoryWithId:(unsigned int)categoryId {
	SMECategory *aCategory;
	NSEnumerator *enumerator = [[self categories] objectEnumerator];
	while(aCategory = [enumerator nextObject]) {
		if([aCategory identifier] == categoryId)
			return aCategory;
	}
	return nil;
}

-(void)albumInfoFetchDidComplete:(SMEResponse *)resp {
	[[self albumEditController] setIsBusy:NO];
	[[self albumEditController] closeSheet];
	[self setIsBusy:NO];

	SMEAlbum *theAlbum = [resp smData];
	SMESubCategory *subCategory = [theAlbum subCategory];
	// FIXME setting a category wipes out a subcategory; this is weird but re
	[theAlbum setCategory:[self categoryWithId:[[theAlbum category] identifier]]];
	[theAlbum setSubCategory:subCategory];
	
	if(![resp wasSuccessful]) {
		[self presentRemoteError:resp];
		return;
	}
	
	[albumEditController showAlbumEditSheet:self 
								  forWindow:[[self exportManager] window]
								   forAlbum:[resp smData]];
}

-(void)editAlbum:(SMEAlbum *)album {
	[[self albumEditController] setIsBusy:YES];
	[[self session] editAlbum:album withTarget:self callback:@selector(albumEditDidEnd:)];
}

-(void)albumEditDidEnd:(SMEResponse *)resp {
	if(![resp wasSuccessful]) {
		[self presentRemoteError:resp];
	} else {
		// a visible title of an album may have changed..
		[[self session] fetchAlbumsWithTarget:self callback:@selector(albumFetchComplete:)];
	}
	
	[[self albumEditController] setIsBusy:NO];
	[[self albumEditController] closeSheet];
}

#pragma mark Image Url Fetching

-(void)imageUrlFetchDidCompleteForImageRef:(SMEResponse *)resp {
 
	SMEImageURLs *urls = [resp smData];
	
	if(![resp wasSuccessful] && [self albumUrlFetchAttemptCount] < AlbumUrlFetchRetryCount) {
		[self incrementAlbumUrlFetchAttemptCount];
	
		// try again
//		[[self session] performSelector:@selector(fetchImageUrls:) 
//							  withObject:ref
//							  afterDelay:2.0
//								 inModes:[NSArray arrayWithObjects: NSDefaultRunLoopMode, NSModalPanelRunLoopMode, nil]];		
		return;
	}
	
	NSString *siteUrlString = [urls albumURL];
	if(siteUrlString != nil) {
		[self setUploadSiteUrl:[NSURL URLWithString:siteUrlString]];
		[self setSiteUrlHasBeenFetched:YES];
	} else {
		[self setSiteUrlHasBeenFetched:NO];
	}
	
	/* it's possible that we're done uploading the images for an album and *then* we
		receive this callback notifying us of the url for the album.  In that case,
	   we open the gallery in the browser. Otherwise, this happens when the upload
		completes
		*/
	if(![self isUploading] && 
	   [self uploadSiteUrl] != nil &&
	   ![self browserOpenedInGallery] &&
	   [[[NSUserDefaults smugMugUserDefaults] valueForKey:SMOpenInBrowserAfterUploadCompletion] boolValue]) {
		[self openLastGalleryInBrowser];
	}
}

-(void)openLastGalleryInBrowser {
	[[NSWorkspace sharedWorkspace] openURL:[self uploadSiteUrl]];
	[self setBrowserOpenedInGallery:YES];
}

#pragma mark Category Get

-(NSArray *)subcategoriesForCategory:(SMECategory *)cat {
	SMESubCategory *aSubCategory;
	NSEnumerator *subCategoryEnumerator = [[self subcategories] objectEnumerator];
	NSMutableArray *subcategoriesForCategory = [NSMutableArray array];
	while(aSubCategory = [subCategoryEnumerator nextObject]) {
		if([aSubCategory parentCategoryIdentifier] == [cat identifier])
			[subcategoriesForCategory addObject:aSubCategory];			
	}
	return [NSArray arrayWithArray:subcategoriesForCategory];
}

-(void)populateCategorySubCategories {
	NSAssert([self categories] != nil && [self subcategories] != nil, 
			 @"Inconsistent state: attempting to fill subcategories for categories but one of the two is nil");
	
	NSEnumerator *categoryEnumerator = [[self categories] objectEnumerator];
	SMECategory *aCategory;
	while(aCategory = [categoryEnumerator nextObject])
		[aCategory setChildSubCategories:[self subcategoriesForCategory:aCategory]];
}

-(void)categoryFetchComplete:(SMEResponse *)resp {
	if(! [resp wasSuccessful]) {
		[self presentRemoteError:resp];
		return;
	}
	[self setCategories:[resp smData]];
	@synchronized(self) {
		if([self subcategories] != nil)
			[self populateCategorySubCategories];
	}
}

-(void)presentRemoteError:(SMEResponse *)resp {
	[self setIsBusy:NO];
	[self presentError:[NSString stringWithFormat:
						NSLocalizedString(@"Error from Smugmug: %@", @"Error string for remote errors"), 
						[resp errorMessage]]];
}

-(void)subcategoryFetchDidComplete:(SMEResponse *)resp {
	// smugmug considers zero categories to be an error. weird!
	if(! [resp wasSuccessful] && [resp code] != NO_CATEGORIES_FOUND_CODE) {
		[self presentRemoteError:resp];
		return;
	}
	
	[self setSubcategories:[resp smData]];	
	@synchronized(self) {
		if([self categories] != nil)
			[self populateCategorySubCategories];
	}	
}

#pragma mark Upload Methods

-(void)startUpload {
	if([self sheetIsDisplayed]) // this should be impossible
		return;

	if(![self isLoggedIn]) {
		NSBeep();
		return;
	}
	
	[self setBrowserOpenedInGallery:NO];
	[self setImagesUploaded:0];
	[self setFileUploadProgress:[NSNumber numberWithInt:0]];
	[self setSessionUploadProgress:[NSNumber numberWithInt:0]];
	[self setSessionUploadStatusText:[NSString stringWithFormat:NSLocalizedString(@"Uploading image %d of %d", @"Image upload progress text"), [self imagesUploaded] + 1, [[self exportManager] imageCount]]];

	[self setIsUploading:YES];
	[NSApp beginSheet:uploadPanel
	   modalForWindow:[[self exportManager] window]
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];

	NSString *thumbnailPath = [exportManager thumbnailPathAtIndex:[self imagesUploaded]];
	NSImage *img = [[[NSImage alloc] initWithData:[NSData dataWithContentsOfFile: thumbnailPath]] autorelease];
	if(img == nil) {
		[self presentError:NSLocalizedString(@"Cannot load image thumbnail", @"Error message when thumbnail is nil")];
		[self performUploadCompletionTasks:NO];
		return;
	}
	
	[img setScalesWhenResized:YES];
	[self setCurrentThumbnail:img];
	[self setUploadSiteUrl:nil];
	[self setSiteUrlHasBeenFetched:NO];
	
	[self uploadCurrentImage];
}

-(NSData *)sourceDataAtPath:(NSString *)pathToImage isImage:(BOOL)isImage errorString:(NSString **)err {
	
	NSString *application = nil;
	NSString *filetype = nil;
	BOOL result = [[NSWorkspace sharedWorkspace] getInfoForFile:pathToImage
													application:&application
														   type:&filetype];
	if(result == NO) {
		*err =  [NSString stringWithFormat:NSLocalizedString(@"Upload failed: error accessing image: %@.", @"Error message when an image cannot be read."), pathToImage];
		return nil;
	}
	
	BOOL isJpeg = [[filetype lowercaseString] isEqual:@"jpg"];
	
	if(!isJpeg && ShouldScaleImages())
		NSLog(@"The image (%@) is not a jpeg and cannot be scaled by this program (yet).", pathToImage);
	
	NSError *error = nil;
	NSData *imgData = [NSData dataWithContentsOfFile:pathToImage options:0 error:&error];
	if(imgData == nil) {
		*err = [error localizedDescription];
		return nil;
	}
	
	if(isJpeg && ShouldScaleImages() && isImage) {
		int maxWidth = [[[NSUserDefaults smugMugUserDefaults] objectForKey:SMImageScaleWidth] intValue];
		int maxHeight = [[[NSUserDefaults smugMugUserDefaults] objectForKey:SMImageScaleHeight] intValue];
		
		// allow no input and treat it like infinity
		if(maxWidth == 0)
			maxWidth = INT_MAX;
		if(maxHeight == 0)
			maxHeight = INT_MAX;
		
		NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithData:imgData] autorelease];
		
		// scale
		if([rep pixelsWide] > maxWidth || [rep pixelsHigh] > maxHeight)
			return [rep scaledRepToMaxWidth:maxWidth maxHeight:maxHeight];
		
		// no scale
		return imgData;
	}
	
	// the default operation
	return imgData;
}

-(void)uploadCurrentImage {
	
	NSString *nextFile = nil;
	
	// if it's a movie, get the movie source
	if([[self exportManager] originalIsMovieAtIndex:[self imagesUploaded]]) {
		// get the movie:
		nextFile = [[self exportManager] sourcePathAtIndex:[self imagesUploaded]];
	} else {
		// or a jpeg
		nextFile = [[self exportManager] imagePathAtIndex:[self imagesUploaded]];
	}
	
	NSString *error = nil;
	NSData *srcData = [self sourceDataAtPath:nextFile 
									   isImage:![[self exportManager] originalIsMovieAtIndex:[self imagesUploaded]]
								   errorString:&error];	
	if(srcData == nil) {
		if([[[NSUserDefaults smugMugUserDefaults] objectForKey:SMContinueUploadOnFileIOError] boolValue]) {
			NSLog(@"Error reading image data for image: %@. The image will be skipped.", nextFile);
			[self uploadNextImage];
		} else {
			NSLog(@"Error reading image data for image: %@. The upload was canceled.", nextFile);
			[self performUploadCompletionTasks:NO];
			[self presentError:error];
		}
		return;
	}
	
	NSString *title = nil;
	if([[self exportManager] respondsToSelector:@selector(imageCaptionAtIndex:)])
		title = [[self exportManager] imageCaptionAtIndex:[self imagesUploaded]]; // iPhoto <=6
	else
		title = [[self exportManager] imageTitleAtIndex:[self imagesUploaded]]; // iPhoto 7
	
	NSString *filename = [self chooseUploadFilename:[[nextFile pathComponents] lastObject] 
											  title:title];
	[[self session] uploadImageData:srcData
							filename:filename
							   album:[[self selectedAlbum] ref]
							 caption:[[self exportManager] imageCommentsAtIndex:[self imagesUploaded]]
							keywords:[[self exportManager] imageKeywordsAtIndex:[self imagesUploaded]]
						   observer:self];		
	
}

-(NSString *)chooseUploadFilename:(NSString *)filename title:(NSString *)imageTitle {
	NSString *selectedUploadFilenameOption = [[NSUserDefaults smugMugUserDefaults] objectForKey:SMUploadedFilename];
	return [selectedUploadFilenameOption isEqualToString:SMUploadedFilenameOptionTitle] ?
											  imageTitle:filename;
}
	
-(void)performUploadCompletionTasks:(BOOL)wasSuccessful {
	[NSApp endSheet:uploadPanel];
	[self setIsUploading:NO];
	
	// if this really bothers you you can set your preferences to not open the page in the browser
	if([[[NSUserDefaults smugMugUserDefaults] valueForKey:SMOpenInBrowserAfterUploadCompletion] boolValue] &&
				[self uploadSiteUrl] != nil &&  ![self browserOpenedInGallery]) {
		[self setBrowserOpenedInGallery:YES];
		[[NSWorkspace sharedWorkspace] openURL:uploadSiteUrl];
	}
	
	if([[[NSUserDefaults smugMugUserDefaults] valueForKey:SMCloseExportWindowAfterUploadCompletion] boolValue])
		[[self exportManager] cancelExportBeforeBeginning];
	
	if(wasSuccessful)
		[self notifyUploadCompleted];
}

-(void)uploadDidFail:(SMEResponse *)resp {
	[self notifyUploadError:[resp errorMessage]];
	[self performUploadCompletionTasks:NO];
	NSString *errorString = NSLocalizedString(@"Image upload failed (%@).", @"Error message to display when upload fails.");
	[self presentError:[NSString stringWithFormat:errorString, [resp errorMessage]]];
}

-(void)uploadMadeProgress:(NSData *)imageData bytesWritten:(long)bytesWritten ofTotalBytes:(long)totalBytes {	
	float progressForFile = MIN(100.0, ceil(100.0*(float)bytesWritten/(float)totalBytes));
	[self setFileUploadProgress:[NSNumber numberWithFloat:progressForFile]];
	
	float baselinePercentageCompletion = 100.0*((float)[self imagesUploaded])/((float)[[self exportManager] imageCount]);
	float estimatedFileContribution = (100.0/((float)[[self exportManager] imageCount]))*((float)bytesWritten)/((float)totalBytes);
	[self setSessionUploadProgress:[NSNumber numberWithFloat:MIN(100.0, ceil(baselinePercentageCompletion+estimatedFileContribution))]];
	if(progressForFile < 100.0) {
		[self setImageUploadProgressText:[NSString stringWithFormat:
										  NSLocalizedString(@"%0.0fKB of %0.0fKB", @"upload progress expression"), 
										  bytesWritten/1024.0, totalBytes/1024.0]];
	} else {
		[self setImageUploadProgressText:NSLocalizedString(@"Waiting for response...", @"status indicator to display when all bytes have been sent but we're waiting for a resonse from SmugMug")];
	}
}

-(void)uploadWasCanceled {
	[self performUploadCompletionTasks:NO];
}

-(void)uploadNextImage {
	// onto the next image
	[self setImagesUploaded:[self imagesUploaded] + 1];
	[self setSessionUploadProgress:[NSNumber numberWithFloat:100.0*((float)[self imagesUploaded])/((float)[[self exportManager] imageCount])]];
	
	if([self imagesUploaded] >= [[self exportManager] imageCount]) {
		[self performUploadCompletionTasks:YES];
	} else {
		[self setSessionUploadStatusText:[NSString stringWithFormat:NSLocalizedString(@"Uploading image %d of %d", @"Image upload progress text"), [self imagesUploaded] + 1, [[self exportManager] imageCount]]];
		NSString *thumbnailPath = [exportManager thumbnailPathAtIndex:[self imagesUploaded]];
		NSImage *img = [[[NSImage alloc] initWithData:[NSData dataWithContentsOfFile: thumbnailPath]] autorelease];
		[img setScalesWhenResized:YES];
		[self setCurrentThumbnail:img];
		
		[self uploadCurrentImage];		
	}	
}

-(void)uploadDidSucceed:(SMEResponse *)resp filename:(NSString *)filename data:(NSData *)imageData {
	SMEImageRef *ref = [resp smData];
	if(![self siteUrlHasBeenFetched]) {
		[self resetAlbumUrlFetchAttemptCount];
		[self setSiteUrlHasBeenFetched:NO];
		[[self session] fetchImageURLs:ref withTarget:self callback:@selector(imageUrlFetchDidCompleteForImageRef:)];
	}

	[self notifyImageUploaded:filename image:imageData];
	[self uploadNextImage];
}

-(void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

-(IBAction)cancelUpload:(id)sender {
	[self cancelExport];
}

#pragma mark Get and Set properties

-(BOOL)isLoggedIn {
	return sessionInfo != nil; 
}

-(BOOL)isLoggingIn {
	return isLoggingIn;
}

-(void)setIsLoggingIn:(BOOL)v {
	isLoggingIn = v;
}

-(NSString *)imageUploadProgressText {
	return imageUploadProgressText;
}

-(void)setImageUploadProgressText:(NSString *)text {
	if([self imageUploadProgressText] != nil)
		[[self imageUploadProgressText] release];
	
	imageUploadProgressText = [text retain];
}

-(NSArray *)accounts {
	return [[accountManager accounts] arrayByAddingObject:NewAccountLabel];
}

/* the user selected an account in the drop down */
-(void)setSelectedAccount:(NSString *)account {
	
	// add a new account
	if([account isEqualToString:NewAccountLabel]) {
		[self showLoginSheet:self];
		return;
	}
	
	// an unknown account
	NSAssert( [[self accounts] containsObject:account], NSLocalizedString(@"Selected account is unknown", @"Error for unknown accounts"));
	
	// if we're already logged into the newly selected account, return
	if([[self selectedAccount] isEqual:account]) {
		return;
	}
	
	// if we're already loggin in to another account, logout
	if([self isLoggedIn]) {
		// handle the rest of the account changed tasks after we logout
		NSInvocation *inv = [NSInvocation invocationWithMethodSignature:
			[self methodSignatureForSelector:@selector(accountChangedTasks:)]];
		[inv setSelector:@selector(accountChangedTasks:)];
		[self setPostLogoutInvocation:inv];	
		[[self postLogoutInvocation] setArgument:&account atIndex:2];
		[inv retainArguments];
		
		[[self session] logoutWithTarget:self callback:@selector(logoutDidComplete:)]; // aynchronous callback
	} else {
		[self accountChangedTasks:account];
	}
}

-(void)accountChangedTasks:(NSString *)account {
	// set our newly selected acccount
	[[self accountManager] setSelectedAccount:account];
	
	[self setLoginAttempted:NO];
	
	// login to the newly selected account
	[self attemptLoginIfNecessary];	
}

-(NSString *)selectedAccount {
	return [[self accountManager] selectedAccount];
}

-(NSImage *)currentThumbnail {
	return currentThumbnail;
}

-(void)setCurrentThumbnail:(NSImage *)d {
	if([self currentThumbnail] != nil)
		[[self currentThumbnail] release];
	
	currentThumbnail = [d retain];
}

-(BOOL)siteUrlHasBeenFetched {
	return siteUrlHasBeenFetched;
}

-(void)setSiteUrlHasBeenFetched:(BOOL)v {
	siteUrlHasBeenFetched = v;
}

-(NSURL *)uploadSiteUrl {
	return uploadSiteUrl;
}

-(void)setUploadSiteUrl:(NSURL *)url {
	if(uploadSiteUrl != nil)
		[[self uploadSiteUrl] release];
	
	uploadSiteUrl = [url retain];
}

-(void)setIsBusyWithNumber:(NSNumber *)val {
	[self setIsBusy:[val boolValue]];
}

-(BOOL)isBusy {
	return isBusy;
}

-(void)setIsBusy:(BOOL)v {
	isBusy = v;
}

-(BOOL)isDeletingAlbum {
	return isDeletingAlbum;
}

-(void)setIsDeletingAlbum:(BOOL)v {
	isDeletingAlbum = v;
}

-(BOOL)loginAttempted {
	return loginAttempted;
}

-(void)setLoginAttempted:(BOOL)v {
	loginAttempted = v;
}

-(BOOL)browserOpenedInGallery {
	return browserOpenedInGallery;
}

-(void)setBrowserOpenedInGallery:(BOOL)v {
	browserOpenedInGallery = v;
}

-(BOOL)isUploading {
	return isUploading;
}

-(int)albumUrlFetchAttemptCount {
	return albumUrlFetchAttemptCount;
}

-(void)incrementAlbumUrlFetchAttemptCount {
	albumUrlFetchAttemptCount++;
}

-(void)resetAlbumUrlFetchAttemptCount {
	albumUrlFetchAttemptCount = 0;
}

-(void)setIsUploading:(BOOL)v {
	isUploading = v;
}

-(SMEAccountManager *)accountManager {
	return accountManager;
}

-(void)setAccountManager:(SMEAccountManager *)mgr {
	if([self accountManager] != nil)
		[[self accountManager] release];
	
	accountManager = [mgr retain];
}

-(ExportMgr *)exportManager {
	return exportManager;
}

-(int)imagesUploaded {
	return imagesUploaded;
}

-(void)setImagesUploaded:(int)v {
	imagesUploaded = v;
}

-(BOOL)isUpdateInProgress {
	return isUpdateInProgress;
}

-(void)setIsUpdateInProgress:(BOOL)v {
	isUpdateInProgress = v;
}

-(NSString *)loginSheetStatusMessage {
	return loginSheetStatusMessage;
}

-(void)setLoginSheetStatusMessage:(NSString *)m {
	if([self loginSheetStatusMessage] != nil)
		[[self loginSheetStatusMessage] release];
	
	loginSheetStatusMessage = [m retain];
}

-(NSInvocation *)postLogoutInvocation {
	return postLogoutInvocation;
}

-(void)setPostLogoutInvocation:(NSInvocation *)inv {
	if([self postLogoutInvocation] != nil)
		[[self postLogoutInvocation] release];
		
	postLogoutInvocation = [inv retain];
}

-(SMESession *)session {
	return session;
}

-(void)setSession:(SMESession *)m {
	if(m != session) {
		[session release];
		session = [m retain];
	}
}


-(SMESessionInfo *)sessionInfo {
	return sessionInfo;
}

-(void)setSessionInfo:(SMESessionInfo *)m {
	if([self sessionInfo] != nil)
		[[self sessionInfo] release];
	
	sessionInfo = [m retain];
}

-(SMEAlbumEditController *)albumEditController {
	return albumEditController;
}

-(void)setAlbumEditController:(SMEAlbumEditController *)aController {
	if(aController != albumEditController) {
		[albumEditController release];
		albumEditController = [aController retain];
	}
}

-(id)description {
    return [[[self thisBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
}

-(id)name {
    return [[[self thisBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
}

-(NSString *)username {
	return username;
}

-(void)setUsername:(NSString *)n {
	if([self username] != nil)
		[[self username] release];
	
	username = [n retain];
}

-(NSString *)statusText {
	return statusText;
}

-(void)setStatusText:(NSString *)t {
	if([self statusText] != nil)
		[[self statusText] release];
	
	statusText = [t retain];
}

-(NSString *)password {
	return password;
}

-(void)setPassword:(NSString *)p {
	if([self password] != nil)
		[[self password] release];
	
	password = [p retain];
}

-(NSString *)sessionUploadStatusText {
	return sessionUploadStatusText;
}

-(void)setSessionUploadStatusText:(NSString *)t {
	if([self sessionUploadStatusText] != nil)
		[[self sessionUploadStatusText] release];
	
	sessionUploadStatusText = [t retain];
}

-(NSArray *)albums {
	return albums;
}

-(void)setAlbums:(NSArray *)a {
	if(albums != a) {
		[albums release];
		albums = [a retain];
	}
}

-(NSArray *)categories {
	return categories;
}

-(void)setCategories:(NSArray *)v {
	if(v != categories) {
		[categories release];
		categories = [v retain];
	}
}

-(NSArray *)subcategories {
	return subcategories;
}

-(void)setSubcategories:(NSArray *)v {
	if(v != subcategories) {
		[subcategories release];
		subcategories = [v retain];
	}
}

-(NSNumber *)fileUploadProgress {
	return fileUploadProgress;
}

-(void)setFileUploadProgress:(NSNumber *)v {
	if([self fileUploadProgress] != nil)
		[[self fileUploadProgress] release];
	
	fileUploadProgress = [v retain];
}

-(NSNumber *)sessionUploadProgress {
	return sessionUploadProgress;
}

-(void)setSessionUploadProgress:(NSNumber *)v {
	if([self sessionUploadProgress] != nil)
		[[self sessionUploadProgress] release];

	sessionUploadProgress = [v retain];
}

-(SMEAlbum *)selectedAlbum {
	if([[albumsArrayController selectedObjects] count] > 0)
		return [[albumsArrayController selectedObjects] objectAtIndex:0];
	
	return nil;
}

-(NSPanel *)uploadPanel {
	return uploadPanel;
}

-(NSPanel *)loginPanel {
	return loginPanel;
}

#pragma mark iPhoto Export Manager Delegate methods

-(void)cancelExport {
	[[self session] stopUpload];
}

-(void)unlockProgress {
}

-(void)lockProgress {
}

-(void *)progress {
	return (void *)@""; 
}

-(void)performExport:(id)fp8 {
}

-(void)startExport:(id)fp8 {
	[self startUpload];
}

-(BOOL)validateUserCreatedPath:(id)fp8 {
    return NO;
}

-(BOOL)treatSingleSelectionDifferently {
    return NO;
}

-(id)defaultDirectory {
    return NSHomeDirectory();
}

-(id)defaultFileName {
	return nil;
}

-(id)getDestinationPath {
	return NSHomeDirectory();
}

-(BOOL)wantsDestinationPrompt {
    return NO;
}

-(id)requiredFileType {
	return @"album";
}

-(void)viewWillBeDeactivated {
	loginAttempted = NO;
	[[self session] logoutWithTarget:self callback:@selector(logoutDidComplete:)];
}

-(void)viewWillBeActivated {
	
	// try to login in a moment (i don't like this approach but don't know how to get a 'tab was focused'
	// notification, only a 'tab will be focused' notification
	[self performSelector:@selector(attemptLoginIfNecessary) 
			   withObject:nil
			   afterDelay:0.5
				  inModes:[NSArray arrayWithObjects: NSDefaultRunLoopMode, NSModalPanelRunLoopMode, nil]];
}

-(id)lastView {
	return lastView;
}

-(id)firstView {
	return firstView;
}

-(id)settingsView {
	return settingsBox;
}

-(void)clickExport {
}

- (BOOL)handlesMovieFiles {
	return YES;
}

#pragma mark Growl Delegate Methods

-(NSDictionary *)registrationDictionaryForGrowl {
	NSArray *allNotifications = [NSArray arrayWithObjects:
								 SMGrowlLogin,
								 SMGrowlLogout,
								 SMGrowlUploadCompleted,
								 SMGrowlUploadError,
								 SMGrowlImageUploaded,
								 nil];
	NSArray *defaultNotifications = [NSArray arrayWithObjects:
									 SMGrowlUploadCompleted,
									 SMGrowlUploadError,
									 nil];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			allNotifications, GROWL_NOTIFICATIONS_ALL,
			defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
			[NSNumber numberWithInt:1], GROWL_TICKET_VERSION,
			nil];
}

-(NSString *)applicationNameForGrowl {
	NSString *appName = [[[NSBundle bundleForClass:[SMEExportPlugin class]] infoDictionary] objectForKey:@"CFBundleDisplayName"];
	return appName;
}

-(NSData *)applicationIconDataForGrowl {
	return nil;
}

-(void)growlIsReady {
}

-(void)growlNotificationWasClicked:(id)clickContext {
	if(clickContext != nil)
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:(NSString *)clickContext]];
}

-(void)growlNotificationTimedOut:(id)clickContext {
}

#pragma mark Growl Notification

-(NSData *)notificationThumbnail:(NSData *)fullsizeImageData {
	NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithData:fullsizeImageData] autorelease];
	return [rep scaledRepToMaxWidth:120 maxHeight:120];	
}

-(NSString *)GrowlFrameworkPath {
	return [[[NSBundle bundleForClass:[self class]] privateFrameworksPath] stringByAppendingPathComponent:@"Growl.framework"];
}

-(NSString *)JSONFrameworkPath {
	return [[[NSBundle bundleForClass:[self class]] privateFrameworksPath] stringByAppendingPathComponent:@"JSON.framework"];
}

-(BOOL)isFrameworkLoaded:(NSString *)fwPath {
	NSBundle *frameworkBundle = [NSBundle bundleWithPath:fwPath];
	return frameworkBundle != nil && [frameworkBundle isLoaded];
}

-(BOOL)isGrowlLoaded {
	return [self isFrameworkLoaded:[self GrowlFrameworkPath]];
}

-(BOOL)isJSONLoaded {
	return [self isFrameworkLoaded:[self JSONFrameworkPath]];
}

-(void)loadJSON {
	if([self isJSONLoaded]) {
		return;
	}
	
	NSBundle *jsonBundle = [NSBundle bundleWithPath:[self JSONFrameworkPath]];
	if(jsonBundle)
		[jsonBundle load];
}

-(void)loadGrowl {
	if([self isGrowlLoaded])
		return;
	
	NSBundle *growlBundle = [NSBundle bundleWithPath:[self GrowlFrameworkPath]];
	if (growlBundle && [growlBundle load]) {
		// Register ourselves as a Growl delegate
		[GrowlApplicationBridge setGrowlDelegate:self];
	} else {
		NSLog(@"Could not load Growl.framework");
	}
}

-(void)unloadFramework:(NSString *)fwPath {
//	if(![self isFrameworkLoaded:fwPath])
//		return;

//	// NSBundle unload is strictly >= 10.5
//	NSBundle *bundle = [NSBundle bundleWithPath:fwPath];
//	if (bundle)
//		[bundle unload];			
}


-(void)unloadJSON {
	[self unloadFramework:[self JSONFrameworkPath]];
}

-(void)unloadGrowl {
	[self unloadFramework:[self GrowlFrameworkPath]];
}

-(void)notifyImageUploaded:(NSString *)imageFilename image:(NSData *)image{	
	[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"Image Uploaded", @"Growl notification title for image uploaded event")
								description:imageFilename
						   notificationName:SMGrowlImageUploaded
								   iconData:[self notificationThumbnail:image]
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

-(void)notifyLogin:(NSString *)account {
	[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"Logged In", @"Growl Notification title for logged in event")
								description:[NSString stringWithFormat:NSLocalizedString(@"User: %@", @"User logged in growl description"), account]
						   notificationName:SMGrowlLogin
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

-(void)notifyLougout:(NSString *)account {
	[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"Logged Out", @"Growl Message Title: (Logged Out)")
								description:[NSString stringWithFormat:NSLocalizedString(@"User: %@", @"User logged out growl description"), account]
						   notificationName:SMGrowlLogout
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

-(void)notifyUploadCompleted {
	[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"Upload Complete", @"Growl title for upload completed notification")
								description:[NSString stringWithFormat:NSLocalizedString(@"Uploaded %d images", @"Description for upload complete Growl message"), imagesUploaded]
						   notificationName:SMGrowlUploadCompleted
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:[[self uploadSiteUrl] description]];
}

-(void)notifyUploadError:(NSString *)error {
	[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"Upload Error", @"Growl title for upload error notification")
								description:error
						   notificationName:SMGrowlUploadError
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:nil];			
}

@end
