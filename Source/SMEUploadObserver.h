//
//  SMEUploadObserver.h
//  SmugMugExport
//
//  Created by Aaron Evans on 9/3/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SMEMethodRequest, SMEImageRef, SMEResponse, SMEImage;

// protocol for monitoring an upload
@protocol SMEUploadObserver

-(void)uploadDidFail:(SMEResponse *)resp;

-(void)uploadMadeProgress:(SMEImage *)theImage bytesWritten:(long)bytesWritten ofTotalBytes:(long)totalBytes;

-(void)uploadDidComplete:(SMEResponse *)resp image:(SMEImage *)theImage;

@end
