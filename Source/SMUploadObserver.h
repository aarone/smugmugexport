//
//  SMUploadObserver.h
//  SmugMugExport
//
//  Created by Aaron Evans on 9/3/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SMRequest;

// protocol for monitoring an upload
@protocol SMUploadObserver

-(void)uploadMadeProgress:(SMRequest *)request bytesWritten:(long)numberOfBytes ofTotalBytes:(long)totalBytes;
-(void)uploadFailed:(SMRequest *)request withError:(NSString *)reason;
-(void)uploadCanceled:(SMRequest *)request;
-(void)uploadSucceeded:(SMRequest *)request;

@end
