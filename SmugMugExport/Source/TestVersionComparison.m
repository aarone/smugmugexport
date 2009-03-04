//
//  TestVersionComparison.m
//  SmugMugExport
//
//  Created by Aaron Evans on 5/25/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "TestVersionComparison.h"

#import "NSStringAdditions.h"

@implementation TestVersionComparison

-(void)testVersionCompareQualifierMicro {
	NSString* v1 = @"1.0.7.p1";
	NSString* v2 = @"1.0.8";
	STAssertTrue([v1 compareVersionToVersion:v2] == NSOrderedAscending, @"Error comparing versions");
}

-(void)testVersionCompareQualifier {
	NSString* v1 = @"1.0.7";
	NSString* v2 = @"1.0.7.p1";
	STAssertTrue([v1 compareVersionToVersion:v2] == NSOrderedAscending, @"Error comparing versions");
}


@end
