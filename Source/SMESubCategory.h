//
//  SMESubCategory.h
//  SmugMugExport
//
//  Created by Aaron Evans on 7/3/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMECategory.h"

@interface SMESubCategory : SMECategory {

}

+(SMESubCategory *)nullSubCategory;
-(unsigned int)parentCategoryIdentifier;

@end
