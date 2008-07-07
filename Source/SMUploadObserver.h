//
//  SMUploadObserver.h
//  SmugMugExport
//
//  Created by Aaron Evans on 9/3/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SMRequest, SMImageRef, SMResponse;

// protocol for monitoring an upload
@protocol SMUploadObserver

-(void)uploadDidFail:(SMResponse *)resp;

-(void)uploadMadeProgress:(NSData *)imageData bytesWritten:(long)bytesWritten ofTotalBytes:(long)totalBytes;

-(void)uploadDidSucceed:(SMResponse *)resp filename:(NSString *)filename data:(NSData *)imageData;

@end
