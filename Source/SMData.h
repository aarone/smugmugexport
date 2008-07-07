//
//  SMData.h
//  SmugMugExport
//
//  Created by Aaron Evans on 6/29/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SMData : NSObject {
	id sourceData;
}

-(id)initWithSourceData:(id)src;
+(SMData *)dataWithSourceData:(id)src;
-(id)sourceData;
@end
