//
//  NSURLAdditions.h
//  SmugMugExport
//
//  Created by Aaron Evans on 5/31/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSURL (NSURLAdditions)

-(NSURL *)URLByAppendingParameterList:(NSDictionary *)params;
@end
