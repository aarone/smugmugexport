//
//  SMAlbum.h
//  SmugMugExport
//
//  Created by Aaron Evans on 3/23/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SMData.h"

@class SMAlbumRef, SMSubCategory, SMCategory;

@interface SMAlbum : NSObject {
	NSMutableDictionary *albumData;
	SMCategory *category;
	SMSubCategory * subCategory;
}

-(id)initWithDictionary:(NSMutableDictionary *)dict;
+(SMAlbum *)album; //empty album
+(SMAlbum *)albumWithDictionary:(NSMutableDictionary *)dict; // from smugmug album dictionary

-(NSString *)albumKey;
-(NSString *)albumId;
-(NSString *)title;
-(void)setTitle:(NSString *)title;
-(SMAlbumRef *)ref;
-(SMSubCategory *)subCategory;
-(void)setCategory:(SMCategory *)cat;
-(SMCategory *)category;
-(void)setSubCategory:(SMSubCategory *)cat;

-(NSString *)description;
-(void)setDescription:(NSString *)aDescription;
-(NSString *)keywords;
-(void)setKeywords:(NSString *)keywords;

-(BOOL)isPublic;
-(void)setIsPublic:(BOOL)v;
-(BOOL)isSharingEnabled;
-(void)setIsSharingEnabled:(BOOL)v;
-(BOOL)isPrintable;
-(void)setIsPrintable:(BOOL)v;
-(BOOL)showsFilenames;
-(void)setShowsFilenames:(BOOL)v;
-(BOOL)allowsComments;
-(void)setAllowsComments:(BOOL)v;
-(BOOL)allowsExternalLinking;
-(void)setAllowsExternalLinking:(BOOL)v;
-(BOOL)showsOriginals;
-(void)setShowsOriginals:(BOOL)v;
-(BOOL)allowsFriendsToEdit;
-(void)setAllowsFriendsToEdit:(BOOL)v;
-(BOOL)displaysEXIFInfo;
-(void)setDisplaysEXIFInfo:(BOOL)v;
-(BOOL)allowsFamilyToEdit;
-(void)setAllowsFamilyToEdit:(BOOL)v;

-(NSDictionary *)toDictionary;
// album representations are not equivalent for GET and PUTs
-(NSDictionary *)toEditDictionary;
@end
