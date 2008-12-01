//
//  SMExportPlugin.h
//  SMExportPlugin
//
//  Created by Aaron Evans on 10/7/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>
#import <WebKit/WebKit.h>

#import "ExportPluginProtocol.h"
#import "SMESession.h"

@class SMESession, ExportMgr, SMEAccountManager, SMEAlbumEditController, SMEAccountInfo, SMEGrowlDelegate, SMEAccountInfo;
@protocol ExportPluginProtocol, SMESessionDelegate;

@interface SMEExportPlugin : NSObject <ExportPluginProtocol, SMEUploadObserver> {

	IBOutlet id firstView;
	IBOutlet id lastView;
	IBOutlet NSBox *settingsBox;
	IBOutlet NSPanel *uploadPanel;
	IBOutlet NSPanel *loginPanel;
	IBOutlet NSPopUpButton *acccountPopupButton;
	IBOutlet NSArrayController *albumsArrayController;
	IBOutlet NSPanel *newAlbumSheet;
	IBOutlet NSPanel *preferencesPanel;
	IBOutlet NSTableView *albumsTableView;
	IBOutlet WebView *vaultLink;
	
	NSString *username;  // this is the username bound to the textfield, account manager holds the real username
	NSString *password; // same goes for password..
	NSString *sessionUploadStatusText;
	NSString *statusText;
	NSNumber *fileUploadProgress;
	NSNumber *sessionUploadProgress;
	NSString *loginSheetStatusMessage;
	NSImage *currentThumbnail;
	NSString *imageUploadProgressText; // below the thumbnail..
	NSURL *uploadSiteUrl;
	NSMutableDictionary *newAlbumPreferences;
	
	SMEGrowlDelegate *growlDelegate;
	SMESession *session;
	
	// smugmug state
	NSArray *albums;
	NSArray *categories;
	NSArray *subcategories;
	SMEAccountInfo *accountInfo;
	
	NSInvocation *postLogoutInvocation; // do this after a logout is complete

	BOOL isLoggingIn;
	BOOL isUploading;
	BOOL isBusy;
	BOOL loginAttempted;
	BOOL isLoginSheetDismissed;
	BOOL uploadCancelled;
	BOOL errorAlertSheetIsVisisble;
	BOOL siteUrlHasBeenFetched;
	BOOL browserOpenedInGallery;
	BOOL isDeletingAlbum;
	BOOL isUpdateInProgress;
	int imagesUploaded;
	int albumUrlFetchAttemptCount;
	
	ExportMgr *exportManager;
	SMEAccountManager *accountManager;
	SMEAlbumEditController *albumEditController;
}

#pragma mark Upload Actions
-(IBAction)cancelUpload:(id)sender;

#pragma mark Login Actions
-(IBAction)cancelLoginSheet:(id)sender;
-(IBAction)showLoginSheet:(id)sender;
-(IBAction)performLoginFromSheet:(id)sender;

#pragma mark Misc
-(IBAction)donate:(id)sender;

#pragma mark Preferences
-(IBAction)showPreferences:(id)sender;
-(IBAction)closePreferencesSheet:(id)sender;

#pragma mark Album Editing Actions
-(IBAction)showNewAlbumSheet:(id)sender;
-(IBAction)removeAlbum:(id)sender;
-(IBAction)showEditAlbumSheet:(id)sender;

#pragma mark Update
-(IBAction)checkForUpdates:(id)sender;

-(void)editAlbum:(SMEAlbum *)album;
-(void)createAlbum:(SMEAlbum *)album;
@end
