//
//  SmugmugExport.m
//  SmugMugExport
//
//  Created by Aaron Evans on 10/7/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import "SmugMugExport.h"
#import "SmugMugManager.h"
#import "ExportPluginProtocol.h"
#import "ExportMgr.h"
#import "AccountManager.h"
#import "Globals.h"
#import "NSUserDefaultsAdditions.h"

@interface SmugMugExport (Private)
-(ExportMgr *)exportManager;
-(void)setExportManager:(ExportMgr *)m;
-(SmugMugManager *)smugMugManager;
-(void)setSmugMugManager:(SmugMugManager *)m;
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
-(AccountManager *)accountManager;
-(void)setAccountManager:(AccountManager *)mgr;
-(void)registerDefaults;
-(BOOL)loginAttempted;
-(void)setLoginAttempted:(BOOL)v;
-(void)performPostLoginTasks;
-(NSString *)loginSheetStatusMessage;
-(void)setLoginSheetStatusMessage:(NSString *)m;
-(void)setSelectedAccount:(NSString *)account;
-(NSString *)selectedAccount;
-(NSDictionary *)selectedAlbum;
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
-(void)incrementUploadRetryCount;
-(void)resetUploadRetryCount;
-(void)presentError:(NSString *)errorText;
-(BOOL)isUploading;
-(void)setIsUploading:(BOOL)v;
-(void)beginAlbumDelete;
-(BOOL)browserOpenedInGallery;
-(void)setBrowserOpenedInGallery:(BOOL)v;	
-(BOOL)isCreatingAlbum;
-(void)setIsCreatingAlbum:(BOOL)v;
-(NSString *)imageUploadProgressText;
-(void)setImageUploadProgressText:(NSString *)text;
-(NSPanel *)newAlbumSheet;
-(NSPanel *)uploadPanel;
-(NSPanel *)loginPanel;
-(BOOL)sheetIsDisplayed;
-(void)uploadNextImage;
-(void)openLastGalleryInBrowser;
-(NSInvocation *)postLogoutInvocation;
-(void)setPostLogoutInvocation:(NSInvocation *)inv;
-(void)accountChangedTasks:(NSString *)account;

-(BOOL)siteUrlHasBeenFetched;
-(void)setSiteUrlHasBeenFetched:(BOOL)v;
-(NSURL *)uploadSiteUrl;
-(void)setUploadSiteUrl:(NSURL *)url;
@end

NSLock *GalleryOpenLock = nil;

// Globals
NSString *AlbumID = @"id";
NSString *CategoryID = @"id";
NSString *SubCategoryID = @"id";

// UI keys
NSString *ExistingAlbumTabIdentifier = @"existingAlbum";
NSString *NewAlbumTabIdentifier = @"newAlbum";
NSString *NewAccountLabel = @"New Account...";

// defaults keys
NSString *SMESelectedTabIdDefaultsKey = @"SMESelectedTabId";
NSString *SMEAccountsDefaultsKey = @"SMEAccounts";
NSString *SMESelectedAccountDefaultsKey = @"SMESelectedAccount";
NSString *SMOpenInBrowserAfterUploadCompletion = @"SMOpenInBrowserAfterUploadCompletion";
NSString *SMStorePasswordInKeychain = @"SMStorePasswordInKeychain";
NSString *SMSelectedScalingTag = @"SMSelectedScalingTag";
NSString *SMUseKeywordsAsTags = @"SMUseKeywordsAsTags";
NSString *SMImageScaleWidth = @"SMImageScaleWidth";
NSString *SMImageScaleHeight = @"SMImageScaleHeight";
NSString *SMShowAlbumDeleteAlert = @"SMShowAlbumDeleteAlert";
NSString *SMEnableNetworkTracing = @"SMEnableNetworkTracing";
NSString *SMEnableAlbumFetchDelay = @"SMEnableAlbumFetchDelay";
NSString *SMJpegQualityFactor = @"SMJpegQualityFactor";

static int UploadFailureRetryCount = 3;
const float DefaultJpegScalingFactor = 0.9;

@implementation SmugMugExport

