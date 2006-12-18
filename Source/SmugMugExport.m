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
#import "SmugMugEntityUnescapeTransformer.h"

@interface SmugMugExport (Private)
-(ExportMgr *)exportManager;
-(void)setExportManager:(ExportMgr *)m;
-(SmugMugManager *)smugMugManager;
-(void)setSmugMugManager:(SmugMugManager *)m;
-(BOOL)CURLIsLoaded;
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
-(BOOL)isFocused;
-(void)setIsFocused:(BOOL)v;
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
-(void)login;
-(NSData *)currentThumbnailData;
-(void)setCurrentThumbnailData:(NSData *)d;
-(BOOL)loginSheetIsBusy;
-(void)setLoginSheetIsBusy:(BOOL)v;

@end

// UI keys
NSString *ExistingAlbumTabIdentifier = @"existingAlbum";
NSString *NewAlbumTabIdentifier = @"newAlbum";
NSString *NewAccountLabel = @"New Account...";

// defaults keys
NSString *SMESelectedTabIdDefaultsKey = @"SMESelectedTabId";
NSString *SMEAccountsDefaultsKey = @"SMEAccounts";
NSString *SMESelectedAccountDefaultsKey = @"SMESelectedAccount";

@implementation SmugMugExport

-(id)initWithExportImageObj:(id)exportMgr
{
	if(![super init])
		return nil;
	
	exportManager = exportMgr;	
	[self registerDefaults];
	[NSBundle loadNibNamed: @"SmugMugExport" owner:self];

	[self setAccountManager:[AccountManager accountManager]];
	[self setSmugMugManager:[SmugMugManager smugmugManager]];
	[[self smugMugManager] setDelegate:self];

	[self setIsFocused:NO];
	[self setLoginAttempted:NO];
	[self setImagesUploaded:0];

	[NSValueTransformer setValueTransformer:[[[SmugMugEntityUnescapeTransformer alloc] init] autorelease] forName:@"SmugMugEntityUnescapeTransformer"];
	return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[[self smugMugManager] release];
	[[self username] release];
	[[self password] release];
	[[self sessionUploadStatusText] release];
	[[self fileUploadProgress] release];
	[[self sessionUploadProgress] release];
	[[self accountManager] release];
	[[self loginSheetStatusMessage] release];
	[[self statusText] release];
	[[self currentThumbnailData] release];

	[super dealloc];
}

+(void)initialize {
	[[self class] setKeys:[NSArray arrayWithObject:@"accountManager.accounts"] triggerChangeNotificationsForDependentKey:@"accounts"];
	[[self class] setKeys:[NSArray arrayWithObject:@"accountManager.selectedAccount"] triggerChangeNotificationsForDependentKey:@"selectedAccount"];
}

-(void)registerDefaults { 
	NSMutableDictionary *defaultsDict = [NSMutableDictionary dictionary];
	[defaultsDict setObject:ExistingAlbumTabIdentifier forKey:SMESelectedTabIdDefaultsKey];
	[defaultsDict setObject:[NSArray array] forKey:SMEAccountsDefaultsKey];
//	[defaultsDict setObject:nil forKey:SMESelectedAccountDefaultsKey];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];
}

-(void)awakeFromNib {
	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:SMESelectedTabIdDefaultsKey
											   options:0
											   context:NULL];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:[[self exportManager] window]];
}


