//
//  SMEImage.m
//  SmugMugExport
//
//  Created by Aaron Evans on 9/12/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMEImage.h"

@implementation SMEImage

-(id)initWithTitle:(NSString *)aTitle 
		   caption:(NSString *)aCaption
		  keywords:(NSArray *)theKeywords
		 imageData:(NSData *)theData
	 thumbnailPath:(NSString *)pathToThumbnail {
	
	if( nil == (self = [super init]))
		return nil;
	
	[self setTitle:aTitle];
	[self setCaption:aCaption];
	[self setKeywords:theKeywords];
	[self setImageData:theData];
	[self setThumbnailPath:pathToThumbnail];
		
	return self;	
}

+(SMEImage *)imageWithTitle:(NSString *)aTitle
					caption:(NSString *)aCaption
				   keywords:(NSArray *)theKeywords
				  imageData:(NSData *)theData 
			  thumbnailPath:(NSString *)pathToThumbnail {
	return [[[[self class] alloc] initWithTitle:aTitle caption:aCaption keywords:theKeywords imageData:theData thumbnailPath:pathToThumbnail] autorelease];
}

-(void)dealloc {
	[self setTitle:nil];
	[self setCaption:nil];
	[self setKeywords:nil];
	[self setImageData:nil];
	[self setThumbnailPath:nil];
	
	[super dealloc];
}

-(NSString *)title {
	return title;
}

-(void)setTitle:(NSString *)aTitle {
	if(title != aTitle) {
		[title release];
		title = [aTitle retain];
	}
}

-(NSString *)caption {
	return caption;
}

-(void)setCaption:(NSString *)aCaption {
	if(aCaption != caption) {
		[caption release];
		caption = [aCaption retain];
	}
}

-(NSArray *)keywords {
	return keywords;
}

-(void)setKeywords:(NSArray *)theKeywords {
	if(theKeywords != keywords) {
		[keywords release];
		keywords = [theKeywords retain];
	}
}

-(NSData *)imageData {
	return imageData;
}

-(void)setImageData:(NSData *)theData {
	if(theData != imageData) {
		[imageData release];
		imageData = [theData retain];
	}
}

-(NSString *)thumbnailPath {
	return thumbnailPath;
}

-(void)setThumbnailPath:(NSString *)pathToThumbnail {
	if(thumbnailPath != pathToThumbnail) {
		[thumbnailPath release];
		thumbnailPath = [pathToThumbnail retain];
	}
}

-(NSData *)thumbnail {
	return [NSData dataWithContentsOfFile:thumbnailPath];
}

@end
