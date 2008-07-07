//
//  SMAlbum.m
//  SmugMugExport
//
//  Created by Aaron Evans on 3/23/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMAlbum.h"
#import "SMAlbumRef.h"
#import "SMSubCategory.h"
#import "SMCategory.h"


@interface NSMutableDictionary (SMDictionaryAdditions)
-(void)nilSafeSetObject:(id)obj forKey:(id)aKey;
-(void)setBool:(BOOL)v forKey:(id)key;
@end

@implementation NSMutableDictionary (SMDictionaryAdditions)
-(void)setBool:(BOOL)v forKey:(id)key {
	[self setObject:[NSNumber numberWithBool:v] forKey:key];
}

-(void)nilSafeSetObject:(id)obj forKey:(id)aKey {
	if(obj == nil)
		[self removeObjectForKey:aKey];
	else
		[self setObject:obj forKey:aKey];
}

@end

@interface SMAlbum (Private)
-(void)setAlbumData:(NSMutableDictionary *)d;
-(NSMutableDictionary *)albumData;
-(NSDictionary *)categoryDict;
-(NSDictionary *)subCategoryDict;
@end

@implementation SMAlbum

-(id)init {
	return [self initWithDictionary:nil];
}

-(id)initWithDictionary:(NSMutableDictionary *)dict {
	if( ! (self = [super init]))
		return nil;
	
	BOOL useDefaults = dict == nil;
	if(useDefaults) {
		[self setAlbumData:[NSMutableDictionary dictionary]];
		[self setTitle:@""];
		[self setDescription:@""];
		[self setKeywords:@""];
		[self setIsPublic:YES];
		[self setIsSharingEnabled:YES];
		[self setIsPrintable:YES];
		[self setShowsFilenames:YES];
		[self setAllowsComments:YES];
		[self setAllowsExternalLinking:YES];
		[self setShowsOriginals:YES];
		[self setAllowsFriendsToEdit:YES];
		[self setDisplaysEXIFInfo:YES];
		[self setAllowsFamilyToEdit:YES];
		[self setCategory:nil];
		[self setSubCategory:nil];
	} else {
		[self setAlbumData:dict];
		if([[[self categoryDict] objectForKey:@"id"] intValue] == 0)
			[self setCategory:nil];
		else
			[self setCategory:(SMCategory *)[SMCategory dataWithSourceData:[self categoryDict]]];
		
		if([[[self subCategoryDict] objectForKey:@"id"] intValue] == 0)
			[self setSubCategory:nil];
		else
			[self setSubCategory:(SMSubCategory *)[SMSubCategory dataWithSourceData:[self subCategoryDict]]];
	}
	
	return self;
}

+(SMAlbum *)album { //empty album
	return [[[[self class] alloc] init] autorelease];
}

+(SMAlbum *)albumWithDictionary:(NSMutableDictionary *)dict {
	return [[[[self class] alloc] initWithDictionary:dict] autorelease];
}

-(void)dealloc {
	[self setAlbumData:nil];
	[super dealloc];
}

-(void)setAlbumData:(NSMutableDictionary *)d {
	if(d != albumData) {
		[albumData release];
		albumData = [d retain];
	}
}

-(NSMutableDictionary *)albumData {
	return albumData;
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
	return [SMAlbumRef refWithId:[self albumId]	key:[self albumKey]];
}

-(NSString *)albumKey {
	return [[self albumData] objectForKey:@"Key"];
}

-(NSString *)albumId {
	return [[[self albumData] objectForKey:@"id"] stringValue];
}

-(NSDictionary *)categoryDict {
	return [[self albumData] objectForKey:@"Category"];
}

-(NSDictionary *)subCategoryDict {
	return [[self albumData] objectForKey:@"SubCategory"];
}

-(NSString *)title {
	return [[self albumData] objectForKey:@"Title"];
}

-(void)setTitle:(NSString *)title {
	[[self albumData] nilSafeSetObject:title forKey:@"Title"];
}

-(SMSubCategory *)subCategory {
	return subCategory;
}

-(void)setSubCategory:(SMSubCategory *)cat {
	if(cat != subCategory) {
		[subCategory release];
		subCategory = [cat retain];
	}
}

-(SMCategory *)category {
	return category;
}

-(void)setCategory:(SMCategory *)cat {
	if(cat != category) {
		[category release];
		category = [cat retain];
	}
	[self setSubCategory:nil]; // subcategories are subordinates of categories
}

-(NSString *)description {
	return [[self albumData] objectForKey:@"Description"];
}

-(void)setDescription:(NSString *)aDescription {
	[[self albumData] nilSafeSetObject:aDescription forKey:@"Description"];
}

