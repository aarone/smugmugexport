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
-(NSImage *)currentImageThumbnail;
-(void)setCurrentImageThumbnail:(NSImage *)i;
-(int)imagesUploaded;
-(void)setImagesUploaded:(int)v;
-(void)resizeWindow;
-(AccountManager *)accountManager;
-(void)setAccountManager:(AccountManager *)mgr;
-(BOOL)isLoggedIn;
-(void)setIsLoggedIn:(BOOL)v;
-(void)registerDefaults;
-(BOOL)isFocused;
-(void)setIsFocused:(BOOL)v;
-(BOOL)loginAttempted;
-(void)setLoginAttempted:(BOOL)v;
-(void)performPostLoginTasks;
-(NSNumber *)isLoggingIn;
-(void)setIsLoggingIn:(NSNumber *)v;
-(NSString *)loginStatusMessage;
-(void)setLoginStatusMessage:(NSString *)m;
-(void)setSelectedAccount:(NSString *)account;
-(NSString *)selectedAccount;
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

	[self setIsLoggedIn:NO];
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
	[[self currentImageThumbnail] release];
	[[self accountManager] release];
	[[self isLoggingIn] release];
	[[self loginStatusMessage] release];

	[super dealloc];
}

+(void)initialize
{
	[[self class] setKeys:[NSArray arrayWithObject:@"accountManager.accounts"] triggerChangeNotificationsForDependentKey:@"accounts"];
	[[self class] setKeys:[NSArray arrayWithObject:@"accountManager.selectedAccount"] triggerChangeNotificationsForDependentKey:@"selectedAccount"];
}

-(void)registerDefaults
{
	NSMutableDictionary *defaultsDict = [NSMutableDictionary dictionary];
	[defaultsDict setObject:ExistingAlbumTabIdentifier forKey:SMESelectedTabIdDefaultsKey];
	[defaultsDict setObject:[NSArray array] forKey:SMEAccountsDefaultsKey];
//	[defaultsDict setObject:nil forKey:SMESelectedAccountDefaultsKey];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];
}

-(void)awakeFromNib
{
	[[NSUserDefaults standardUserDefaults] addObserver:self
											forKeyPath:SMESelectedTabIdDefaultsKey
											   options:0
											   context:NULL];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:[[self exportManager] window]];
}

-(void)windowDidBecomeKey:(NSNotification *)not
{
	/*
	 * Show the login window if we're not logged in, we haven't tried to log in, the window is focused,
	 * and there is no existing account to automatically choose.
	 */
	if([[not object] isEqualTo:[[self exportManager] window]] && 
	   ![self isLoggedIn] && 
	   [self isFocused] &&
	   ![self loginAttempted] &&
	   [[[self accountManager] accounts] count] == 0)
		[self showLoginPanel:self];

	/**
	 *  If we have a saved password for the previously selected account, log in to that account.
	 */
	if([[not object] isEqualTo:[[self exportManager] window]] && 
	   ![self isLoggedIn] && 
	   [self isFocused] &&
	   [[[self accountManager] accounts] count] > 0 &&
	   [[self accountManager] selectedAccount] != nil &&
	   ![self loginAttempted] &&
	   [[self accountManager] passwordExistsInKeychainForAccount:[[self accountManager] selectedAccount]]) {
		[self setLoginAttempted:YES];
		[[self smugMugManager] setUsername:[[self accountManager] selectedAccount]];
		[[self smugMugManager] setPassword:[[self accountManager] passwordForAccount:[[self accountManager] selectedAccount]]];
		[[self smugMugManager] login]; // gets asyncronous callback
	}

		
	
	
	//	[self resizeWindow];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//	[self resizeWindow];
}

-(void)resizeWindow
{
	return;
	float x = [[[self exportManager] window] frame].origin.x;
    float y = [[[self exportManager] window] frame].origin.y;
    float height = [[[self exportManager] window] frame].size.height;
	float targetWidth = 543;
	float targetHeight = 350;
	float yDiff = 0.0;
	NSString *selectedTabId = [[NSUserDefaults standardUserDefaults] objectForKey:SMESelectedTabIdDefaultsKey];

	if([selectedTabId isEqualToString:ExistingAlbumTabIdentifier]) {
        yDiff = height - targetHeight;
		targetWidth = 400;
	} else if([selectedTabId isEqualToString:NewAlbumTabIdentifier]) {
		targetHeight = 500.0;
        yDiff = height - targetHeight;
	}

	[[[self exportManager] window] setFrame:NSMakeRect(x,y+yDiff,targetWidth,targetHeight)
									display:YES
									animate:YES];
}

-(IBAction)donate:(id)sender
{
	NSLog(@"donate");
}

