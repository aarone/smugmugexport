//
//  SMECategory.h
//  SmugMugExport
//
//  Created by Aaron Evans on 7/3/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMEData.h"

@interface SMECategory : SMEData {
	NSArray *childSubCategories;
}

+(SMECategory *)nullCategory;
-(unsigned int)identifier;
-(NSString *)title;
-(NSDictionary *)toDict;
-(NSArray *)childSubCategories;
-(void)setChildSubCategories:(NSArray *)categories;
@end
