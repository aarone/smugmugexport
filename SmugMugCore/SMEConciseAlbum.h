//
//  SMEConciseAlbum.h
//  SmugMugExport
//
//  Created by Aaron Evans on 7/13/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SMECategory, SMESubCategory, SMEAlbumRef;

@interface SMEConciseAlbum : NSObject {
	NSMutableDictionary *albumData;
	SMECategory *category;
	SMESubCategory * subCategory;
	BOOL hasChanges;
}

-(id)initWithDictionary:(NSMutableDictionary *)dict;
+(SMEConciseAlbum *)album; //empty album
+(SMEConciseAlbum *)albumWithDictionary:(NSMutableDictionary *)dict; // from smugmug album dictionary

-(SMEAlbumRef *)ref;

-(NSString *)albumKey;
-(NSString *)albumId;
-(NSString *)title;
-(void)setTitle:(NSString *)title;
-(SMEAlbumRef *)ref;
-(SMESubCategory *)subCategory;
-(void)setCategory:(SMECategory *)cat;
-(SMECategory *)category;
-(void)setSubCategory:(SMESubCategory *)cat;

-(NSDictionary *)toDictionary;

-(void)setAlbumData:(NSMutableDictionary *)d;
-(NSMutableDictionary *)albumData;

-(NSDictionary *)categoryDict;
-(NSDictionary *)subCategoryDict;

@end
