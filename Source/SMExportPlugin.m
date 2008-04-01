//
//  SMExportPlugin.m
//  SMExportPlugin
//
//  Created by Aaron Evans on 10/7/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import "SMExportPlugin.h"
#import "SMAccess.h"
#import "ExportPluginProtocol.h"
#import "ExportMgr.h"
#import "SMAlbumEditController.h"
#import "SMAccountManager.h"
#import "SMGlobals.h"
#import "NSBitmapImageRepAdditions.h"
#import "NSUserDefaultsAdditions.h"
#import "NSDataAdditions.h"
#import "NSStringAdditions.h"
#import "SMRequest.h"
#import "SMAlbum.h"
#import "SMAlbumInfo.h"

@interface SMExportPlugin (Private)
-(ExportMgr *)exportManager;
-(void)setExportManager:(ExportMgr *)m;
-(SMAccess *)smAccess;
-(void)setSMAccess:(SMAccess *)m;
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
-(SMAccountManager *)accountManager;
-(void)setAccountManager:(SMAccountManager *)mgr;
-(void)registerDefaults;
-(BOOL)loginAttempted;
-(void)setLoginAttempted:(BOOL)v;
-(void)performPostLoginTasks;
-(NSString *)loginSheetStatusMessage;
-(void)setLoginSheetStatusMessage:(NSString *)m;
-(void)setSelectedAccount:(NSString *)account;
-(NSString *)selectedAccount;
-(SMAlbum *)selectedAlbum;
-(NSString *)statusText;
-(void)setStatusText:(NSString *)t;
-(BOOL)isBusy;
-(void)setIsBusy:(BOOL)v;
-(BOOL)isDeletingAlbum;
-(void)setIsDeletingAlbum:(BOOL)v;	
-(void)login;
-(NSImage *)currentThumbnail;
-(void)setCurrentThumbnail:(NSImage *)d;
-(BOOL)loginSheetIsBusy;
-(void)setLoginSheetIsBusy:(BOOL)v;
-(void)setUploadRetryCount:(int)v;
-(int)uploadRetryCount;
-(void)setInsertionPoint:(NSWindow *)aWindow;
-(void)incrementUploadRetryCount;
-(void)resetUploadRetryCount;
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
-(SMAlbumEditController *)albumEditController;
-(void)setAlbumEditController:(SMAlbumEditController *)aController;	


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
-(void)notifyImageUploaded:(NSString *)imageFilename image:(NSData *)image;
-(NSData *)notificationThumbnail:(NSData *)fullsizeImageData;
@end

@interface SMExportPlugin (GrowlDelegate)
- (NSDictionary *) registrationDictionaryForGrowl;
- (NSString *) applicationNameForGrowl;
- (NSData *) applicationIconDataForGrowl;
- (void) growlIsReady;
- (void) growlNotificationWasClicked:(id)clickContext;
- (void) growlNotificationTimedOut:(id)clickContext;
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


// two additional attempts to upload an image if the upload fails
static const int UploadFailureRetryCount = 2; 
static const int AlbumUrlFetchRetryCount = 5;
static const int SMDefaultScaledHeight = 2592;
static const int SMDefaultScaledWidth = 2592;
static const NSTimeInterval SMDefaultUpdateCheckInterval = 24.0*60.0*60.0;

NSString *defaultRemoteVersionInfo = @"http://s3.amazonaws.com/smugmugexport/versionInfo.plist";

@implementation SMExportPlugin

