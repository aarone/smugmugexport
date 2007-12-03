//
//  NSImageRepAdditions.h
//  SmugMugExport
//
//  Created by Aaron Evans on 8/25/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSBitmapImageRep (NSBitmapImageRepAdditions)

+(float)defaultJpegScalingFactor;
-(NSData *)scaledRepToMaxWidth:(float)maxWidth maxHeight:(float)maxFactor;
-(NSData *)scaledRepToWidth:(float)widthFactor height:(float)heightFactor;

@end
