//
//  SMEImageURLs.h
//  SmugMugExport
//
//  Created by Aaron Evans on 7/7/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMEData.h"

@interface SMEImageURLs : SMEData {

}

-(unsigned int)identifier;
-(NSString *)albumURL;
-(NSString *)tinyURL;
-(NSString *)thumbURL;
-(NSString *)smallURL;
-(NSString *)mediumURL;
-(NSString *)largeURL;
-(NSString *)originalURL;

@end