-(id)initWithExportImageObj:(id)exportMgr {
	if((self = [super init]) == nil)
		return nil; // fail!
	
	exportManager = exportMgr;	
	[self loadGrowl];
	[NSBundle loadNibNamed: @"SmugMugExport" owner:self];
	
	
	[self setAccountManager:[SMAccountManager accountManager]];
	[self setSMAccess:[SMAccess smugmugManager]];
	[self setAlbumEditController:[SMAlbumEditController controller]];
	[albumEditController setDelegate:self];
	[[self smAccess] setDelegate:self];
	[self setLoginAttempted:NO];
	[self setSiteUrlHasBeenFetched:NO];
	[self setImagesUploaded:0];
	[self resetUploadRetryCount];
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
	[[self albumEditController] release];
	[[self postLogoutInvocation] release];
	[[self uploadSiteUrl] release];
	[[self smAccess] release];
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

-(SMUserDefaults *)defaults {
	return [NSUserDefaults smugMugUserDefaults];
}

+(void)initialize {
	[self initializeLocalizableStrings];
	
	NSMutableDictionary *defaultsDict = [NSMutableDictionary dictionary];
	[defaultsDict setObject:ExistingAlbumTabIdentifier forKey:SMESelectedTabIdDefaultsKey];
	[defaultsDict setObject:[NSArray array] forKey:SMEAccountsDefaultsKey];
	[defaultsDict setObject:@"yes" forKey:SMOpenInBrowserAfterUploadCompletion];
	[defaultsDict setObject:@"yes" forKey:SMCloseExportWindowAfterUploadCompletion];
	[defaultsDict setObject:@"yes" forKey:SMStorePasswordInKeychain];
	[defaultsDict setObject:@"no" forKey:SMUseKeywordsAsTags];
	[defaultsDict setObject:@"yes" forKey:SMShowAlbumDeleteAlert];
	[defaultsDict setObject:@"no" forKey:SMEnableNetworkTracing];
	[defaultsDict setObject:@"yes" forKey:SMEnableAlbumFetchDelay];
	[defaultsDict setObject:[NSNumber numberWithFloat:[NSBitmapImageRep defaultJpegScalingFactor]] forKey:SMJpegQualityFactor];
	[defaultsDict setObject:[NSNumber numberWithInt:0] forKey:SMSelectedScalingTag];
	[defaultsDict setObject:[NSNumber numberWithInt: SMDefaultScaledWidth] forKey:SMImageScaleWidth];
	[defaultsDict setObject:[NSNumber numberWithInt: SMDefaultScaledHeight] forKey:SMImageScaleHeight];
	[defaultsDict setObject:defaultRemoteVersionInfo forKey:SMRemoteInfoURL];
	[defaultsDict setObject:@"yes" forKey:SMCheckForUpdates];
	[defaultsDict setObject:SMUploadedFilenameOptionFilename forKey:SMUploadedFilename];
	[defaultsDict setObject:[NSNumber numberWithBool:NO] forKey:SMUserHasSeenUpdatePolicy];
	[defaultsDict setObject:[NSNumber numberWithBool:NO] forKey:SMAutomaticallyCheckForUpdates];
	[defaultsDict setObject:[NSDate distantPast] forKey:SMLastUpdateCheck];
	[defaultsDict setObject:[NSNumber numberWithInt:SMDefaultUpdateCheckInterval] forKey:SMUpdateCheckInterval];
	[defaultsDict setObject:[NSNumber numberWithBool:NO] forKey:SMContinueUploadOnFileIOError];
	
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
	NSString *versionString = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
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
	if([self sheetIsDisplayed])
		return;
	
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
	[[self defaults] setObject:[NSNumber numberWithBool:selectedButton = NSAlertFirstButtonReturn] forKey:SMAutomaticallyCheckForUpdates];
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
		NSLog(@"Cannot check for updates because a check is already in progress.");
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
						   withObject:[[NSDictionary alloc] initWithObjectsAndKeys: 
									   remoteInfo , @"remoteInfo",
									   displayAlertIfNoUpdateAvailable, @"displayAlertIfNoUpdateAvailable", nil]
						waitUntilDone:NO];
	[pool release];
}

