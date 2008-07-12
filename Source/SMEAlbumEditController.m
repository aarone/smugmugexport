//
//  SMEAlbumEditController
//  SmugMugExport
//
//  Created by Aaron Evans on 3/23/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMEAlbumEditController.h"
#import "SMEGlobals.h"
#import "SMEExportPlugin.h"

@interface SMEAlbumEditController (Private) 
-(NSArray *)subCategoriesForCategory:(NSDictionary *)aCategory;
-(NSDictionary *)createNullSubcategory;
-(NSArray *)categories;
-(NSArray *)subcategories;
-(NSPredicate *)createRelevantSubCategoryFilterForCategory:(NSDictionary *)aCategory;
-(void)refreshCategorySelections:(BOOL)clearsSubcategory;
-(BOOL)isEditing;
-(void)setIsEditing:(BOOL)v;
-(SMEAlbum *)album;
-(void)setAlbum:(SMEAlbum *)anAlbum;
-(NSString *)statusText;
-(void)setStatusText:(NSString *)aString;
@end

@implementation SMEAlbumEditController

-(id)init {
	if( (self = [super init]) == nil)
		return nil;

	nibLoaded = NO;
	isBusy = NO;
	return self;
}

-(void)dealloc {
	[super dealloc];
}

+(void)initialize {
	[self setKeys:[NSArray arrayWithObject:@"isEditing"] triggerChangeNotificationsForDependentKey:@"albumActionButtonText"];
}

-(void)setDelegate:(id)aDelegate {
	delegate = aDelegate;
}

-(void)awakeFromNib {}

+(SMEAlbumEditController *)controller {
	return [[[[self class] alloc] init] autorelease];
}

-(void)loadNibIfNecessary {
	if(!nibLoaded)
		[NSBundle loadNibNamed: @"AlbumEdit" owner: self];
	
	nibLoaded = YES;
}

-(void)showError:(NSString *)err {
	[self setStatusText:err];
}

-(NSWindow *)newAlbumSheet {
	return newAlbumSheet;
}

-(void)setInsertionPoint:(NSWindow *)aWindow {
	if([[aWindow firstResponder] respondsToSelector:@selector(setString:)]) {
		// hack to get insertion point to appear in textfield
		[(NSTextView *)[aWindow firstResponder] setString:@""];
	}
}

-(void)showAlbumCreateSheet:(SMEAlbum *)anAlbum
				   delegate:(id)delegate 
				  forWindow:(NSWindow *)aWindow {
	[self loadNibIfNecessary];

	[self setIsEditing:NO];
	[self setAlbum:anAlbum];
	
	[NSApp beginSheet:[self newAlbumSheet]
	   modalForWindow:aWindow
		modalDelegate:self
	   didEndSelector:@selector(newAlbumDidEndSheet:returnCode:contextInfo:)
		  contextInfo:nil];
	isSheetOpen = YES;
	
	[self setInsertionPoint:[self newAlbumSheet]];
}

-(IBAction)createOrEditAlbum:(id)sender {
	
	if(![self isEditing] && [delegate respondsToSelector:@selector(createAlbum:)]) {
		[delegate createAlbum:[self album]];
	} else if( [delegate respondsToSelector:@selector(editAlbum:)]) {
		[delegate editAlbum:[self album]];
	}
}

-(IBAction)cancelAlbumSheet:(id)sender {
	[NSApp endSheet:[self newAlbumSheet]];
}

-(void)newAlbumDidEndSheet:(NSWindow *)sheet 
				returnCode:(int)returnCode
			   contextInfo:(void *)contextInfo {
	[sheet orderOut:self];
	isSheetOpen = NO;	
}

-(void)showAlbumEditSheet:(id)delegate
				forWindow:(NSWindow *)aWindow
				 forAlbum:(SMEAlbum *)anAlbum {
	[self loadNibIfNecessary];
	[self setAlbum:anAlbum];
	[self setIsEditing:YES];
	isSheetOpen = YES;
	[NSApp beginSheet:[self newAlbumSheet]
	   modalForWindow:aWindow
		modalDelegate:self
	   didEndSelector:@selector(editAlbumDidEndSheet:returnCode:contextInfo:)
		  contextInfo:NULL];
	[[self newAlbumSheet] makeKeyAndOrderFront:self];	
}

-(void)editAlbumDidEndSheet:(NSWindow *)sheet
				 returnCode:(int)returnCode
				contextInfo:(void *)contextInfo {
	[sheet orderOut:self];
	isSheetOpen = NO;
}

-(NSString *)editAlbumButtonText {
	return NSLocalizedString(@"Edit", @"Button text when editing a new album");
}

-(NSString *)createAlbumButtonText {
	return NSLocalizedString(@"Create", @"Button text when creating a new album");
}	

-(NSString *)albumActionButtonText {
	if([self isEditing])
		return [self editAlbumButtonText];
	else
		return [self createAlbumButtonText];
}

-(BOOL)isBusy {
	return isBusy;
}

-(void)setIsBusy:(BOOL)v {
	isBusy = v;
}

-(BOOL)isEditing {
	return isEditing;
}

-(void)setIsEditing:(BOOL)v {
	isEditing = v;
}

-(id)delegate {
	return delegate;
}

-(void)closeSheet {
	[self setIsBusy:NO];
	[NSApp endSheet:newAlbumSheet];
}

-(BOOL)isSheetOpen {
	return isSheetOpen;
}

-(NSArray *)categories {
	return [delegate categories];
}

-(NSArray *)subcategories {
	return [delegate subcategories];
}

-(SMEAlbum *)album {
	return album;
}

-(void)setAlbum:(SMEAlbum *)anAlbum {
	if(anAlbum != album) {
		[album release];
		album = [anAlbum retain];
	}
}

-(NSString *)statusText {
	return statusText;
}

-(void)setStatusText:(NSString *)aString {
	if(aString != statusText) {
		[statusText release];
		statusText = [aString retain];
	}
}
@end
