//
//  NSUserDefaultsAdditions.m
//  SmugMugExport
//
//  Created by Aaron Evans on 6/10/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "NSUserDefaultsAdditions.h"
#import "SmugMugUserDefaults.h"

@implementation NSUserDefaults (NSUserDefaultsAdditions)

+(SmugMugUserDefaults *)smugMugUserDefaults {
	return [SmugMugUserDefaults smugMugDefaults];
}

@end
