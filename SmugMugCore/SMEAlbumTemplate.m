//
//  SMEAlbumTemplate.m
//  SmugMugExport
//
//  Created by Nicholas Riley on 6/2/12.
//  Copyright 2012 Nicholas Riley. All rights reserved.
//

#import "SMEAlbumTemplate.h"


@implementation SMEAlbumTemplate

-(NSString *)name {
	return [[self albumData] objectForKey:@"AlbumTemplateName"];
}

-(unsigned int)hash {
	return [[self albumId] hash];
}

-(BOOL)isEqual:(id)anotherObject {
	if(![anotherObject isKindOfClass:[self class]])
		return NO;
	
	return [[self albumId] isEqual:[anotherObject albumId]];
}

@end
