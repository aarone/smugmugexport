//
//  SmugMugEntityUnescapeTransformer.m
//  SmugMugExport
//
//  Created by Aaron Evans on 11/18/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import "SmugMugEntityUnescapeTransformer.h"


@implementation SmugMugEntityUnescapeTransformer

+ (Class)transformedValueClass { return [NSString class]; }
+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {
    if (value == nil) 
		return nil;
	
	NSStringFromClass([value class]);
}
@end
