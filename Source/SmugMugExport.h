//
//  SmugmugExport.h
//  SmugMugExport
//
//  Created by Aaron Evans on 10/7/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SmugMugManager, ExportMgr, AccountManager;
@protocol ExportPluginProtocol, SmugMugManagerDelegate;

@interface SmugMugExport : NSObject <ExportPluginProtocol, SmugMugManagerDelegate> {

	IBOutlet id firstView;
	IBOutlet id lastView;
	IBOutlet NSBox *settingsBox;
	IBOutlet NSPanel *uploadPanel;
	IBOutlet NSPanel *loginPanel;
	IBOutlet NSPopUpButton *acccountPopupButton;
	IBOutlet NSArrayController *albumsArrayController;
	IBOutlet NSPanel *newAlbumSheet;
	IBOutlet NSArrayController *categoriesArrayController; 

	 // this is the username bound to the textfield, account manager holds the real username
	NSString *username; 
	// same goes for password..
	NSString *password;
	NSString *sessionUploadStatusText;
	NSString *statusText;
	NSNumber *fileUploadProgress;
	NSNumber *sessionUploadProgress;
	NSString *loginSheetStatusMessage;
	NSImage *currentThumbnail;
	NSString *imageUploadProgressText; // below the thumbnail..

	BOOL loginSheetIsBusy;
	BOOL isBusy;
	BOOL loginAttempted;
	BOOL uploadCancelled;
	BOOL errorAlertSheetIsVisisble;
	int uploadRetryCount;
	int imagesUploaded;

	ExportMgr *exportManager;
	SmugMugManager *smugMugManager;
	AccountManager *accountManager;
}

#pragma mark Upload Actions
-(IBAction)cancelUpload:(id)sender;

#pragma mark Login Actions
-(IBAction)cancelLoginSheet:(id)sender;
-(IBAction)showLoginSheet:(id)sender;
-(IBAction)performLoginFromSheet:(id)sender;

#pragma mark Misc
-(IBAction)donate:(id)sender;

#pragma mark Album Creation Actions
-(IBAction)addNewAlbum:(id)sender;
-(IBAction)removeAlbum:(id)sender;
-(IBAction)cancelNewAlbumSheet:(id)sender;
-(IBAction)createAlbum:(id)sender;


@end