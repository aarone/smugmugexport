//
//  SmugMugManager.h
//  SmugMugExport
//
//  Created by Aaron Evans on 10/7/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol SmugMugManagerDelegate
-(void)loginDidComplete:(NSNumber *)wasSuccessful;
-(void)logoutDidComplete:(NSNumber *)wasSuccessful;
-(void)uploadDidCompleteWithArgs:(NSArray *)args;
-(void)uploadMadeProgressWithArgs:(NSArray *)args;
//-(void)uploadDidCompleteForFile:(NSString *)aFullPathToImage imageId:(NSString *)imageId  withError:(NSString *)error;
//-(void)uploadMadeProgressForFile:(NSString *)pathToFile bytesWritten:(long)bytesWritten totalBytes:(long)totalBytes;
-(void)categoryGetDidComplete:(NSNumber *)wasSuccessful;
-(void)createNewAlbumDidComplete:(NSNumber *)wasSuccessful;
-(void)deleteAlbumDidComplete:(NSNumber *)wasSuccessful;
-(void)imageUrlFetchDidComplete:(NSDictionary *)imageUrls;
@end

@interface SmugMugManager : NSObject {
	id delegate;

	NSArray *albums;
	NSString *username;
	NSString *password;
	NSString *sessionID;
	NSString *userID;
	NSString *passwordHash;
	CFReadStreamRef readStream;
	NSMutableData *responseData;
	NSArray *categories;
	NSArray *subcategories;
	NSMutableDictionary *newAlbumPreferences;
	NSDictionary *selectedCategory;

	NSString *currentPathForUpload;
	long uploadSize;
	BOOL isUploading;
	BOOL isLoggingIn;
	BOOL isLoggedIn;
	long nextProgressThreshold;
	NSIndexSet *selectedCategoryIndices;
}

+(SmugMugManager *)smugmugManager;

-(void)setDelegate:(id)delegate;
-(id)delegate;

-(void)login;
-(void)logout;

-(BOOL)isLoggingIn;
-(BOOL)isLoggedIn;

-(void)buildCategoryList; // must be logged in to call!
-(void)buildSubCategoryList;

-(NSString *)username;
-(void)setUsername:(NSString *)n;
-(NSString *)password;
-(void)setPassword:(NSString *)p;

-(void)uploadImageAtPath:(NSString *)path albumWithID:(NSString *)albumId caption:(NSString *)caption;
-(void)stopUpload;

-(void)fetchImageUrls:(NSString *)imageId;

-(void)createNewAlbum;
-(void)clearAlbumCreationState;
-(void)deleteAlbum:(NSString *)albumId;

-(NSArray *)albums;
-(NSArray *)categories;
-(NSArray *)subcategories;

@end