-(NSBundle *)thisBundle {
	return [NSBundle bundleForClass:[SMExportPlugin class]];
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
		[args release];
		return;
	}
	
	NSString *localVersion = [[[self thisBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
	if(localVersion == nil) {
		NSLog(@"undefined bundle version found during update.");
		NSBeep();
		[args release];
		return;
	}

	if([localVersion compareVersionToVersion:remoteVersion] == NSOrderedAscending)
		[self displayUpdateAvailable:remoteInfo];
	else if([displayAlertIfNoUpdateAvailable boolValue])
		[self displayNoUpdateAvailable];

	[args release];
}

-(void)displayNoUpdateAvailable {
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:NSLocalizedString(@"Dismiss", @"Dismiss button to dismiss no new version available button.")];
	[alert setMessageText: [NSString stringWithFormat:NSLocalizedString(@"You are running the newest version of SmugMugExport (%@).", @"Message text for no update available text"), [[[self thisBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey]]];
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


#pragma mark Login Methods

-(void)attemptLoginIfNecessary {
	// try to automatically show the login sheet 
	
	if([loginPanel isVisible]) // don't try to show the login sheet if it's already showing
		return;
	
	if(![[[self exportManager] window] isKeyWindow])
		return;
	
	/* don't try to login if we're already logged in or attempting to login */
	if([[self smAccess] isLoggedIn] ||
	   [[self smAccess] isLoggingIn])
		return;
	
	/*
	 * Show the login window if we're not logged in and there is no way to autologin
	 */
	if(![[self smAccess] isLoggedIn] && 
	   ![[self accountManager] canAttemptAutoLogin]) {
		
		// show the login panel after some delay
		[self showLoginSheet:self];
		return;
	}
	
	/*
	 *  If we have a saved password for the previously selected account, log in to that account.
	 */
	if(![[self smAccess] isLoggedIn] && 
	   ![[self smAccess] isLoggingIn] &&
	   [[[self accountManager] accounts] count] > 0 &&
	   [[self accountManager] selectedAccount] != nil &&
	   ![self loginAttempted] &&
	   [[self accountManager] passwordExistsInKeychainForAccount:[[self accountManager] selectedAccount]]) {

		[self setLoginAttempted:YES];
		[self performSelectorOnMainThread:@selector(setIsBusyWithNumber:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];	
		[self performSelectorOnMainThread:@selector(setStatusText:) withObject:NSLocalizedString(@"Logging in...", @"Status text for logginng in") waitUntilDone:NO];
		[[self smAccess] setUsername:[[self accountManager] selectedAccount]];
		[[self smAccess] setPassword:[[self accountManager] passwordForAccount:[[self accountManager] selectedAccount]]]; 
		[[self smAccess] login]; // gets asyncronous callback
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
	[self setLoginSheetIsBusy:NO];
	[NSApp endSheet:loginPanel];
}

/** called from the login sheet.  takes username/password values from the textfields */
-(IBAction)performLoginFromSheet:(id)sender {
	if(IsEmpty([self username]) ||
	   IsEmpty([self password])) {
		NSBeep();
	}
	
	[self setLoginSheetStatusMessage:NSLocalizedString(@"Logging In...", @"log in status string")];
	[self setLoginSheetIsBusy:YES];
	[[self smAccess] setUsername:[self username]];
	[[self smAccess] setPassword:[self password]];
	[[self smAccess] login]; // gets asyncronous callback
}

-(void)loginDidComplete:(NSNumber *)wasSuccessful {
	[self setIsBusy:NO];
	[self setStatusText:@""];
	[self setLoginSheetIsBusy:NO];
	[self setLoginSheetStatusMessage:@""];
	
	if(![wasSuccessful boolValue]) {
		[self setLoginSheetStatusMessage:NSLocalizedString(@"Login Failed", @"Status text for failed login")];
		/* we act like we haven't atttempted a log in if the login fails.  
		*/
		[self setLoginAttempted:NO];
		return;
	}
	
	// attempt to login, if successful add to keychain
	[[self accountManager] addAccount:[[self smAccess] username] withPassword:[[self smAccess] password]];
	
	[self setSelectedAccount:[[self smAccess] username]];
	[NSApp endSheet:loginPanel];
	
	[self notifyLogin:[self selectedAccount]];
	[[self smAccess] buildCategoryList];
	[[self smAccess] buildSubCategoryList];
}


-(void)loginDidEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

#pragma mark Logout 
-(void)logoutDidComplete:(NSNumber *)wasSuccessful {
	if(![wasSuccessful boolValue])
		[self presentError:NSLocalizedString(@"Logout failed.", @"Error message to display when logout fails.")];
	else if([self postLogoutInvocation] != nil) {
		[self notifyLougout:[self selectedAccount]];
		[[self postLogoutInvocation] invokeWithTarget:self];
	}
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

	if(![[self smAccess] isLoggedIn] || [[self smAccess] isLoggingIn]) {
		NSBeep();
		return;
	}
	
	[albumEditController showAlbumCreateSheet:self forWindow:[[self exportManager] window]];
}

-(void)createNewAlbumDidComplete:(NSNumber *)wasSuccessful {

	[[self albumEditController] setIsBusy:NO];
	if([wasSuccessful boolValue]) {
		[albumEditController closeSheet];
		[albumsArrayController setSelectionIndex:0]; // default to selecting the new album which should be album 0
	} else {
		// album creation occurs in a sheet, don't try to show an error dialog in another sheet...
		NSBeep();
		
		//[self presentError:NSLocalizedString(@"Album creation failed.", @"Error message to display when album creation fails.")];
	}
}

-(void)createAlbum:(SMAlbumInfo *)albumInfo {
	if(IsEmpty([albumInfo title])) {
		NSBeep();
		return;
	}
	
	[[self albumEditController] setIsBusy:YES];
	[[self smAccess] createNewAlbum:albumInfo];
	
	return;
}

#pragma mark Delete Album

-(IBAction)removeAlbum:(id)sender {
	if([[self selectedAlbum] albumId] == nil) { // no album is selected
		NSBeep();
		return;
	}
	
	// not properly logged in, can't remove an album
	if(![[self smAccess] isLoggedIn] || [[self smAccess] isLoggingIn]) {
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
	[[self smAccess] deleteAlbum:[[self selectedAlbum] ref]];
}	

-(void)sheetDidDismiss:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
	
}

-(void)deleteAlbumSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {

	if(returnCode == NSAlertDefaultReturn) {
		[self beginAlbumDelete];
	}
}

-(void)deleteAlbumDidComplete:(NSNumber *)wasSuccessful {
	if(![wasSuccessful boolValue])
		[self presentError:NSLocalizedString(@"Album deletion failed.", 
											 @"Error message to display when album delete fails.")];
	
	[self setIsBusy:NO];
	[self setIsDeletingAlbum:NO];
	[self setStatusText:@""];	
}

#pragma mark Album Edit
-(IBAction)showEditAlbumSheet:(id)sender {
	if([self selectedAlbum] == nil) {
		NSBeep();
		return;
	}
	
	[self setIsBusy:YES];
	[[self smAccess] fetchAlbumInfo:[[self selectedAlbum] ref]];		
}

-(void)albumInfoFetchDidComplete:(NSNumber *)wasSuccessful forAlbum:(SMAlbumRef *)ref info:(SMAlbumInfo *)info {
	[self setIsBusy:NO];
	if([wasSuccessful boolValue])
		[albumEditController showAlbumEditSheet:self 
									  forWindow:[[self exportManager] window] 
									   forAlbum:ref
								  withAlbumInfo:info];
	else {
		NSBeep();
	}
}

-(void)albumsFetchDidComplete:(NSNumber *)wasSuccessful {
	[[self albumEditController] setIsBusy:NO];
	[[self albumEditController] closeSheet];
}

-(void)albumEditDidComplete:(NSNumber *)wasSuccessful forAlbum:(SMAlbumRef *)ref {	
	// update fields for albums here...
	if([wasSuccessful boolValue]) {
		[[self smAccess] fetchAlbums];
	} else {
		[[self albumEditController] setIsBusy:NO];
		[[self albumEditController] closeSheet];
	}
}

-(void)editAlbum:(SMAlbumInfo *)albumInfo {
	[[self albumEditController] setIsBusy:YES];
	[[self smAccess] editAlbum:albumInfo];
}

#pragma mark Image Url Fetching

-(void)imageUrlFetchDidCompleteForImageRef:(SMImageRef *)ref imageUrls:(NSDictionary *)imageUrls {
	
	if(imageUrls == nil && [self albumUrlFetchAttemptCount] < AlbumUrlFetchRetryCount) {
		[self incrementAlbumUrlFetchAttemptCount];
	
		// try again
		[[self smAccess] performSelector:@selector(fetchImageUrls:) 
							  withObject:ref
							  afterDelay:2.0
								 inModes:[NSArray arrayWithObjects: NSDefaultRunLoopMode, NSModalPanelRunLoopMode, nil]];		
		return;
	}
	
	NSString *siteUrlString = [imageUrls objectForKey:@"AlbumURL"];
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

-(void)categoryGetDidComplete:(NSNumber *)wasSuccessful {
	if(![wasSuccessful boolValue])
		[self presentError:NSLocalizedString(@"Could not fetch categories.", @"Error message to display when category get fails.")];
}

#pragma mark Upload Methods

-(void)startUpload {
	if([self sheetIsDisplayed]) // this should be impossible
		return;

	if(![[self smAccess] isLoggedIn]) {
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
	[self resetUploadRetryCount];
	[self setUploadSiteUrl:nil];
	[self setSiteUrlHasBeenFetched:NO];
	
	[self uploadCurrentImage];
}

-(NSData *)imageDataForPath:(NSString *)pathToImage errorString:(NSString **)err {
	
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
	
	if(isJpeg && ShouldScaleImages()) {
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
	
	NSString *nextFile = [[self exportManager] imagePathAtIndex:[self imagesUploaded]];
	NSString *error = nil;
	NSData *imageData = [self imageDataForPath:nextFile errorString:&error];
	if(imageData == nil) {
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
	[[self smAccess] uploadImageData:imageData
							filename:filename
							   album:[[self selectedAlbum] ref]
							 caption:[[self exportManager] imageCommentsAtIndex:[self imagesUploaded]]
							keywords:[[self exportManager] imageKeywordsAtIndex:[self imagesUploaded]]];		
	
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

-(void)uploadDidFail:(NSData *)imageData reason:(NSString *)errorText {

	[self notifyUploadError:errorText];
	
	if([self uploadRetryCount] < UploadFailureRetryCount) {
		// if an error occurred, retry up to UploadFailureRetryCount times
		
		[self incrementUploadRetryCount];
		[self setSessionUploadStatusText:[NSString stringWithFormat:NSLocalizedString(@"Retrying upload of image %d of %d\nReason: %@", @"Retry upload progress"), [self imagesUploaded] + 1, [[self exportManager] imageCount], errorText]];
		[self uploadCurrentImage];
		return;
	} else {
		// our max retries have been hit, stop uploading
		[self performUploadCompletionTasks:NO];
		NSString *errorString = NSLocalizedString(@"Image upload failed (%@).", @"Error message to display when upload fails.");
		[self presentError:[NSString stringWithFormat:errorString, errorText]];
		return;
	}
}

-(void)uploadMadeProgress:(NSData *)imageData bytesWritten:(long)bytesWritten ofTotalBytes:(long)totalBytes {	
	float progressForFile = MIN(100.0, ceil(100.0*(float)bytesWritten/(float)totalBytes));
	[self setFileUploadProgress:[NSNumber numberWithFloat:progressForFile]];
	
	float baselinePercentageCompletion = 100.0*((float)[self imagesUploaded])/((float)[[self exportManager] imageCount]);
	float estimatedFileContribution = (100.0/((float)[[self exportManager] imageCount]))*((float)bytesWritten)/((float)totalBytes);
	[self setSessionUploadProgress:[NSNumber numberWithFloat:MIN(100.0, ceil(baselinePercentageCompletion+estimatedFileContribution))]];
	
	[self setImageUploadProgressText:[NSString stringWithFormat:@"%0.0fKB of %0.0fKB", bytesWritten/1024.0, totalBytes/1024.0]];
}

-(void)uploadWasCanceled {
	[self performUploadCompletionTasks:NO];
}

-(void)uploadNextImage {
	// onto the next image
 	[self resetUploadRetryCount];
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

-(void)uploadDidSucceeed:(NSData *)imageData imageRef:(SMImageRef *)ref requestDict:(NSDictionary *)requestDict {	
	if(![self siteUrlHasBeenFetched]) {
		[self resetAlbumUrlFetchAttemptCount];
		[self setSiteUrlHasBeenFetched:NO];
		[[self smAccess] fetchImageUrls:ref];
	}
	
	[self notifyImageUploaded:[requestDict objectForKey:@"filename"]
						image:[requestDict objectForKey:SMUploadKeyImageData]];
	[self uploadNextImage];
}

-(void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

-(IBAction)cancelUpload:(id)sender {
	[self cancelExport];
}

#pragma mark Get and Set properties

-(NSArray *)categories {
	return [[self smAccess] categories];
}

-(NSArray *)subcategories {
	return [[self smAccess] subcategories];
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
	if([[self smAccess] isLoggedIn]) {
		// handle the rest of the account changed tasks after we logout
		NSInvocation *inv = [NSInvocation invocationWithMethodSignature:
			[self methodSignatureForSelector:@selector(accountChangedTasks:)]];
		[inv setSelector:@selector(accountChangedTasks:)];
		[self setPostLogoutInvocation:inv];	
		[[self postLogoutInvocation] setArgument:&account atIndex:2];
		[inv retainArguments];
		
		[[self smAccess] logout]; // aynchronous callback
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

-(BOOL)loginSheetIsBusy {
	return loginSheetIsBusy;
}

-(void)setLoginSheetIsBusyWithNumber:(NSNumber *)v {
	[self setLoginSheetIsBusy:[v boolValue]];
}

-(void)setLoginSheetIsBusy:(BOOL)v {
	loginSheetIsBusy = v;
}

-(void)setUploadRetryCount:(int)v {
	uploadRetryCount = v;
}

-(int)uploadRetryCount {
	return uploadRetryCount;
}

-(void)incrementUploadRetryCount {
	[self setUploadRetryCount:[self uploadRetryCount]+1];
}

-(void)resetUploadRetryCount {
	[self setUploadRetryCount:0];
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

-(SMAccountManager *)accountManager {
	return accountManager;
}

-(void)setAccountManager:(SMAccountManager *)mgr {
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


-(SMAccess *)smAccess {
	return smAccess;
}

-(void)setSMAccess:(SMAccess *)m {
	if([self smAccess] != nil)
		[[self smAccess] release];
	
	smAccess = [m retain];
}

-(SMAlbumEditController *)albumEditController {
	return albumEditController;
}

-(void)setAlbumEditController:(SMAlbumEditController *)aController {
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

-(SMAlbum *)selectedAlbum {
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
	[[self smAccess] stopUpload];
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
//	[[self smAccess] logout];
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
	return NO;
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
	NSString *appName = [[[NSBundle bundleForClass:[SMExportPlugin class]] infoDictionary] objectForKey:@"CFBundleDisplayName"];
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

-(BOOL)isGrowlLoaded {
	NSBundle *frameworkBundle = [NSBundle bundleWithPath:[self GrowlFrameworkPath]];
	return frameworkBundle != nil && [frameworkBundle isLoaded];
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

-(void)unloadGrowl {
	if(![self isGrowlLoaded])
		return;

	// NSBundle unload is strictly >= 10.5
//	NSBundle *growlBundle = [NSBundle bundleWithPath:[self GrowlFrameworkPath]];
//	if (growlBundle)
//		[growlBundle unload];		
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
