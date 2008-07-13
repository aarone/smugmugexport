//
//  SMEGrowlDelegate.h
//  SmugMugExport
//
//  Created by Aaron Evans on 7/13/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SMEGrowlDelegate : NSObject<GrowlApplicationBridgeDelegate> {

}

+(SMEGrowlDelegate *)growlDelegate;

-(void)notifyImageUploaded:(NSString *)imageFilename image:(NSData *)image;
-(void)notifyLogin:(NSString *)account;
-(void)notifyLougout:(NSString *)account;
-(void)notifyUploadCompleted:(int)imagesUploaded uploadSiteUrl:(NSString *)siteUrl;
-(void)notifyUploadError:(NSString *)error;
@end
