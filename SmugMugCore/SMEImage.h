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
	NSString *thumbnailPath;
	NSNumber *latitude;
	NSNumber *longitude;
	NSNumber *altitude;
}

-(id)initWithTitle:(NSString *)aTitle 
		   caption:(NSString *)aCaption
		  keywords:(NSArray *)theKeywords
		 imageData:(NSData *)theData
	 thumbnailPath:(NSString *)pathToThumbnail;

+(SMEImage *)imageWithTitle:(NSString *)aTitle
					caption:(NSString *)aCaption
				   keywords:(NSArray *)theKeywords
				  imageData:(NSData *)theData
			  thumbnailPath:(NSString *)pathToThumbnail;

-(NSString *)title;
-(void)setTitle:(NSString *)aTitle;

-(NSString *)caption;
-(void)setCaption:(NSString *)aCaption;

-(NSArray *)keywords;
-(void)setKeywords:(NSArray *)theKeywords;

-(NSData *)imageData;
-(void)setImageData:(NSData *)theData;

-(NSString *)thumbnailPath;
-(void)setThumbnailPath:(NSString *)pathToThumbnail;
-(NSData *)thumbnail;

-(NSNumber *)latitude;
-(void)setLatitude:(NSNumber *)v;

-(NSNumber *)longitude;
-(void)setLongitude:(NSNumber *)v;

-(NSNumber *)altitude;
-(void)setAltitude:(NSNumber *)v;

@end