-(id)initWithExportImageObj:(id)exportMgr {
	if(![super init])
		return nil;
	
	exportManager = exportMgr;	
	[NSBundle loadNibNamed: @"SmugMugExport" owner:self];
	
	[self setAccountManager:[AccountManager accountManager]];
	[self performSelectorOnMainThread:@selector(setSmugMugManager:)  withObject:[SmugMugManager smugmugManager] waitUntilDone:YES];
	[[self smugMugManager] setDelegate:self];

	[self setLoginAttempted:NO];
	[self setSiteUrlHasBeenFetched:NO];
	[self setImagesUploaded:0];
	[self resetUploadRetryCount];
	[self setIsUploading:NO];
	[self setIsCreatingAlbum:NO];
	
	return self;
}

-(void)dealloc {
	[[self postLogoutInvocation] release];
	[[self uploadSiteUrl] release];
	[[self smugMugManager] release];
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

-(SmugMugUserDefaults *)defaults {
	return [NSUserDefaults smugMugUserDefaults];
}

+(void)initialize {
	NSMutableDictionary *defaultsDict = [NSMutableDictionary dictionary];
	[defaultsDict setObject:ExistingAlbumTabIdentifier forKey:SMESelectedTabIdDefaultsKey];
	[defaultsDict setObject:[NSArray array] forKey:SMEAccountsDefaultsKey];
	[defaultsDict setObject:@"yes" forKey:SMOpenInBrowserAfterUploadCompletion];
	[defaultsDict setObject:@"yes" forKey:SMStorePasswordInKeychain];
	[defaultsDict setObject:@"no" forKey:SMUseKeywordsAsTags];
	[defaultsDict setObject:@"yes" forKey:SMShowAlbumDeleteAlert];
	[defaultsDict setObject:@"no" forKey:SMEnableNetworkTracing];
	[defaultsDict setObject:@"yes" forKey:SMEnableAlbumFetchDelay];
	[defaultsDict setObject:[NSNumber numberWithFloat:DefaultJpegScalingFactor] forKey:SMJpegQualityFactor];
	[defaultsDict setObject:[NSNumber numberWithInt:0] forKey:SMSelectedScalingTag];
	
	[[NSUserDefaults smugMugUserDefaults] registerDefaults:defaultsDict];
	[[self class] setKeys:[NSArray arrayWithObject:@"accountManager.accounts"] triggerChangeNotificationsForDependentKey:@"accounts"];
	[[self class] setKeys:[NSArray arrayWithObject:@"accountManager.selectedAccount"] triggerChangeNotificationsForDependentKey:@"selectedAccount"];
	
	GalleryOpenLock = [[NSLock alloc] init];
}

-(void)awakeFromNib {
}

-(BOOL)sheetIsDisplayed {
	return [[self newAlbumSheet] isVisible] ||
		[[self loginPanel] isVisible] ||
		[[self uploadPanel] isVisible] ||
		errorAlertSheetIsVisisble;
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

#pragma mark Login Methods

-(void)attemptLoginIfNecessary {
	// try to automatically show the login sheet 
	
	if([loginPanel isVisible]) // don't try to show the login sheet if it's already showing
		return;
	
	if(![[[self exportManager] window] isKeyWindow])
		return;
	
	/* don't try to login if we're already logged in or attempting to login */
	if([[self smugMugManager] isLoggedIn] ||
	   [[self smugMugManager] isLoggingIn])
		return;
	
	/*
	 * Show the login window if we're not logged in and there is no way to autologin
	 */
	if(![[self smugMugManager] isLoggedIn] && 
	   ![[self accountManager] canAttemptAutoLogin]) {
		
		// show the login panel after some delay
		[self showLoginSheet:self];
		return;
	}
	
	/*
	 *  If we have a saved password for the previously selected account, log in to that account.
	 */
	if(![[self smugMugManager] isLoggedIn] && 
	   ![[self smugMugManager] isLoggingIn] &&
	   [[[self accountManager] accounts] count] > 0 &&
	   [[self accountManager] selectedAccount] != nil &&
	   ![self loginAttempted] &&
	   [[self accountManager] passwordExistsInKeychainForAccount:[[self accountManager] selectedAccount]]) {

		[self setLoginAttempted:YES];
		[self performSelectorOnMainThread:@selector(setIsBusyWithNumber:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];	
		[self performSelectorOnMainThread:@selector(setStatusText:) withObject:NSLocalizedString(@"Logging in...", @"Status text for logginng in") waitUntilDone:NO];
		[[self smugMugManager] setUsername:[[self accountManager] selectedAccount]];
		[[self smugMugManager] setPassword:[[self accountManager] passwordForAccount:[[self accountManager] selectedAccount]]]; 
		[[self smugMugManager] login]; // gets asyncronous callback
	}
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

	if([[loginPanel firstResponder] respondsToSelector:@selector(setString:)]) {
		// hack to get insertion point to appear in textfield
		[(NSTextView *)[loginPanel firstResponder] setString:@""];
	}
		
	// mark that we've shown the user the login sheet at least once
	[self setLoginAttempted:YES];
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
	[[self smugMugManager] setUsername:[self username]];
	[[self smugMugManager] setPassword:[self password]];
	[[self smugMugManager] login]; // gets asyncronous callback
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
	[[self accountManager] addAccount:[[self smugMugManager] username] withPassword:[[self smugMugManager] password]];
	
	[self setSelectedAccount:[[self smugMugManager] username]];
	[NSApp endSheet:loginPanel];
	
	[[self smugMugManager] buildCategoryList];
	[[self smugMugManager] buildSubCategoryList];
}


-(void)loginDidEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

#pragma mark Logout 
-(void)logoutDidComplete:(NSNumber *)wasSuccessful {
	if(![wasSuccessful boolValue])
		[self presentError:NSLocalizedString(@"Logout failed.", @"Error message to display when logout fails.")];
	else if([self postLogoutInvocation] != nil) {
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

-(IBAction)addNewAlbum:(id)sender { // opens the create album sheet
	
	if(![[[self exportManager] window] isVisible])
		return;

	if([self sheetIsDisplayed])
		return;

	if(![[self smugMugManager] isLoggedIn] || [[self smugMugManager] isLoggingIn]) {
		NSBeep();
		return;
	}
	
	[[self smugMugManager] clearAlbumCreationState];
	[NSApp beginSheet:[self newAlbumSheet]
	   modalForWindow:[[self exportManager] window]
		modalDelegate:self
	   didEndSelector:@selector(newAlbumDidEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];

	if([[[self newAlbumSheet] firstResponder] respondsToSelector:@selector(setString:)]) {
		// hack to get insertion point to appear in textfield
		[(NSTextView *)[[self newAlbumSheet] firstResponder] setString:@""];
	}
}

-(IBAction)cancelNewAlbumSheet:(id)sender {
	[NSApp endSheet:[self newAlbumSheet]];
}

-(void)newAlbumDidEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];
}

-(BOOL)isCreatingAlbum {
	return isCreatingAlbum;
}

-(void)setIsCreatingAlbum:(BOOL)v {
	isCreatingAlbum = v;
}

-(void)createNewAlbumDidComplete:(NSNumber *)wasSuccessful {

	[self setIsCreatingAlbum:NO];
	if([wasSuccessful boolValue]) {
		[NSApp endSheet:[self newAlbumSheet]];
		[albumsArrayController setSelectionIndex:0]; // default to selecting the new album which should be album 0
	} else {
		// album creation occurs in a sheet, don't try to show an error dialog in another sheet...
		NSBeep();
		
		//[self presentError:NSLocalizedString(@"Album creation failed.", @"Error message to display when album creation fails.")];
	}
}


-(IBAction)createAlbum:(id)sender {
	[self setIsCreatingAlbum:YES];
	[[self smugMugManager] createNewAlbum];
}

#pragma mark Delete Album

-(IBAction)removeAlbum:(id)sender {
	if([[self selectedAlbum] objectForKey:AlbumID] == nil) { // no album is selected
		NSBeep();
		return;
	}
	
	// not properly logged in, can't remove an album
	if(![[self smugMugManager] isLoggedIn] || [[self smugMugManager] isLoggingIn]) {
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
	[[self smugMugManager] deleteAlbum:[[self selectedAlbum] objectForKey:AlbumID]];
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

#pragma mark Image Url Fetching

-(void)imageUrlFetchDidComplete:(NSDictionary *)imageUrls {
	NSString *siteUrlString = [imageUrls objectForKey:@"AlbumURL"];
	if(siteUrlString != nil) {
		[self setUploadSiteUrl:[NSURL URLWithString:siteUrlString]];
	} else {
		[self setSiteUrlHasBeenFetched:NO];
	}
	
	/* it's possible that we're done uploading the images for an album and *then* we
		receive this callback notifying us of the url for the album.  In that case,
	   we open the gallery in the browser. Otherwise, this happens when the upload
		completes
		*/
	[GalleryOpenLock lock];
	if(![self isUploading] && 
	   [self uploadSiteUrl] != nil &&
	   ![self browserOpenedInGallery] &&
	   [[[NSUserDefaults smugMugUserDefaults] valueForKey:SMOpenInBrowserAfterUploadCompletion] boolValue]) {
		[self openLastGalleryInBrowser];
	}
	[GalleryOpenLock unlock];
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

	if(![[self smugMugManager] isLoggedIn]) {
		NSBeep();
		return;
	}
	
	uploadCancelled = NO;
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
	[img setScalesWhenResized:YES];
	[self setCurrentThumbnail:img];
	[self resetUploadRetryCount];
	[self setUploadSiteUrl:nil];
	[self setSiteUrlHasBeenFetched:NO];
	
	[self uploadNextImage];
}

-(void)uploadNextImage {
	
	NSString *selectedAlbumId = [[[self selectedAlbum] objectForKey:AlbumID] stringValue];
	if([[self exportManager] respondsToSelector:@selector(imageCaptionAtIndex:)]) {
		// iPhoto <=6
		[[self smugMugManager] uploadImageAtPath:[[self exportManager] imagePathAtIndex:[self imagesUploaded]]
									 albumWithID:selectedAlbumId
										   title:[[self exportManager] imageCaptionAtIndex:[self imagesUploaded]]
										comments:[[self exportManager] imageCommentsAtIndex:[self imagesUploaded]]
										keywords:[[self exportManager] imageKeywordsAtIndex:[self imagesUploaded]]];		
	} else {
		// iPhoto 7
		[[self smugMugManager] uploadImageAtPath:[[self exportManager] imagePathAtIndex:[self imagesUploaded]]
									 albumWithID:selectedAlbumId
										   title:[[self exportManager] imageTitleAtIndex:[self imagesUploaded]]
										comments:[[self exportManager] imageCommentsAtIndex:[self imagesUploaded]]
										keywords:[[self exportManager] imageKeywordsAtIndex:[self imagesUploaded]]];
	}	
}


-(void)performUploadCompletionTasks:(BOOL)wasSuccessful {
	[NSApp endSheet:uploadPanel];
	[[self exportManager] cancelExportBeforeBeginning];
	[self setIsUploading:NO];

	[GalleryOpenLock lock];
	// if this really bothers you you can set your preferences to not open the page in the browser
	if(![[[NSUserDefaults smugMugUserDefaults] valueForKey:SMOpenInBrowserAfterUploadCompletion] boolValue]) {
		[GalleryOpenLock unlock];
		return;
	}
	
	if([self uploadSiteUrl] != nil && ![self browserOpenedInGallery]) {
		[self setBrowserOpenedInGallery:YES];
		[[NSWorkspace sharedWorkspace] openURL:uploadSiteUrl];
	}
	[GalleryOpenLock unlock];
	
}

-(void)uploadDidCompleteWithArgs:(NSArray *)args {
//	NSString *aFullPathToImage = [args objectAtIndex:0];
	NSString *imageId = [args objectAtIndex:1];
	NSString *error = [args count] > 2 ? [args objectAtIndex:2] : nil;
	
	if(uploadCancelled) {
		[self performUploadCompletionTasks:NO];
		return; // stop uploading
	}

	if(error == nil) {
		@synchronized(self) {
			if(!siteUrlHasBeenFetched) {
				[self setSiteUrlHasBeenFetched:NO];
				[[self smugMugManager] fetchImageUrls:imageId];
			}
		}
	} else  if(error != nil && [self uploadRetryCount] < UploadFailureRetryCount) {
		// if an error occurred, retry up to UploadFailureRetryCount times

		[self incrementUploadRetryCount];
		[self setSessionUploadStatusText:[NSString stringWithFormat:NSLocalizedString(@"Retrying upload of image %d of %d", @"Retry upload progress"), [self imagesUploaded] + 1, [[self exportManager] imageCount]]];
		

		[self uploadNextImage];		
		return;
	} else if (error != nil) {
		// our max retries have been hit, stop uploading
		[self performUploadCompletionTasks:NO];
		NSString *errorString = NSLocalizedString(@"Image upload failed (%@).", @"Error message to display when upload fails.");
		[self presentError:[NSString stringWithFormat:errorString, error]];
		return;
	}

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

		[self uploadNextImage];		
	}
}

-(void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

-(void)uploadMadeProgressWithArgs:(NSArray *)args {
//	NSString *pathToFile = [args objectAtIndex:0];
	long bytesWritten = [[args objectAtIndex:1] longValue];
	long totalBytes = [[args objectAtIndex:2] longValue];

	float progressForFile = MIN(100.0, ceil(100.0*(float)bytesWritten/(float)totalBytes));
	[self setFileUploadProgress:[NSNumber numberWithFloat:progressForFile]];

	float baselinePercentageCompletion = 100.0*((float)[self imagesUploaded])/((float)[[self exportManager] imageCount]);
	float estimatedFileContribution = (100.0/((float)[[self exportManager] imageCount]))*((float)bytesWritten)/((float)totalBytes);
	[self setSessionUploadProgress:[NSNumber numberWithFloat:MIN(100.0, ceil(baselinePercentageCompletion+estimatedFileContribution))]];

	[self setImageUploadProgressText:[NSString stringWithFormat:@"%0.0fKB of %0.0fKB", bytesWritten/1024.0, totalBytes/1024.0]];
}

-(IBAction)cancelUpload:(id)sender {
	uploadCancelled = YES;
	[self cancelExport];
}

#pragma mark Get and Set properties

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
	
	// a placeholder account; do nothing
	if([account isEqualToString:NewAccountLabel]) {
		[self showLoginSheet:self];
		return;
	}

	// an unknown account
	NSAssert( [[self accounts] containsObject:account], @"Selected account is unknown");
	
	// if we're already logged into the newly selected account, return
	if([[self selectedAccount] isEqual:account]) {
		return;
	}
	
	// if we're already loggin in to another account, logout
	if([[self smugMugManager] isLoggedIn]) {
		// handle the rest of the account changed tasks after we logout
		NSInvocation *inv = [NSInvocation invocationWithMethodSignature:
			[self methodSignatureForSelector:@selector(accountChangedTasks:)]];
		[inv setSelector:@selector(accountChangedTasks:)];
		[inv retainArguments];
		[self setPostLogoutInvocation:inv];		
		[[self postLogoutInvocation] setArgument:account atIndex:0];

		[[self smugMugManager] logout]; // aynchronous callback
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

-(void)setIsUploading:(BOOL)v {
	isUploading = v;
}

-(AccountManager *)accountManager {
	return accountManager;
}

-(void)setAccountManager:(AccountManager *)mgr {
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


-(SmugMugManager *)smugMugManager {
	return smugMugManager;
}

-(void)setSmugMugManager:(SmugMugManager *)m {
	if([self smugMugManager] != nil)
		[[self smugMugManager] release];
	
	smugMugManager = [m retain];
}

-(id)description {
    return NSLocalizedString(@"SmugMugExport", @"Name of the Plugin");
}

-(id)name {
    return NSLocalizedString(@"SmugMugExport", @"Name of the Project");
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

-(NSDictionary *)selectedAlbum {
	if([[albumsArrayController selectedObjects] count] > 0)
		return [[albumsArrayController selectedObjects] objectAtIndex:0];
	
	return nil;
}

-(NSPanel *)newAlbumSheet {
	return newAlbumSheet;
}

-(NSPanel *)uploadPanel {
	return uploadPanel;
}

-(NSPanel *)loginPanel {
	return loginPanel;
}

#pragma mark iPhoto Export Manager Delegate methods

-(void)cancelExport {
	[[self smugMugManager] stopUpload];
}

-(void)unlockProgress {
	NSLog(@"SmugMugExport -- unlockProgress");
}

-(void)lockProgress {
	NSLog(@"SmugMugExport -- lockProgress");
}

-(void *)progress {
	return (void *)@""; 
}

-(void)performExport:(id)fp8 {
	NSLog(@"SmugMugExport -- performExport");
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
	return [NSString stringWithFormat:@"%@-%d",[[NSCalendarDate calendarDate] descriptionWithCalendarFormat:@"%Y-%m-%d"], [NSDate timeIntervalSinceReferenceDate]];;
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
//	[[self smugMugManager] logout];
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
	NSLog(@"SmugMugExport -- clickExport");
}

- (BOOL)handlesMovieFiles {
	return NO;
}

@end
