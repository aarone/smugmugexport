//
//  SMESessionInfo.m
//  SmugMugExport
//
//  Created by Aaron Evans on 6/29/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMEAccountInfo.h"


@implementation SMEAccountInfo

-(NSDictionary *)userInfo {
	return [[self sourceData] objectForKey:@"User"];
}

-(NSString *)passwordHash {
	return [[self sourceData] objectForKey:@"PasswordHash"];
}

-(NSString *)accountType {
	return [[self sourceData] objectForKey:@"AccountType"];
}

-(unsigned int)filesizeLimit {
	return [[[self sourceData] objectForKey:@"FileSizeLimit"] intValue];
}

-(BOOL)hasVaultEnabled {
	return [[[self sourceData] objectForKey:@"SmugVault"] boolValue];
}

-(NSString *)sessionId {
	return [[[self sourceData] objectForKey:@"Session"] objectForKey: @"id"];
}

@end
