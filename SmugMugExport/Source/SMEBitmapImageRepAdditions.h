//
//  NSImageRepAdditions.h
//  SmugMugExport
//
//  Created by Aaron Evans on 8/25/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSBitmapImageRep (SMEBitmapImageRepAdditions)

+(float)defaultJpegScalingFactor;
-(NSData *)scaledRepToMaxWidth:(float)maxWidth maxHeight:(float)maxHeight scaleFactor:(float)scalingFactor;
-(NSData *)scaledRepToWidth:(float)widthFactor height:(float)heightFactor scaleFactor:(float)scalingFactor;

@end