/* try to automatically show the login sheet */
-(void)attemptLoginIfNecessary {

	if([loginPanel isVisible]) // don't try to show the login sheet if it's already showing
		return;

	if(![self isFocused]) // don't show if we're not focused
		return;

	/* don't try to login if we're already logged in or attempting to login */
	if([[self smugMugManager] isLoggedIn] ||
	   [[self smugMugManager] isLoggingIn])
		return;

	/*
	 * Show the login window if we're not logged in, we haven't tried to log in,
	 * and there is no existing account to automatically choose.
	 */
	if(![[self smugMugManager] isLoggedIn] && 
	   ![self loginAttempted] &&
	   [[[self accountManager] accounts] count] == 0) {

		[self showLoginPanel:self];
		return;
	}

	/**
	*  If we have a saved password for the previously selected account, log in to that account.
	 */
	if(![[self smugMugManager] isLoggedIn] && 
	   [[[self accountManager] accounts] count] > 0 &&
	   [[self accountManager] selectedAccount] != nil &&
	   ![self loginAttempted] &&
	   [[self accountManager] passwordExistsInKeychainForAccount:[[self accountManager] selectedAccount]]) {
		
		[self setLoginAttempted:YES];
		[self setIsBusy:YES];
		[self setStatusText:@"Logging in..."];
		[[self smugMugManager] setUsername:[[self accountManager] selectedAccount]];
		[[self smugMugManager] setPassword:[[self accountManager] passwordForAccount:[[self accountManager] selectedAccount]]];
		[[self smugMugManager] login]; // gets asyncronous callback
	}	
}

-(void)windowDidBecomeKey:(NSNotification *)not {

	if([[not object] isEqualTo:[[self exportManager] window]])
		[self attemptLoginIfNecessary];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//	[self resizeWindow];
}

-(NSDictionary *)selectedAlbum {
	if([[albumsArrayController selectedObjects] count] > 0)
		return [[albumsArrayController selectedObjects] objectAtIndex:0];
	
	return nil;
}

-(IBAction)cancelUpload:(id)sender {
	[self cancelExport];
}

-(IBAction)donate:(id)sender {
	NSLog(@"donate");
}

