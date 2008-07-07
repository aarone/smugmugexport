//
//  SMEAlbumRef.h
//  SmugMugExport
//
//  Created by Aaron Evans on 3/9/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SMEAlbumRef : NSObject {
	NSString *albumId;
	NSString *albumKey;
}

-(id)initWithId:(NSString *)id key:(NSString *)key;
+(SMEAlbumRef *)refWithId:(NSString *)anId key:(NSString *)aKey;
+(SMEAlbumRef *)refWithRef:(SMEAlbumRef *)ref;
-(NSString *)albumId;
-(NSString *)albumKey;

@end