-(NSString *)keywords {
	return [[self albumData] objectForKey:@"Keywords"];
}

-(void)setKeywords:(NSString *)keywords {
	[[self albumData] nilSafeSetObject:keywords forKey:@"Keywords"];
}

-(BOOL)isPublic {
	return [[[self albumData] objectForKey:@"Public"] boolValue];
}

-(void)setIsPublic:(BOOL)v {
	[[self albumData] setBool:v	forKey:@"Public"];
}

-(BOOL)isSharingEnabled {
	return [[[self albumData] objectForKey:@"Share"] boolValue];
}

-(void)setIsSharingEnabled:(BOOL)v {
	[[self albumData] setBool:v forKey:@"Share"];
}

-(BOOL)isPrintable {
	return [[[self albumData] objectForKey:@"Printable"] boolValue];
}

-(void)setIsPrintable:(BOOL)v {
	[[self albumData] setBool:v	forKey:@"Printable"];
}

-(BOOL)showsFilenames {
	return [[[self albumData] objectForKey:@"Filenames"] boolValue];
}

-(void)setShowsFilenames:(BOOL)v {
	[[self albumData] setBool:v	forKey:@"Filenames"];
}

-(BOOL)allowsComments {
	return [[[self albumData] objectForKey:@"Comments"] boolValue];
}


-(void)setAllowsComments:(BOOL)v {
	[[self albumData] setBool:v	forKey:@"Comments"];
}

-(BOOL)allowsExternalLinking {
	return [[[self albumData] objectForKey:@"External"] boolValue];
}

-(void)setAllowsExternalLinking:(BOOL)v {
	[[self albumData] setBool:v	forKey:@"External"];
}

-(BOOL)showsOriginals {
	return [[[self albumData] objectForKey:@"Originals"] boolValue];
}

-(void)setShowsOriginals:(BOOL)v {
	[[self albumData] setBool:v	forKey:@"Originals"];
}

-(BOOL)allowsFriendsToEdit {
	return [[[self albumData] objectForKey:@"FriendEdit"] boolValue];
}

-(void)setAllowsFriendsToEdit:(BOOL)v {
	[[self albumData] setBool:v	forKey:@"FriendEdit"];
}

-(BOOL)displaysEXIFInfo {
	return [[[self albumData] objectForKey:@"EXIF"] boolValue];
}

-(void)setDisplaysEXIFInfo:(BOOL)v {
	[[self albumData] setBool:v	forKey:@"EXIF"];
}

-(BOOL)allowsFamilyToEdit {
	return [[[self albumData] objectForKey:@"FamilyEdit"] boolValue];
}

-(void)setAllowsFamilyToEdit:(BOOL)v {
	[[self albumData] setBool:v	forKey:@"FamilyEdit"];
}

-(NSDictionary *)toDictionary {
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:[self albumData]];
	[result nilSafeSetObject:[self categoryDict] forKey:@"Category"];
	[result nilSafeSetObject:[self subCategoryDict] forKey:@"SubCategory"];
	return [NSDictionary dictionaryWithDictionary:result];
}

-(NSDictionary *)toEditDictionary {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	[result setObject:[self albumId] forKey:@"AlbumID"];
	[result setObject:[NSNumber numberWithInt:[[self category] identifier]] forKey:@"CategoryID"];
	[result setObject:[NSNumber numberWithInt:[[self subCategory] identifier]] forKey:@"SubCategoryID"];
	[result setObject:[self title] forKey:@"Title"];
	[result setObject:[self description] forKey:@"Description"];
	[result setObject:[NSNumber numberWithBool:[self isPublic]] forKey:@"Public"];
	[result setObject:[NSNumber numberWithBool:[self isSharingEnabled]] forKey:@"Share"];
	[result setObject:[NSNumber numberWithBool:[self isPrintable]] forKey:@"Printable"];
	[result setObject:[NSNumber numberWithBool:[self showsFilenames]] forKey:@"Filenames"];
	[result setObject:[NSNumber numberWithBool:[self allowsComments]] forKey:@"Comments"];
	[result setObject:[NSNumber numberWithBool:[self allowsExternalLinking]] forKey:@"FriendEdit"];
	[result setObject:[NSNumber numberWithBool:[self showsOriginals]] forKey:@"Originals"];
	[result setObject:[NSNumber numberWithBool:[self allowsFriendsToEdit]] forKey:@"FriendEdit"];
	[result setObject:[NSNumber numberWithBool:[self displaysEXIFInfo]] forKey:@"EXIF"];
	[result setObject:[NSNumber numberWithBool:[self allowsFamilyToEdit]] forKey:@"FamilyEdit"];	
	return [NSDictionary dictionaryWithDictionary:result];
}

@end


