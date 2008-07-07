//
//  SMEUserDefaultsAdditions.m
//  SmugMugExport
//
//  Created by Aaron Evans on 6/10/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "SMEUserDefaultsAdditions.h"
#import "SMUserDefaults.h"

@implementation NSUserDefaults (SMEUserDefaultsAdditions)

+(SMUserDefaults *)smugMugUserDefaults {
	return [SMUserDefaults smugMugDefaults];
}

@end
