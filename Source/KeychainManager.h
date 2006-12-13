//
//  KeychainManager.h
//  SmugMugExport
//
//  Created by Aaron Evans on 11/14/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface KeychainManager : NSObject {

}

+(KeychainManager *)sharedKeychainManager;

-(NSArray *)keychainItemsForKind:(NSString *)itemKind;

-(BOOL)checkForExistanceOfKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username;

-(BOOL)deleteKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username;

-(BOOL)modifyKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username withNewPassword:(NSString *)newPassword;

-(BOOL)addKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username withPassword:(NSString *)password;

-(NSString *)passwordFromKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username;

-(NSString *)passwordFromSecKeychainItemRef:(SecKeychainItemRef)item;

@end
