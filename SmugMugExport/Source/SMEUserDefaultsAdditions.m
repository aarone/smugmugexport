//
//  SMEUserDefaultsAdditions.m
//  SmugMugExport
//
//  Created by Aaron Evans on 6/10/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "SMEUserDefaultsAdditions.h"
#import "SMEUserDefaults.h"

@implementation NSUserDefaults (SMEUserDefaultsAdditions)

+(SMEUserDefaults *)smugMugUserDefaults {
	return [SMEUserDefaults smugMugDefaults];
}

@end
