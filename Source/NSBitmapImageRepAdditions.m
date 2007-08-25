//
//  NSBitmapImageRepAdditions.m
//  SmugMugExport
//
//  Created by Aaron Evans on 8/25/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "NSBitmapImageRepAdditions.h"


@implementation NSBitmapImageRep (NSBitmapImageRepAdditions)

-(NSData *)scaledRepToMaxWidth:(float)maxWidth maxHeight:(float)maxHeight {
	
	int inputImageWidth = [self pixelsWide];
	int inputImageHeight = [self pixelsHigh];
		
	float scaleFactor = 1.0;
	if( inputImageWidth > maxWidth || inputImageHeight > maxHeight ) {
		int heightDifferential = inputImageWidth - maxWidth;
		int widthDifferential = inputImageHeight - maxHeight;
		// scale the dimension with the greatest difference
		scaleFactor = (heightDifferential > widthDifferential) ? 
			(float)maxHeight/(float)inputImageHeight : 
			(float)maxWidth/(float)inputImageWidth;
	}
	
	NSAssert(scaleFactor > 0.0 && scaleFactor <= 1.0, @"This is a bug.  The scaling factor should never be negative.");
	return [self scaledRepToWidth:scaleFactor height:scaleFactor];	
}

-(NSData *)scaledRepToWidth:(float)widthFactor height:(float)heightFactor {
	
	// we copy the properties that relate to jpegs
	NSSet *propertiesToTransfer = [NSSet setWithObjects:NSImageEXIFData, NSImageColorSyncProfileData, 
		NSImageProgressive, nil];
	NSMutableDictionary *outgoingImageProperties = [NSMutableDictionary dictionary];
	[outgoingImageProperties setObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
	NSEnumerator *propertyEnumerator = [propertiesToTransfer objectEnumerator];
	id key;
	while(key = [propertyEnumerator nextObject]) {
		id inVal = [self valueForProperty:key];
		if(inVal != nil)
			[outgoingImageProperties setObject:inVal forKey:key];
	}
	
	// do the scale here
	int outputWidth = [self pixelsWide]*widthFactor;
	int outputHeight = [self pixelsHigh]*heightFactor;
	
	NSImage *outputImage = [[NSImage alloc] initWithSize:NSMakeSize(outputWidth, outputHeight)];
	[outputImage lockFocus];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[self drawInRect:NSMakeRect(0,0,outputWidth, outputHeight)];
	NSBitmapImageRep *scaledRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0,0,outputWidth,outputHeight)];
	[outputImage unlockFocus];
	
	NSData *photoData = [scaledRep representationUsingType:NSJPEGFileType properties:outgoingImageProperties];
	[scaledRep release];
	[outputImage release];
	return photoData;	
}

@end
