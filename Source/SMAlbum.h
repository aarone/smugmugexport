//
//  SMAlbum.h
//  SmugMugExport
//
//  Created by Aaron Evans on 3/23/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SMAlbumRef;

@interface SMAlbum : NSObject {
	NSDictionary *response;
}

// response is a JSON object response from SmugMug for the album as an NSDictionary
-(id)initWithSMResponse:(NSDictionary *)response;
+(SMAlbum *)albumWithSMResponse:(NSDictionary *)response;

-(NSString *)albumKey;
-(NSString *)albumId;
-(NSDictionary *)category;
-(NSDictionary *)subCategory;
-(NSString *)title;
-(NSString *)categoryId;
-(NSString *)subCategoryId;
-(SMAlbumRef *)ref;

@end
