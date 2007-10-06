//
//  SmugMugManager.h
//  SMExportPlugin
//
//  Created by Aaron Evans on 10/7/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMUploadObserver.h"

@protocol SmugMugManagerDelegate
-(void)loginDidComplete:(NSNumber *)wasSuccessful;
-(void)logoutDidComplete:(NSNumber *)wasSuccessful;
-(void)uploadDidSucceeed:(NSData *)imageData imageId:(NSString *)smImageId;
-(void)uploadDidFail:(NSData *)imageData reason:(NSString *)errorText;
-(void)uploadMadeProgress:(NSData *)imageData bytesWritten:(long)bytesWritten ofTotalBytes:(long)totalBytes;
-(void)uploadWasCanceled;
-(void)categoryGetDidComplete:(NSNumber *)wasSuccessful;
-(void)createNewAlbumDidComplete:(NSNumber *)wasSuccessful;
-(void)deleteAlbumDidComplete:(NSNumber *)wasSuccessful;
-(void)imageUrlFetchDidComplete:(NSDictionary *)imageUrls;
@end

/*
 * High-level interface to smugmug.  Most methods are asynchronous and
 * require a delegate to implement the methods above.  The delegate
 * is guaranteed that responses are provided on the main thread.  This class
 * knows about the SmugMug API but is sheltered from the underlying API
 * implementation (provided by a SMRequest)
 */
@interface SmugMugManager : NSObject<SMUploadObserver> {
	id delegate;

	NSArray *albums;
	NSString *username;
	NSString *password;
	NSString *sessionID;
	NSString *userID;
	NSString *passwordHash;
	NSArray *categories;
	NSArray *subcategories;
	
	SMRequest *lastUploadRequest;
	NSString *currentPathForUpload;
	BOOL isUploading;
	BOOL isLoggingIn;
	BOOL isLoggedIn;
	long nextProgressThreshold;
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

-(void)uploadImageData:(NSData *)imageData
			  filename:(NSString *)filename
		   albumWithID:(NSString *)albumId 
				 title:(NSString *)title
			   caption:(NSString *)caption
			  keywords:(NSArray *)keywords;
-(void)stopUpload;

-(void)fetchImageUrls:(NSString *)imageId;

-(void)createNewAlbumWithCategory:(NSString *)categoryId 
					  subcategory:(NSString *)subCategoryId 
							title:(NSString *)title 
				  albumProperties:(NSDictionary *)newAlbumProperties;
-(void)deleteAlbum:(NSString *)albumId;
-(NSDictionary *)createNullSubcategory;

-(NSArray *)albums;
-(NSArray *)categories;
-(NSArray *)subcategories;
-(NSArray *)subCategoriesForCategory:(NSDictionary *)aCategory;

@end
