//
//  SMImageRef.m
//  SmugMugExport
//
//  Created by Aaron Evans on 3/9/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMImageRef.h"

@interface  SMImageRef (Private) 
-(void)setImageId:(NSString *)anId;
-(void)setImageKey:(NSString *)aKey;
@end

@implementation SMImageRef

-(id)initWithId:(NSString *)anId key:(NSString *)aKey {
	if(!(self = [super init]))
		return nil;
	
	[self setImageId:anId];
	[self setImageKey:aKey];
	return self;
}

+(SMImageRef *)refWithId:(NSString *)anId key:(NSString *)key {
	return [[[self class] alloc] initWithId:anId key:key];
}

-(id)initWithDictionary:(NSDictionary *)aDict {
	return [self initWithId:[aDict objectForKey:@"id"] key:[aDict objectForKey:@"Key"]];
}

+(SMImageRef *)refWithDictionary:(NSDictionary *)aDict {
	return [[[[self class] alloc] initWithDictionary:aDict] autorelease];
}

-(unsigned int)hash {
	return 31 * [[self imageId] hash] + [[self imageKey] hash];
}

-(BOOL)isEqual:(id)anotherObject {
	if(![anotherObject isKindOfClass:[self class]])
		return NO;
	
	return [[self imageKey] isEqual:[anotherObject imageKey]] &&
		[[self imageId] isEqual:[anotherObject imageId]];
}

-(NSString *)description {
	return [NSString stringWithFormat:@"id: %@ key:%@", [self imageId], [self imageKey]];
}

-(void)dealloc {
	[self setImageId:nil];
	
	[super dealloc];
}

-(void)setImageId:(NSString *)anId {
	if([self imageId] != nil)
		[[self imageId] release];
	
	imageId = [anId retain];
}
			
-(NSString *)imageId {
	return imageId;
}


-(void)setImageKey:(NSString *)aKey {
	if([self imageKey] != nil)
		[[self imageKey] release];
	
	imageKey = [aKey retain];
}


-(NSString *)imageKey {
	return imageKey;
}

@end
