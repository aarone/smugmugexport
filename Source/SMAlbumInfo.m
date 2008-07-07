	//
//  SMAlbumInfo.m
//  SmugMugExport
//
//  Created by Aaron Evans on 3/23/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMAlbum.h"
#import "SMGlobals.h"
#import "SMAlbumRef.h"
#import "SMCategory.h"
#import "SMSubCategory.h"

@interface SMAlbumInfo (Private)
-(void)setDefaults;
@end

@implementation SMAlbumInfo

-(id)init {
	if( (self = [super init]) == nil)
		return nil;
	
	[self setDefaults];
	return self;
}

-(id)initWithAlbum:(SMAlbum *)album {
	if( (self = [super init]) == nil)
		return nil;
	
	[self setDefaults];
	[self setTitle:[album title]];
	[self setCategory:[album category]];
	[self setSubCategory:[album subCategory]];
	
	return self;
}

+(SMAlbumInfo *)albumInfo {
	return [[[[self class] alloc] init] autorelease];
}

+(SMAlbumInfo *)albumInfoWithAlbum:(SMAlbum *)album {
	return [[[[self class] alloc] initWithAlbum:album] autorelease];
}

+(SMAlbumInfo *)albumInfoWithSMResponse:(NSDictionary *)response {
	SMAlbumInfo *info = [SMAlbumInfo albumInfo];
	[info setIsPublic:[[response objectForKey:@"Public"] boolValue]];
	[info setAlbumKey:[response objectForKey:@"Key"]];
	[info setAlbumId:[response objectForKey:@"id"]];
	[info setShowsFilenames:[[response objectForKey:@"Filenames"] boolValue]];
	[info setAllowsComments:[[response objectForKey:@"Comments"] boolValue]];
	[info setAllowsExternalLinking:[[response objectForKey:@"External"] boolValue]];
	[info setDisplaysEXIFInfo:[[response objectForKey:@"EXIF"] boolValue]];
	[info setIsSharingEnabled:[[response objectForKey:@"Share"] boolValue]];
	[info setIsPrintable:[[response objectForKey:@"Printable"] boolValue]];
	[info setShowsOriginals:[[response objectForKey:@"Originals"] boolValue]];
	[info setAllowsFriendsToEdit:[[response objectForKey:@"FriendEdit"] boolValue]];
	[info setAllowsFamilyToEdit:[[response objectForKey:@"FamilyEdit"] boolValue]];
	[info setTitle:[response objectForKey:@"Title"]];
	[info setDescription:[response objectForKey:@"Description"]];
	[info setKeywords:[response objectForKey:@"Keywords"]];
	[info setSubCategoryId:[[response objectForKey:@"SubCategory"] objectForKey:@"id"]];
	[info setCategoryId:[[response objectForKey:@"Category"] objectForKey:@"id"]];
	 
	//	[info setCategory:[info categoryForId:[[response objectForKey:@"Category"] objectForKey:@"id"] categories:categories]];
//	[info setSubCategory:[info subcategoryForId:[[response objectForKey:@"SubCategory"] objectForKey:@"id"] subcategories:subcatgegories]];
		
	return info;
}

-(void)dealloc {
	[albumKey release];
	[albumId release];
	[category release];
	[subCategory release];
	[title release];
	[description release];
	[subCategoryId release];
	[categoryId release];
	[keywords release];
	
	[super dealloc];
}

-(unsigned int)hash {
	return 31 * [[self albumId] hash] + [[self albumKey] hash];
}

-(BOOL)isEqual:(id)anotherObject {
	if(![anotherObject isKindOfClass:[self class]])
		return NO;
	
	return [[self albumId] isEqual:[anotherObject albumId]] &&
		[[self albumKey] isEqual:[anotherObject albumKey]];
}

-(SMAlbumRef *)ref {
	return [SMAlbumRef refWithId:[self albumId] key:[self albumKey]];
}

-(void)setDefaults {
	[self setTitle:@""];
	[self setSubCategoryId:nil];
	[self setCategoryId:nil];
	[self setKeywords:@""];
	[self setDescription:@""];
	[self setIsPublic:YES];
	[self setIsPrintable:YES];
	[self setShowsFilenames:YES];
	[self setAllowsComments:YES];
	[self setAllowsFamilyToEdit:YES];
	[self setAllowsExternalLinking:YES];
	[self setShowsOriginals:YES];
	[self setAllowsFriendsToEdit:YES];
	[self setDisplaysEXIFInfo:YES];
	[self setIsSharingEnabled:YES];
}

-(NSString *)albumKey {
	return albumKey;
}

-(void)setAlbumKey:(NSString *)aKey {
	if(aKey != albumKey) {
		[albumKey release];
		albumKey = [aKey retain];
	}
}

-(NSString *)albumId {
	return albumId;
}