-(IBAction)showLoginPanel:(id)sender
{
	[NSApp beginSheet:loginPanel
	   modalForWindow:[[self exportManager] window]
		modalDelegate:self
	   didEndSelector:@selector(loginDidEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];

	// mark that we've shown the user the login sheet at least once
	[self setLoginAttempted:YES];
}

-(IBAction)cancelLoginSheet:(id)sender
{
	if([[[self accountManager] accounts] count] > 0)
		[self setSelectedAccount:[[[self accountManager] accounts] objectAtIndex:0]];
	else
		[self setSelectedAccount:nil];

	[NSApp endSheet:loginPanel];
}

/** called from the login sheet.  takes username/password values from the textfields */
-(IBAction)login:(id)sender
{
	[self setLoginStatusMessage:@""];
	[self setIsLoggingIn:[NSNumber numberWithBool:YES]];
	[[self smugMugManager] setUsername:[self username]];
	[[self smugMugManager] setPassword:[self password]];
	[[self smugMugManager] login]; // gets asyncronous callback
}

#pragma mark Delegate Methods
-(void)loginDidComplete:(BOOL)wasSuccessful
{
	[self setIsLoggingIn:[NSNumber numberWithBool:NO]];
	
	if(!wasSuccessful) {
		[self setLoginStatusMessage:@"Login Failed"];
		return;
	}

	// attempt to login, if successful add to keychain
	[self setIsLoggedIn:YES];
	[[self accountManager] addAccount:[[self smugMugManager] username] withPassword:[[self smugMugManager] password]];
	[self setSelectedAccount:[[self smugMugManager] username]];
	[NSApp endSheet:loginPanel];
	[self performPostLoginTasks];
}

-(void)performPostLoginTasks
{
	// load the list of known albums
	[[self smugMugManager] buildAlbumList];
}

-(void)loginDidEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	
    [sheet orderOut:self];
}

-(void)logoutDidComplete:(BOOL)wasSuccessful
{
	NSLog(@"logout complete");
}

-(void)startUpload
{
	[self setImagesUploaded:0];
	[self setFileUploadProgress:[NSNumber numberWithInt:0]];
	[self setSessionUploadProgress:[NSNumber numberWithInt:0]];
	[self setSessionUploadStatusText:[NSString stringWithFormat:@"Uploading image %d of %d", [self imagesUploaded] + 1, [[self exportManager] imageCount]]];

	[NSApp beginSheet:uploadPanel
	   modalForWindow:[[self exportManager] window]
		modalDelegate:self
	   didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];

	[[self smugMugManager] uploadImageAtPath:[[self exportManager] imagePathAtIndex:[self imagesUploaded]]
								 albumWithID:[NSString stringWithFormat:@"%d", 1976807]
									 caption:@"test"];	
}

-(void)albumListLoadDidComplete
{
//	[self startUpload];
//	[[self smugMugManager] logout];
}

-(void)uploadDidCompleteForFile:(NSString *)aFullPathToImage withError:(NSString *)error
{
	[self setImagesUploaded:[self imagesUploaded] + 1];
	[self setSessionUploadProgress:[NSNumber numberWithFloat:100.0*((float)[self imagesUploaded])/((float)[[self exportManager] imageCount])]];

	if([self imagesUploaded] >= [[self exportManager] imageCount]) {
		[NSApp endSheet:uploadPanel];
	} else {
		[self setSessionUploadStatusText:[NSString stringWithFormat:@"Uploading image %d of %d", [self imagesUploaded] + 1, [[self exportManager] imageCount]]];
		[[self smugMugManager] uploadImageAtPath:[[self exportManager] imagePathAtIndex:[self imagesUploaded]]
									 albumWithID:[NSString stringWithFormat:@"%d", 1976807]
										 caption:@"test"];
	}
}

