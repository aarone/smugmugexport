//
//  SMSessionInfo.h
//  SmugMugExport
//
//  Created by Aaron Evans on 6/29/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SMData.h"

@interface SMSessionInfo : SMData {

}

-(NSDictionary *)userInfo;
-(NSString *)passwordHash;
-(NSString *)accountType;
-(unsigned int)filesizeLimit;
-(BOOL)smugVault;
-(NSString *)sessionId;
@end
