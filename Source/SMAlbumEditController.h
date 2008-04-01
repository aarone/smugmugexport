//
//  SMAlbumEditController.h
//  SmugMugExport
//
//  Created by Aaron Evans on 3/23/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SMAlbumInfo, SMAlbumRef;

// informal protocol
@protocol SMAlbumEditControllerDelegate
-(void)createAlbum:(SMAlbumInfo *)albumInfo;
-(void)editAlbum:(SMAlbumInfo *)albumInfo;
-(NSArray *)categories;
-(NSArray *)subcategories;
@end

@interface SMAlbumEditController : NSObject {
	id delegate;
	IBOutlet NSWindow *newAlbumSheet;
	IBOutlet NSArrayController *categoriesArrayController;
	IBOutlet NSArrayController *subCategoriesArrayController;
	IBOutlet NSObjectController *albumInfoController;
	
	SMAlbumInfo *albumInfo;
	NSArray *categories;
	NSArray *subcategories;
	NSString *albumActionButtonText;
	
	BOOL isBusy;
	BOOL nibLoaded;
	BOOL isSheetOpen;
	BOOL isEditing; // ie not creating a new album
}

-(IBAction)cancelAlbumSheet:(id)sender;
-(IBAction)createOrEditAlbum:(id)sender;

+(SMAlbumEditController *)controller;
-(void)setDelegate:(id)aDelegate;

-(void)showAlbumCreateSheet:(id)delegate forWindow:(NSWindow *)aWindow;
-(void)showAlbumEditSheet:(id)delegate
				forWindow:(NSWindow *)aWindow
				 forAlbum:(SMAlbumRef *)ref
			withAlbumInfo:(SMAlbumInfo *)albumInfo;
-(id)delegate;
-(void)closeSheet;
-(BOOL)isSheetOpen;

-(BOOL)isBusy;
-(void)setIsBusy:(BOOL)v;

@end
