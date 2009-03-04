//
//  SMEImageRef.h
//  SmugMugExport
//
//  Created by Aaron Evans on 3/9/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SMEImageRef : NSObject {
	NSString *imageId;
	NSString *imageKey;
}

-(id)initWithId:(NSString *)anId key:(NSString *)aKey;
-(id)initWithDictionary:(NSDictionary *)aDict;
+(SMEImageRef *)refWithId:(NSString *)imageId key:(NSString *)key;
+(SMEImageRef *)refWithDictionary:(NSDictionary *)aDict;

-(NSString *)imageId;
-(NSString *)imageKey;

@end
