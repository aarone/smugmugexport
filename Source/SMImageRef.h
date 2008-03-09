//
//  SMImageRef.h
//  SmugMugExport
//
//  Created by Aaron Evans on 3/9/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SMImageRef : NSObject {
	NSString *imageId;
	NSString *imageKey;
}

-(id)initWithId:(NSString *)anId key:(NSString *)aKey;
+(SMImageRef *)refWithId:(NSString *)imageId key:(NSString *)key;

-(NSString *)imageId;
-(NSString *)imageKey;

@end