-(void)setAlbumId:(NSString *)anId {
	if(anId != albumId) {
		[albumId release];
		albumId = [anId retain];
	}
}

-(NSString *)categoryId {
	return categoryId;
}

-(void)setCategoryId:(NSString*)anId {
	if(anId != categoryId) {
		[categoryId release];
		categoryId = [anId retain];
	}
}

-(NSString *)subCategoryId {
	return subCategoryId;
}

-(void)setSubCategoryId:(NSString *)anId {
	if(anId != subCategoryId) {
		[subCategoryId release];
		subCategory = [anId retain];
	}
}


-(SMCategory *)category {
	return category;
}

-(void)setCategory:(SMCategory *)anId {
	if(category != anId) {
		[category release];
		category = [anId retain];
	}
}

-(SMSubCategory *)subCategory {
	return subCategory;
}

-(void)setSubCategory:(SMSubCategory *)anId {
	if(subCategory != anId) {
		[subCategory release];
		subCategory = [anId retain];
	}
}

-(NSString *)title {
	return title;
}

-(void)setTitle:(NSString *)aTitle {
	if(title != aTitle) {
		[title release];
		title = [aTitle retain];
	}
}

-(NSString *)description {
	return description;
}

-(void)setDescription:(NSString *)aDescription {
	if(description != aDescription) {
		[description release];
		description = [aDescription retain];
	}
}

// TODO make the UI specify a collection of keywords
-(NSString *)keywords {
	return keywords;
}

-(void)setKeywords:(NSString *)_keywords {
	if(keywords != _keywords) {
		[keywords release];
		keywords = [_keywords retain];
	}
}

-(BOOL)isPublic {
	return isPublic;
}

-(void)setIsPublic:(BOOL)v {
	isPublic = v;
}

-(BOOL)isPrintable {
	return isPrintable;
}

-(void)setIsPrintable:(BOOL)v {
	isPrintable = v;
}

-(BOOL)showsFilenames {
	return showsFilenames;
}

-(void)setShowsFilenames:(BOOL)v {
	showsFilenames = v;
}

-(BOOL)isSharingEnabled {
	return isSharingEnabled;
}

-(void)setIsSharingEnabled:(BOOL)v {
	isSharingEnabled = v;
}

-(BOOL)allowsComments {
	return allowsComments;
}

-(void)setAllowsComments:(BOOL)v {
	allowsComments = v;
}

-(BOOL)allowsExternalLinking {
	return allowsExternalLinking;
}

-(void)setAllowsExternalLinking:(BOOL)v {
	allowsExternalLinking = v;
}

-(BOOL)showsOriginals {
	return showsOriginals;
}

-(void)setShowsOriginals:(BOOL)v {
	showsOriginals = v;
}

-(BOOL)allowsFriendsToEdit {
	return allowsFriendsToEdit;
}

-(void)setAllowsFriendsToEdit:(BOOL)v {
	allowsFriendsToEdit = v;
}

-(BOOL)allowsFamilyToEdit {
	return allowsFamilyToEdit;
}

-(void)setAllowsFamilyToEdit:(BOOL)v {
	allowsFamilyToEdit = v;
}

-(BOOL)displaysEXIFInfo {
	return displaysEXIFInfo;
}

-(void)setDisplaysEXIFInfo:(BOOL)v {
	displaysEXIFInfo = v;
}

-(NSDictionary *)toDictionary {
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   [NSNumber numberWithBool:[self isPublic]], @"Public",
								   [NSNumber numberWithBool:[self showsFilenames]], @"Filenames",
								   [NSNumber numberWithBool:[self allowsComments]], @"Comments",
								   [NSNumber numberWithBool:[self allowsExternalLinking]], @"External",
								   [NSNumber numberWithBool:[self displaysEXIFInfo]], @"EXIF",
								   [NSNumber numberWithBool:[self isSharingEnabled]], @"Share",
								   [NSNumber numberWithBool:[self isPrintable]], @"Printable",
								   [NSNumber numberWithBool:[self showsOriginals]], @"Originals",
								   [NSNumber numberWithBool:[self allowsFriendsToEdit]], @"FriendEdit",
								   [NSNumber numberWithBool:[self allowsFamilyToEdit]], @"FamilyEdit",
								   [self title], @"Title",
								   [self description], @"Description",
								   [self keywords], @"Keywords",
								   nil];
	if([self albumId] != nil)
		[result setObject:[self albumId] forKey:@"AlbumID"];

	if([self albumKey] != nil)
		[result setObject:[self albumKey] forKey:@"AlbumKey"];
	
	[result setObject:[self categoryId] forKey:@"CategoryID"];	
	[result setObject:[self subCategoryId] forKey:@"SubCategoryID"];
	
	return result;
}

@end
