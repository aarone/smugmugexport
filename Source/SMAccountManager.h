//
//  SMAccountManager.h
//  SmugMugExport
//
//  Created by Aaron Evans on 10/29/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SMEKeychainManager;

/**
 * Interface between exporter instance and the known user accounts.  Does not actually
 * communicate with SmugMug.
 */
@interface SMAccountManager : NSObject {

}

+(SMAccountManager *)accountManager;
-(void)addAccount:(NSString *)account withPassword:(NSString *)password;
-(NSArray *)accounts;
-(NSString *)selectedAccount;
-(void)setSelectedAccount:(NSString *)anAccount;
-(NSString *)passwordForAccount:(NSString *)account;
-(BOOL)passwordExistsInKeychainForAccount:(NSString *)account;
-(BOOL)canAttemptAutoLogin;
@end
