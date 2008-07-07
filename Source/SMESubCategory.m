//
//  SMESubCategory.m
//  SmugMugExport
//
//  Created by Aaron Evans on 7/3/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMESubCategory.h"


@implementation SMESubCategory

-(unsigned int)parentCategoryIdentifier {
	return [[[[self sourceData] objectForKey:@"Category"] objectForKey:@"id"] intValue];
}

@end


