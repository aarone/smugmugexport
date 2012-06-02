//
//  SMEAlbum.m
//  SmugMugExport
//
//  Created by Aaron Evans on 3/23/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMEAlbum.h"
#import "SMEAlbumRef.h"
#import "SMESubCategory.h"
#import "SMECategory.h"
#import "SMEAlbumTemplate.h"


@implementation NSMutableDictionary (SMEDictionaryAdditions)

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

@implementation SMEAlbum

-(id)init {
	return [self initWithDictionary:nil];
}

-(id)initWithDictionary:(NSMutableDictionary *)dict {
	if( ! (self = [super initWithDictionary:dict]))
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
			[self setCategory:(SMECategory *)[SMECategory dataWithSourceData:[self categoryDict]]];
		
		if([[[self subCategoryDict] objectForKey:@"id"] intValue] == 0)
			[self setSubCategory:nil];
		else
			[self setSubCategory:(SMESubCategory *)[SMESubCategory dataWithSourceData:[self subCategoryDict]]];
	}
	
	return self;
}

+(SMEAlbum *)album { //empty album
	return [[[[self class] alloc] init] autorelease];
}

+(SMEAlbum *)albumWithDictionary:(NSMutableDictionary *)dict {
	return [[[[self class] alloc] initWithDictionary:dict] autorelease];
}

-(void)dealloc {
	[albumTemplate release];
	[super dealloc];
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

-(void)setAlbumTemplate:(SMEAlbumTemplate *)t {
	if(t != albumTemplate) {
		[albumTemplate release];
		albumTemplate = [t retain];
		if (albumTemplate == nil)
			return;
		[[self albumData] setObject:[t albumId] forKey:@"AlbumTemplateID"];
		[self setIsPublic:[t isPublic]];
		[self setIsSharingEnabled:[t isSharingEnabled]];
		[self setIsPrintable:[t isPrintable]];
		[self setShowsFilenames:[t showsFilenames]];
		[self setAllowsComments:[t allowsComments]];
		[self setAllowsExternalLinking:[t allowsExternalLinking]];
		[self setShowsOriginals:[t showsOriginals]];
		[self setAllowsFriendsToEdit:[t allowsFriendsToEdit]];
		[self setDisplaysEXIFInfo:[t displaysEXIFInfo]];
		[self setAllowsFamilyToEdit:[t allowsFamilyToEdit]];
	}
}

-(SMEAlbumTemplate *)albumTemplate {
	return albumTemplate;
}

-(NSString *)emptyIfNil:(NSString *)aString {
	return aString == nil ? @"" : aString;
}

-(NSDictionary *)toEditDictionary {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	[result setObject:[self albumId] forKey:@"AlbumID"];
	[result setObject:[NSNumber numberWithInt:[[self category] identifier]] forKey:@"CategoryID"];
	[result setObject:[NSNumber numberWithInt:[[self subCategory] identifier]] forKey:@"SubCategoryID"];
	[result setObject:[self emptyIfNil:[self title]] forKey:@"Title"];
	[result setObject:[self emptyIfNil:[self description]] forKey:@"Description"];
	[result setObject:[self emptyIfNil:[self keywords]] forKey:@"Keywords"];
	[result setObject:[NSNumber numberWithBool:[self isPublic]] forKey:@"Public"];
	[result setObject:[NSNumber numberWithBool:[self isSharingEnabled]] forKey:@"Share"];
	[result setObject:[NSNumber numberWithBool:[self isPrintable]] forKey:@"Printable"];
	[result setObject:[NSNumber numberWithBool:[self showsFilenames]] forKey:@"Filenames"];
	[result setObject:[NSNumber numberWithBool:[self allowsComments]] forKey:@"Comments"];
	[result setObject:[NSNumber numberWithBool:[self allowsExternalLinking]] forKey:@"External"];
	[result setObject:[NSNumber numberWithBool:[self showsOriginals]] forKey:@"Originals"];
	[result setObject:[NSNumber numberWithBool:[self allowsFriendsToEdit]] forKey:@"FriendEdit"];
	[result setObject:[NSNumber numberWithBool:[self displaysEXIFInfo]] forKey:@"EXIF"];
	[result setObject:[NSNumber numberWithBool:[self allowsFamilyToEdit]] forKey:@"FamilyEdit"];	
	return [NSDictionary dictionaryWithDictionary:result];
}

@end
