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
#import "SMEAlbum.h"
#import "SMECategory.h"
#import "SMESubCategory.h"

@interface SMEAlbumEditController (Private) 
-(NSArray *)categories;
-(NSArray *)subcategories;
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
	[[self album] release];
	[[self statusText] release];
	
	[super dealloc];
}

+(void)initialize {
	[self setKeys:[NSArray arrayWithObject:@"isEditing"] triggerChangeNotificationsForDependentKey:@"albumActionButtonText"];
}

	
-(void)setDelegate:(id)aDelegate {
	delegate = aDelegate;
}

-(void)awakeFromNib {
	[self addObserver:self forKeyPath:@"album.category" options:NSKeyValueObservingOptionNew context:NULL];	
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if([keyPath isEqualToString:@"album.category"]) {
		if(![[[[self album] category] childSubCategories] containsObject:[[self album] subCategory]]) {
			[[self album] setSubCategory:[SMESubCategory nullSubCategory]];
		}
		[self willChangeValueForKey:@"subcategories"];
		[self didChangeValueForKey:@"subcategories"];

	}
}

+(SMEAlbumEditController *)controller {
	return [[[[self class] alloc] init] autorelease];
}

-(void)loadNibIfNecessary {
	if(!nibLoaded)
		[NSBundle loadNibNamed: @"AlbumEdit" owner: self];
	
	nibLoaded = YES;
}

-(void)showError:(NSError *)err {
	[[NSAlert alertWithError:err] runModal];
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
	if(newAlbumSheet != nil && [newAlbumSheet isVisible])
		[NSApp endSheet:newAlbumSheet];
}

-(BOOL)isSheetOpen {
	return isSheetOpen;
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

-(NSArray *)categories {
	return [[self delegate] categories];
}

-(NSArray *)subcategories {
	if([[[[self album] category] childSubCategories] count] == 0) {
		return [[[self album] category] childSubCategories];
	}

 	// otherwise, add a placehold subcategory for 'No Value'
	NSMutableArray *result = [NSMutableArray arrayWithArray:[[[self album] category] childSubCategories]];
	SMESubCategory *nullSubCategory = [SMESubCategory nullSubCategory];
	if([result containsObject:nullSubCategory])
		return [[[self album] category] childSubCategories];

	[result addObject:nullSubCategory];
	return [NSArray arrayWithArray:result];	
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
