//
//  SMImageURLs.m
//  SmugMugExport
//
//  Created by Aaron Evans on 7/7/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMImageURLs.h"


@implementation SMImageURLs

-(unsigned int)identifier {
	return [[[self sourceData] objectForKey:@"id"] intValue];
}

-(NSString *)albumURL {
	return [[self sourceData] objectForKey:@"AlbumURL"];
}

-(NSString *)tinyURL {
	return [[self sourceData] objectForKey:@"TinyURL"];
}

-(NSString *)thumbURL {
	return [[self sourceData] objectForKey:@"ThumbURL"];
}

-(NSString *)smallURL {
	return [[self sourceData] objectForKey:@"SmallURL"];
}

-(NSString *)mediumURL {
	return [[self sourceData] objectForKey:@"MediumURL"];
}

-(NSString *)largeURL {
	return [[self sourceData] objectForKey:@"LargeURL"];
}

-(NSString *)originalURL {
	return [[self sourceData] objectForKey:@"OriginalURL"];
}

@end
