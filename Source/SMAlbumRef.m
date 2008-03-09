//
//  SMAlbumRef
//  SmugMugExport
//
//  Created by Aaron Evans on 3/9/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMAlbumRef.h"


@implementation SMAlbumRef

-(id)initWithId:(NSString *)anId key:(NSString *)key {
	if((self = [super init]) == nil)
		return nil;
	
	albumId = [anId retain];
	albumKey = [key retain];
	return self;
}

+(SMAlbumRef *)refWithId:(NSString *)anId key:(NSString *)aKey {
	return [[[self class] alloc] initWithId:anId key:aKey];
}

-(NSString *)description {
	return [NSString stringWithFormat:@"id: %@ key:%@", [self albumId], [self albumKey]];
}

-(void)dealloc {
	[albumId release];
	[albumKey release];
	
	[super dealloc];
}

-(NSString *)albumId {
	return albumId;
}

-(NSString *)albumKey {
	return albumKey;
}

@end
