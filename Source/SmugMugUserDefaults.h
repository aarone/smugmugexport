//
//  SMUserDefaults.h
//  SmugMugExport
//
//  Created by Aaron Evans on 6/10/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SMUserDefaults : NSObject {

}

+(SMUserDefaults *)smugMugDefaults;

-(void)registerDefaults:(NSDictionary *)dictionary;
-(void)setObject:(id)val forKey:(id)key;
-(id)objectForKey:(id)key;

@end
