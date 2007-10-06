//
//  NSURLAdditions.h
//  SMExportPlugin
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSURL (NSURLAdditions)

-(NSURL *)URLByAppendingParameterListWithNames:(NSArray *)names values:(NSArray *)values;
@end
