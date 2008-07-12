//
//  SMEAlbumEditController.h
//  SmugMugExport
//
//  Created by Aaron Evans on 3/23/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SMEAlbum, SMEAlbumRef;

@interface SMEAlbumEditController : NSObject {
	id delegate;
	IBOutlet NSWindow *newAlbumSheet;
	IBOutlet NSArrayController *categoriesArrayController;
	IBOutlet NSArrayController *subCategoriesArrayController;
	IBOutlet NSObjectController *albumInfoController;
	
	SMEAlbum *album;
	NSArray *categories;
	NSArray *subcategories;
	NSString *albumActionButtonText;
	
	BOOL isBusy;
	BOOL nibLoaded;
	BOOL isSheetOpen;
	BOOL isEditing; // ie not creating a new album
	
	NSString *statusText;
}

-(IBAction)cancelAlbumSheet:(id)sender;
-(IBAction)createOrEditAlbum:(id)sender;

+(SMEAlbumEditController *)controller;
-(void)setDelegate:(id)aDelegate;

-(void)showAlbumCreateSheet:(SMEAlbum *)anAlbum
				   delegate:(id)delegate 
				  forWindow:(NSWindow *)aWindow;

-(void)showAlbumEditSheet:(id)delegate
				forWindow:(NSWindow *)aWindow
				 forAlbum:(SMEAlbum *)album;

-(void)showError:(NSString *)err;

-(id)delegate;
-(void)closeSheet;
-(BOOL)isSheetOpen;
-(BOOL)isBusy;
-(void)setIsBusy:(BOOL)v;

@end
