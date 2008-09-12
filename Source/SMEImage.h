//
//  SMEImage.h
//  SmugMugExport
//
//  Created by Aaron Evans on 9/12/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SMEImage : NSObject {
	NSString *title;
	NSString *caption;
	NSArray *keywords;
	NSData *imageData;
	
	BOOL shouldConvertToJpeg;
	
	unsigned int maxDimension;
	BOOL shouldScale;
}

-(id)initWithTitle:(NSString *)aTitle 
		   caption:(NSString *)aCaption
		  keywords:(NSArray *)theKeywords
		 imageData:(NSData *)theData;

+(SMEImage *)imageWithTitle:(NSString *)aTitle
					caption:(NSString *)aCaption
				   keywords:(NSArray *)theKeywords
				  imageData:(NSData *)theData;

-(NSString *)title;
-(void)setTitle:(NSString *)aTitle;

-(NSString *)caption;
-(void)setCaption:(NSString *)aCaption;

-(NSArray *)keywords;
-(void)setKeywords:(NSArray *)theKeywords;

-(NSData *)imageData;
-(void)setImageData:(NSData *)theData;

@end
