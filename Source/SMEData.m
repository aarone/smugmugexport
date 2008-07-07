//
//  SMEData.m
//  SmugMugExport
//
//  Created by Aaron Evans on 6/29/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMEData.h"

@interface SMEData (Private)
-(void)setSourceData:(id)d;
@end


@implementation SMEData


-(id)initWithSourceData:(id)src {
	if( !(self = [super init]))
		return nil;
	
	[self setSourceData:src];
	return self;
}

-(void)dealloc {
	[sourceData release];
	[super dealloc];
}

+(SMEData *)dataWithSourceData:(id)src {
	return [[[[self class] alloc] initWithSourceData:src] autorelease];
}

-(void)setSourceData:(id)d {
	if(d != sourceData) {
		[sourceData release];
		sourceData = [d retain];
	}
}

-(id)sourceData {
	return sourceData;
}

@end