-(void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

-(void)uploadMadeProgressForFile:(NSString *)pathToFile bytesWritten:(long)bytesWritten totalBytes:(long)totalBytes
{
	float progress = 100.0*(float)bytesWritten/(float)totalBytes;
	[self setFileUploadProgress:[NSNumber numberWithFloat:progress]];
}

-(NSArray *)accounts
{
	return [[accountManager accounts] arrayByAddingObject:NewAccountLabel];
}

-(void)setSelectedAccount:(NSString *)account
{
	if([account isEqualToString:NewAccountLabel]) {
		[self showLoginPanel:self];
		return;
	}

	NSAssert( [[self accounts] containsObject:account], @"selected account is unknown");
	
	[[self accountManager] setSelectedAccount:account];
}

-(NSString *)selectedAccount
{
	return [[self accountManager] selectedAccount];
}

-(BOOL)isFocused
{
	return isFocused;
}

-(void)setIsFocused:(BOOL)v
{
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

-(BOOL)isLoggedIn
{
	return isLoggedIn;
}

-(void)setIsLoggedIn:(BOOL)v
{
	isLoggedIn = v;
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

-(ExportMgr *)exportManager
{
	return exportManager;
}

-(int)imagesUploaded
{
	return imagesUploaded;
}

-(void)setImagesUploaded:(int)v
{
	imagesUploaded = v;
}

-(NSNumber *)isLoggingIn
{
	return isLoggingIn;
}

-(void)setIsLoggingIn:(NSNumber *)v
{
	if([self isLoggingIn] != nil)
		[[self isLoggingIn] release];
	
	isLoggingIn = [v retain];
}

-(NSString *)loginStatusMessage
{
	return loginStatusMessage;
}

-(void)setLoginStatusMessage:(NSString *)m
{
	if([self loginStatusMessage] != nil)
		[[self loginStatusMessage] release];
	
	loginStatusMessage = [m retain];
}

-(SmugMugManager *)smugMugManager
{
	return smugMugManager;
}

-(void)setSmugMugManager:(SmugMugManager *)m
{
	if([self smugMugManager] != nil)
		[[self smugMugManager] release];
	
	smugMugManager = [m retain];
}

-(id)description
{
    return NSLocalizedString(@"SmugMugExport", @"Name of the Plugin");
}

-(id)name 
{
    return NSLocalizedString(@"SmugMugExport", @"Name of the Project");
}

-(NSString *)username
{
	return username;
}

-(void)setUsername:(NSString *)n
{
	if([self username] != nil)
		[[self username] release];
	
	username = [n retain];
}

-(NSString *)password
{
	return password;
}

-(void)setPassword:(NSString *)p
{
	if([self password] != nil)
		[[self password] release];
	
	password = [p retain];
}

-(NSString *)sessionUploadStatusText
{
	return sessionUploadStatusText;
}

-(void)setSessionUploadStatusText:(NSString *)t
{
	if([self sessionUploadStatusText] != nil)
		[[self sessionUploadStatusText] release];
	
	sessionUploadStatusText = [t retain];
}

-(NSNumber *)fileUploadProgress
{
	return fileUploadProgress;
}

-(void)setFileUploadProgress:(NSNumber *)v
{
	if([self fileUploadProgress] != nil)
		[[self fileUploadProgress] release];
	
	fileUploadProgress = [v retain];
}

-(NSNumber *)sessionUploadProgress
{
	return sessionUploadProgress;
}

-(void)setSessionUploadProgress:(NSNumber *)v
{
	if([self sessionUploadProgress] != nil)
		[[self sessionUploadProgress] release];
	
	sessionUploadProgress = [v retain];
}

-(NSImage *)currentImageThumbnail
{
	return currentImageThumbnail;
}

-(void)setCurrentImageThumbnail:(NSImage *)i
{
	if([self currentImageThumbnail] != nil)
		[[self currentImageThumbnail] release];
	
	currentImageThumbnail = [i retain];
}

-(void)cancelExport
{
	NSLog(@"SmugMugExport -- cancelExport");
}

-(void)unlockProgress
{
	NSLog(@"SmugMugExport -- unlockProgress");
}

-(void)lockProgress
{
	NSLog(@"SmugMugExport -- lockProgress");
}

-(void *)progress
{
	return (void *)@""; 
}

-(void)performExport:(id)fp8
{
	NSLog(@"SmugMugExport -- performExport");
}

-(void)startExport:(id)fp8
{
	[[self smugMugManager] login];

	return;
}

-(BOOL)validateUserCreatedPath:(id)fp8
{
    return NO;
}

-(BOOL)treatSingleSelectionDifferently
{
    return NO;
}

-(id)defaultDirectory
{
    return NSHomeDirectory();
}

-(id)defaultFileName
{
	return [NSString stringWithFormat:@"%@-%d",[[NSCalendarDate calendarDate] descriptionWithCalendarFormat:@"%Y-%m-%d"], [NSDate timeIntervalSinceReferenceDate]];;
}

-(id)getDestinationPath
{
	return NSHomeDirectory();
}

-(BOOL)wantsDestinationPrompt
{
    return NO;
}

-(id)requiredFileType
{
	return @"album";
}

-(void)viewWillBeDeactivated
{
	[self setIsFocused:NO];
//	[[self smugMugManager] logout];
}

-(void)viewWillBeActivated
{
	// TODO just check for an account and if no account exists, show sheet
	[self setIsFocused:YES];
	// [self performSelector:@selector(resizeWindow) withObject:nil afterDelay:1.0];
}

-(id)lastView
{
	return lastView;
}

-(id)firstView
{
	return firstView;
}

-(id)settingsView
{
	return settingsBox;
}

-(void)clickExport
{
	NSLog(@"SmugMugExport -- clickExport");
}

@end
