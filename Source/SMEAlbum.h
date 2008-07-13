//
//  SMEAlbum.h
//  SmugMugExport
//
//  Created by Aaron Evans on 3/23/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMEConciseAlbum.h"

@class SMEAlbumRef, SMESubCategory, SMECategory;

@interface SMEAlbum : SMEConciseAlbum {
}

-(id)initWithDictionary:(NSMutableDictionary *)dict;
+(SMEAlbum *)album; //empty album
+(SMEAlbum *)albumWithDictionary:(NSMutableDictionary *)dict; // from smugmug album dictionary

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

// album representations are not equivalent for GET and PUTs
-(NSDictionary *)toEditDictionary;
@end