-(IBAction)showLoginPanel:(id)sender {
	[NSApp beginSheet:loginPanel
	   modalForWindow:[[self exportManager] window]
		modalDelegate:self
	   didEndSelector:@selector(loginDidEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];

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
	[self setLoginSheetStatusMessage:@"Logging In..."];
	[self setLoginSheetIsBusy:YES];
	[[self smugMugManager] setUsername:[self username]];
	[[self smugMugManager] setPassword:[self password]];
	[[self smugMugManager] login]; // gets asyncronous callback
}

#pragma mark Delegate Methods
-(void)loginDidComplete:(BOOL)wasSuccessful {
	[self setIsBusy:NO];
	[self setStatusText:@""];
	[self setLoginSheetIsBusy:NO];
	[self setLoginSheetStatusMessage:@""];

	if(!wasSuccessful) {
		[self setLoginSheetStatusMessage:@"Login Failed"];
		return;
	}

	// attempt to login, if successful add to keychain
	[[self accountManager] addAccount:[[self smugMugManager] username] withPassword:[[self smugMugManager] password]];
	[self setSelectedAccount:[[self smugMugManager] username]];
	[NSApp endSheet:loginPanel];
}

-(void)loginDidEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

-(void)logoutDidComplete:(BOOL)wasSuccessful {
	NSLog(@"logout complete");
}

-(void)startUpload {
	[self setImagesUploaded:0];
	[self setFileUploadProgress:[NSNumber numberWithInt:0]];
	[self setSessionUploadProgress:[NSNumber numberWithInt:0]];
	[self setSessionUploadStatusText:[NSString stringWithFormat:@"Uploading image %d of %d", [self imagesUploaded] + 1, [[self exportManager] imageCount]]];

	[NSApp beginSheet:uploadPanel
	   modalForWindow:[[self exportManager] window]
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];
	
	NSNumber *selectedAlbumId = [[self selectedAlbum] objectForKey:@"AlbumID"];
	NSString *thumbnailPath = [exportManager thumbnailPathAtIndex:[self imagesUploaded]];		
	[self setCurrentThumbnailData:[NSData dataWithContentsOfFile: thumbnailPath]];
	[[self smugMugManager] uploadImageAtPath:[[self exportManager] imagePathAtIndex:[self imagesUploaded]]
								 albumWithID:selectedAlbumId
									 caption:@"test"];	
}

-(void)performUploadCompletionTasks {
	[NSApp endSheet:uploadPanel];
	[[self exportManager] cancelExportBeforeBeginning];
}

-(void)uploadDidCompleteForFile:(NSString *)aFullPathToImage withError:(NSString *)error {
	[self setImagesUploaded:[self imagesUploaded] + 1];
	[self setSessionUploadProgress:[NSNumber numberWithFloat:100.0*((float)[self imagesUploaded])/((float)[[self exportManager] imageCount])]];
	
	NSNumber *selectedAlbumId = [[self selectedAlbum] objectForKey:@"AlbumID"];
	if([self imagesUploaded] >= [[self exportManager] imageCount]) {
		[self performUploadCompletionTasks];
	} else {
		[self setSessionUploadStatusText:[NSString stringWithFormat:@"Uploading image %d of %d", [self imagesUploaded] + 1, [[self exportManager] imageCount]]];
		NSString *thumbnailPath = [exportManager thumbnailPathAtIndex:[self imagesUploaded]];		
		[self setCurrentThumbnailData:[NSData dataWithContentsOfFile: thumbnailPath]];
		[[self smugMugManager] uploadImageAtPath:[[self exportManager] imagePathAtIndex:[self imagesUploaded]]
									 albumWithID:selectedAlbumId
										 caption:@"test"];
	}
}

-(void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

-(void)uploadMadeProgressForFile:(NSString *)pathToFile bytesWritten:(long)bytesWritten totalBytes:(long)totalBytes {
	float progressForFile = MIN(100.0, ceil(100.0*(float)bytesWritten/(float)totalBytes));
	[self setFileUploadProgress:[NSNumber numberWithFloat:progressForFile]];

	float baselinePercentageCompletion = 100.0*((float)[self imagesUploaded])/((float)[[self exportManager] imageCount]);
	float estimatedFileContribution = (100.0/((float)[[self exportManager] imageCount]))*((float)bytesWritten)/((float)totalBytes);
	[self setSessionUploadProgress:[NSNumber numberWithFloat:MIN(100.0, ceil(baselinePercentageCompletion+estimatedFileContribution))]];
}

-(NSArray *)accounts {
	return [[accountManager accounts] arrayByAddingObject:NewAccountLabel];
}

-(void)setSelectedAccount:(NSString *)account {
	if([account isEqualToString:NewAccountLabel]) {
		[self showLoginPanel:self];
		return;
	}

	NSAssert( [[self accounts] containsObject:account], @"selected account is unknown");
	
	[[self accountManager] setSelectedAccount:account];
}

-(NSString *)selectedAccount {
	return [[self accountManager] selectedAccount];
}

-(BOOL)loginSheetIsBusy {
	return loginSheetIsBusy;
}

-(void)setLoginSheetIsBusy:(BOOL)v {
	loginSheetIsBusy = v;
}

-(NSData *)currentThumbnailData {
	return currentThumbnailData;
}

-(void)setCurrentThumbnailData:(NSData *)d {
	if([self currentThumbnailData] != nil)
		[[self currentThumbnailData] release];
	
	currentThumbnailData = [d retain];
}

-(BOOL)isBusy {
	return isBusy;
}

-(void)setIsBusy:(BOOL)v {
	isBusy = v;
}

-(BOOL)isFocused {
	return isFocused;
}

-(void)setIsFocused:(BOOL)v {
	isFocused = v;
}

-(BOOL)loginAttempted
{
	return loginAttempted;
}

-(void)setLoginAttempted:(BOOL)v
{
	loginAttempted = v;
}

-(AccountManager *)accountManager
{
	return accountManager;
}

-(void)setAccountManager:(AccountManager *)mgr
{
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

-(void)cancelExport {
	NSLog(@"SmugMugExport -- cancelExport");
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
	[self setIsFocused:NO];
//	[[self smugMugManager] logout];
}

-(void)loginUntilFocused {

	if([[self smugMugManager] isLoggingIn])
		return;

	if(![[[self exportManager] window] isVisible])
		return;

	if([loginPanel isVisible])
		return;

	[self attemptLoginIfNecessary];

	[self performSelector:@selector(loginUntilFocused) withObject:nil afterDelay:0.25];
}

-(void)viewWillBeActivated {
	// TODO just check for an account and if no account exists, show sheet
	[self setIsFocused:YES];
	[self performSelector:@selector(loginUntilFocused) withObject:nil afterDelay:0.25];
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

@end
