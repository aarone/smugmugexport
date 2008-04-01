//
//  SMAlbum.m
//  SmugMugExport
//
//  Created by Aaron Evans on 3/23/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMAlbum.h"
#import "SMAlbumRef.h"

@interface SMAlbum (Private)
-(void)setResponse:(NSDictionary *)resp;
-(NSDictionary *)response;
@end

@implementation SMAlbum

+(SMAlbum *)albumWithSMResponse:(NSDictionary *)aResponse {
	return [[[SMAlbum alloc] initWithSMResponse:aResponse] autorelease];
}

-(id)initWithSMResponse:(NSDictionary *)aResponse {
	if( (self = [super init]) == nil)
		return nil;
	
	[self setResponse:aResponse];
	return self;
}

-(void)dealloc {
	[response release];
	[super dealloc];
}

-(unsigned int)hash {
	return 31 * [[self albumId] hash] + [[self albumKey] hash];
}

-(BOOL)isEqual:(id)anotherObject {
	if(![anotherObject isKindOfClass:[self class]])
		return NO;
	
	return [[self albumId] isEqual:[anotherObject albumId]] &&
		[[self albumKey] isEqual:[anotherObject albumKey]];
}

-(void)setResponse:(NSDictionary *)resp {
	if(response != resp) {
		[response release];
		response = [resp retain];
	}
}

-(NSDictionary *)response {
	return response;
}

-(SMAlbumRef *)ref {
	return [SMAlbumRef refWithId:[self albumId]	key:[self albumKey]];
}

-(NSString *)albumKey {
	return [response objectForKey:@"Key"];
}

-(NSString *)albumId {
	return [[response objectForKey:@"id"] stringValue];
}

-(NSDictionary *)category {
	return [response objectForKey:@"Category"];
}

-(NSDictionary *)subCategory {
	return [response objectForKey:@"SubCategory"];
}

-(NSString *)title {
	return [response objectForKey:@"Title"];
}

-(NSString *)categoryId {
	return [[[self category] objectForKey:@"id"] stringValue];
}

-(NSString *)subCategoryId {
	return [[[self subCategory] objectForKey:@"id"] stringValue];
}

@end
