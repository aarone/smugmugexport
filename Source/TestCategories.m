//
//  TestCategories.m
//  SmugMugExport
//
//  Created by Aaron Evans on 5/25/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "TestCategories.h"

#import "NSStringAdditions.h"
#import "NSObjectAdditions.h"

@implementation TestCategories

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

-(void)testInvocation {
	int x = 4;
	int *y = &x;
	[self performSelectorOnMainThread:@selector(callback:nilArg:) withArgs:[NSArray arrayWithObjects:[NSValue valueWithPointer:y], [NSNull null], nil]];
}

-(void)callback:(void *)context nilArg:(id)arg {
	int *x = context;
	NSLog(@"%d", *x);
}

@end
