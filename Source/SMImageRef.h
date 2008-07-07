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
-(id)initWithDictionary:(NSDictionary *)aDict;
+(SMImageRef *)refWithId:(NSString *)imageId key:(NSString *)key;
+(SMImageRef *)refWithDictionary:(NSDictionary *)aDict;

-(NSString *)imageId;
-(NSString *)imageKey;

@end
