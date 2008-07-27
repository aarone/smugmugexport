/*
 *  SMERequest.h
 *  SmugMugExport
 *
 *  Created by Aaron Evans on 7/26/08.
 *  Copyright 2008 Aaron Evans. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

@protocol SMERequest

-(NSError *)error;

-(NSData *)data;

-(BOOL)wasSuccessful;

@end
