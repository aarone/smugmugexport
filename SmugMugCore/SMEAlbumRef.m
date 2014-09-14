//
//  SMEAlbumRef
//  SmugMugExport
//
//  Created by Aaron Evans on 3/9/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMEAlbumRef.h"


@implementation SMEAlbumRef

-(id)initWithId:(NSString *)anId key:(NSString *)key {
	if((self = [super init]) == nil)
		return nil;
	
	albumId = [anId retain];
	albumKey = [key retain];
	return self;
}

+(SMEAlbumRef *)refWithRef:(SMEAlbumRef *)ref {
	return [SMEAlbumRef refWithId:[ref albumId] key:[ref albumKey]];
}

+(SMEAlbumRef *)refWithId:(NSString *)anId key:(NSString *)aKey {
	return [[[self class] alloc] initWithId:anId key:aKey];
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
