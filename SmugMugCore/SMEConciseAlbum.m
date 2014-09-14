//
//  SMEConciseAlbum.m
//  SmugMugExport
//
//  Created by Aaron Evans on 7/13/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMEConciseAlbum.h"
#import "SMEAlbum.h"
#import "SMEAlbumRef.h"
#import "SMESubCategory.h"
#import "SMECategory.h"

@implementation SMEConciseAlbum

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

+(SMEConciseAlbum *)album { //empty album
	return [[[[self class] alloc] init] autorelease];
}

+(SMEConciseAlbum *)albumWithDictionary:(NSMutableDictionary *)dict {
	return [[[[self class] alloc] initWithDictionary:dict] autorelease];
}

-(void)setAlbumData:(NSMutableDictionary *)d {
	if(d != albumData) {
		[albumData release];
		albumData = [d retain];
	}
}

-(void)dealloc {
	[albumData release];
	[category release];
	[subCategory release];
	
	[super dealloc];
}

-(NSString *)albumKey {
	return [[self albumData] objectForKey:@"Key"];
}

-(NSString *)albumId {
	return [[[self albumData] objectForKey:@"id"] stringValue];
}

-(NSString *)lastUpdated {
	return [[self albumData] objectForKey:@"LastUpdated"];
}

-(NSURL *)url {
    return [NSURL URLWithString:[[self albumData] objectForKey:@"URL"]];
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

-(SMESubCategory *)subCategory {
	return subCategory;
}

-(void)setSubCategory:(SMESubCategory *)cat {
	if(cat != subCategory) {
		[subCategory release];
		subCategory = [cat retain];
	}
}

-(SMECategory *)category {
	return category;
}

-(void)setCategory:(SMECategory *)cat {
	if(cat != category) {
		[category release];
		category = [cat retain];
	}
}

-(NSMutableDictionary *)albumData {
	return albumData;
}

-(NSUInteger)hash {
	return 31 * [[self albumId] hash] + [[self albumKey] hash];
}

-(BOOL)isEqual:(id)anotherObject {
	if(![anotherObject isKindOfClass:[self class]])
		return NO;
	
	return [[self albumId] isEqual:[anotherObject albumId]] &&
	[[self albumKey] isEqual:[anotherObject albumKey]];
}

-(NSComparisonResult)compareLastUpdated:(SMEConciseAlbum *)other {
	return [[other lastUpdated] compare:[self lastUpdated]];
}

-(SMEAlbumRef *)ref {
	return [SMEAlbumRef refWithId:[self albumId]	key:[self albumKey]];
}

-(NSDictionary *)toDictionary {
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:[self albumData]];
	[result nilSafeSetObject:[NSNumber numberWithInt:[[self category] identifier]] forKey:@"CategoryID"];
	[result nilSafeSetObject:[NSNumber numberWithInt:[[self subCategory] identifier]] forKey:@"SubCategoryID"];
	return [NSDictionary dictionaryWithDictionary:result];
}

@end
