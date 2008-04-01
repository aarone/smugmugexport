//
//  SMAlbumEditController
//  SmugMugExport
//
//  Created by Aaron Evans on 3/23/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMAlbumEditController.h"
#import "SMAlbumInfo.h"
#import "SMGlobals.h"

NSString *SMAlbumID = @"id";
NSString *SMAlbumKey = @"Key";
NSString *SMCategoryID = @"id";
NSString *SMSubCategoryID = @"id";

@interface SMAlbumEditController (Private) 
-(NSArray *)subCategoriesForCategory:(NSDictionary *)aCategory;
-(NSDictionary *)createNullSubcategory;
-(NSArray *)categories;
-(NSArray *)subcategories;
-(NSPredicate *)createRelevantSubCategoryFilterForCategory:(NSDictionary *)aCategory;
-(SMAlbumInfo *)albumInfo;
-(void)refreshCategorySelections;
-(SMAlbumInfo *)albumInfo;
-(void)setAlbumInfo:(SMAlbumInfo *)info;	
-(BOOL)isEditing;
-(void)setIsEditing:(BOOL)v;
@end

@implementation SMAlbumEditController

-(id)init {
	if( (self = [super init]) == nil)
		return nil;

	nibLoaded = NO;
	isBusy = NO;
	albumInfo = [[SMAlbumInfo alloc] init];
	return self;
}

-(void)dealloc {
	[albumInfo release];	
	[super dealloc];
}

+(void)initialize {
	[self setKeys:[NSArray arrayWithObject:@"isEditing"] triggerChangeNotificationsForDependentKey:@"albumActionButtonText"];
}

-(void)setDelegate:(id)aDelegate {
	delegate = aDelegate;
}

-(void)awakeFromNib {
	[albumInfoController addObserver:self forKeyPath:@"selection.category" options:NSKeyValueObservingOptionNew context:NULL];
	[[self albumInfo] setCategory:[[self categories] objectAtIndex:0]];
	[self refreshCategorySelections];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
	[self refreshCategorySelections];
}

-(void)refreshCategorySelections {
	NSDictionary *selectedCategory = [[self albumInfo] category];
	NSMutableArray *relevantSubCategories = [NSMutableArray arrayWithArray:[self subCategoriesForCategory:selectedCategory]];
	
	NSDictionary *nullSubCategory = [self createNullSubcategory];
	[relevantSubCategories insertObject:nullSubCategory	atIndex:0];
	[subCategoriesArrayController setContent:nil];
	[subCategoriesArrayController setContent:[NSArray arrayWithArray:relevantSubCategories]];
	if([[self albumInfo] subCategory] == nil)
		[[self albumInfo] setSubCategory:nullSubCategory];
}

-(NSDictionary *)createNullSubcategory {
	return [NSDictionary dictionaryWithObjectsAndKeys:@"None", @"Title",
			@"0", @"id", nil];
}

-(NSArray *)subCategoriesForCategory:(NSDictionary *)aCategory {
	NSArray *relevantSubCategories = [[self subcategories] filteredArrayUsingPredicate:[self createRelevantSubCategoryFilterForCategory:aCategory]];
	return (relevantSubCategories == nil) ? [NSArray array] : relevantSubCategories;
}

-(NSPredicate *)createRelevantSubCategoryFilterForCategory:(NSDictionary *)aCategory {
	if(IsEmpty([self categories]) || IsEmpty([self subcategories]) || aCategory == nil)
		return [NSPredicate predicateWithValue:YES];
	
	return [NSPredicate predicateWithFormat:@"Category.id = %@", [aCategory objectForKey:@"id"]];
}

+(SMAlbumEditController *)controller {
	return [[[[self class] alloc] init] autorelease];
}

-(void)loadNibIfNecessary {
	if(!nibLoaded)
		[NSBundle loadNibNamed: @"AlbumEdit" owner: self];
	
	nibLoaded = YES;
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

-(void)showAlbumCreateSheet:(id)delegate forWindow:(NSWindow *)aWindow {
	[self loadNibIfNecessary];
	
	[self setIsEditing:NO];
	[self setAlbumInfo:[SMAlbumInfo albumInfo]];
	[[self albumInfo] setCategory:[[self categories] objectAtIndex:0]];
	[self refreshCategorySelections];
	
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
		[delegate createAlbum:[self albumInfo]];
	} else if( [delegate respondsToSelector:@selector(editAlbum:)]) {
		[delegate editAlbum:[self albumInfo]];
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

-(SMAlbumInfo *)albumInfo {
	return albumInfo;
}

-(void)setAlbumInfo:(SMAlbumInfo *)info {
	if(albumInfo != info) {
		[albumInfo release];
		albumInfo = [info retain];
	}
}

-(void)showAlbumEditSheet:(id)delegate
				forWindow:(NSWindow *)aWindow
				 forAlbum:(SMAlbumRef *)ref
			withAlbumInfo:(SMAlbumInfo *)info {
	[self loadNibIfNecessary];
	
	[self setAlbumInfo:info];
	[self setIsEditing:YES];

	isSheetOpen = YES;
	[NSApp beginSheet:[self newAlbumSheet]
	   modalForWindow:aWindow
		modalDelegate:self
	   didEndSelector:@selector(editAlbumDidEndSheet:returnCode:contextInfo:)
		  contextInfo:ref];
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


@end
