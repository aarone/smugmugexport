//
//  SMEKeychainManager.h
//  SmugMugExport
//
//  Created by Aaron Evans on 11/14/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
    @class	 SMEKeychainManager
    @abstract   A Cocoa interface for the Keychain.
    @discussion  
 
 the code that was used to initially build this class was found here:
 http://homepage.mac.com/agerson/examples/keychain/
 
 and had the following header:
<blockquote>
 AGKeychain.m
 Based on code from "Core Mac OS X and Unix Programming"
 by Mark Dalrymple and Aaron Hillegass
 http://borkware.com/corebook/source-code

 Created by Adam Gerson on 3/6/05.
 agerson@mac.com
</blockquote>
 
 I made some changes to this class.
*/
@interface SMEKeychainManager : NSObject {

}

/*!
    @method     sharedKeychainManager
    @abstract   Returns the singleton manager.
*/
+(SMEKeychainManager *)sharedKeychainManager;

/*!
    @method     keychainItemsForKind:
    @abstract   Returns an array of keychain items for the specified kind string.
    @discussion Each item in the array is simply a string indicating the name of a keychain item.
*/
-(NSArray *)keychainItemsForKind:(NSString *)itemKind;

/*!
    @method     checkForExistanceOfKeychainItem:withItemKind:forUsername:
    @abstract   Returns YES if the keychain item exists or NO otherwise.
*/
-(BOOL)checkForExistanceOfKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username;

/*!
	@method     deleteKeychainItem:withItemKind:forUsername:
	@abstract   Attempts to delete the specified keychain item. Returns YES if the operation was successful, NO otherwise.
 */
-(BOOL)deleteKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username;

 /*!
	@method     modifyKeychainItem:withItemKind:forUsername:withNewPassword:
	@abstract   Attempts to modify the specified keychain item. Returns YES if the operation was successful, NO otherwise.
 */
-(BOOL)modifyKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username withNewPassword:(NSString *)newPassword;

 /*!
	@method     addKeychainItem:withItemKind:forUsername:withPassword:
	@abstract   Adds the specified item to the keychain.  Returns YES if the operation was successful, NO otherwise.
 */
-(BOOL)addKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username withPassword:(NSString *)password;

/*!
    @method     passwordFromKeychainItem:withItemKind:forUsername:
    @abstract   Returns the password for the specified item or nil if the item does not exist.
*/
-(NSString *)passwordFromKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username;

@end
