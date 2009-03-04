//
//  SMEData.h
//  SmugMugExport
//
//  Created by Aaron Evans on 6/29/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SMEData : NSObject {
	id sourceData;
}

-(id)initWithSourceData:(id)src;
+(SMEData *)dataWithSourceData:(id)src;
-(id)sourceData;
@end
