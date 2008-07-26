//
//  SMEUploadObserver.h
//  SmugMugExport
//
//  Created by Aaron Evans on 9/3/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SMEMethodRequest, SMEImageRef, SMEResponse;

// protocol for monitoring an upload
@protocol SMEUploadObserver

-(void)uploadDidFail:(SMEResponse *)resp;

-(void)uploadMadeProgress:(NSData *)imageData bytesWritten:(long)bytesWritten ofTotalBytes:(long)totalBytes;

-(void)uploadDidComplete:(SMEResponse *)resp filename:(NSString *)filename data:(NSData *)imageData;

@end
