//
//  SMESubCategory.m
//  SmugMugExport
//
//  Created by Aaron Evans on 7/3/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMESubCategory.h"


@implementation SMESubCategory

+(SMESubCategory *)nullSubCategory {
	return [[[[self class] alloc] initWithSourceData:[NSDictionary dictionaryWithObjectsAndKeys:
										 [NSNumber numberWithInt:0], @"id",
										 NSLocalizedString(@"(no subcategory)", @"null subcategory name"), @"Name",
										 [SMECategory nullCategory], @"Category",
													 nil]] autorelease];
}

-(unsigned int)parentCategoryIdentifier {
	return [[[[self sourceData] objectForKey:@"Category"] objectForKey:@"id"] intValue];
}

@end


