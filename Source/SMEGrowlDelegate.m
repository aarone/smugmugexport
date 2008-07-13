//
//  SMEGrowlDelegate.m
//  SmugMugExport
//
//  Created by Aaron Evans on 7/13/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import <Growl/Growl.h>
#import "SMEGrowlDelegate.h"
#import "SMEBitmapImageRepAdditions.h"

// Growl Notification Keys
NSString *SMGrowlUploadCompleted = nil;
NSString *SMGrowlUploadError = nil;
NSString *SMGrowlImageUploaded = nil;
NSString *SMGrowlLogin = nil;
NSString *SMGrowlLogout = nil;

@interface SMEGrowlDelegate (Private)
+(void)initializeLocalizableStrings;
@end

@implementation SMEGrowlDelegate

+(SMEGrowlDelegate *)growlDelegate {
	return [[[[self class] alloc] init] autorelease];
}

+(void)initialize {
	[self initializeLocalizableStrings];
}

+(void)initializeLocalizableStrings {	
	// Growl stuff
	SMGrowlUploadCompleted = NSLocalizedString(@"Upload Completed", @"Upload completed growl notification name");
	SMGrowlUploadError = NSLocalizedString(@"Upload Error", @"Upload error growl notification name");
	SMGrowlImageUploaded = NSLocalizedString(@"Image Uploaded", @"Image uploaded growl notification name");
	SMGrowlLogin = NSLocalizedString(@"Logged In", @"Logged in growl notification name");
	SMGrowlLogout = NSLocalizedString(@"Logged Out", @"Logged out growl notification name");
}

-(NSDictionary *)registrationDictionaryForGrowl {
	NSArray *allNotifications = [NSArray arrayWithObjects:
								 SMGrowlLogin,
								 SMGrowlLogout,
								 SMGrowlUploadCompleted,
								 SMGrowlUploadError,
								 SMGrowlImageUploaded,
								 nil];
	NSArray *defaultNotifications = [NSArray arrayWithObjects:
									 SMGrowlUploadCompleted,
									 SMGrowlUploadError,
									 nil];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			allNotifications, GROWL_NOTIFICATIONS_ALL,
			defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
			[NSNumber numberWithInt:1], GROWL_TICKET_VERSION,
			nil];
}

-(NSString *)applicationNameForGrowl {
	return [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleDisplayName"];
}

-(NSData *)applicationIconDataForGrowl {
	return nil;
}

-(void)growlIsReady {
}

-(void)growlNotificationWasClicked:(id)clickContext {
	if(clickContext != nil)
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:(NSString *)clickContext]];
}

-(void)growlNotificationTimedOut:(id)clickContext {
}

-(NSData *)notificationThumbnail:(NSData *)fullsizeImageData {
	NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithData:fullsizeImageData] autorelease];
	return [rep scaledRepToMaxWidth:120 maxHeight:120];	
}

-(void)notifyImageUploaded:(NSString *)imageFilename image:(NSData *)image{	
	[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"Image Uploaded", @"Growl notification title for image uploaded event")
								description:imageFilename
						   notificationName:SMGrowlImageUploaded
								   iconData:[self notificationThumbnail:image]
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

-(void)notifyLogin:(NSString *)account {
	[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"Logged In", @"Growl Notification title for logged in event")
								description:[NSString stringWithFormat:NSLocalizedString(@"User: %@", @"User logged in growl description"), account]
						   notificationName:SMGrowlLogin
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

-(void)notifyLougout:(NSString *)account {
	[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"Logged Out", @"Growl Message Title: (Logged Out)")
								description:[NSString stringWithFormat:NSLocalizedString(@"User: %@", @"User logged out growl description"), account]
						   notificationName:SMGrowlLogout
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

-(void)notifyUploadCompleted:(int)imagesUploaded uploadSiteUrl:(NSString *)siteUrl {
	[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"Upload Complete", @"Growl title for upload completed notification")
								description:[NSString stringWithFormat:NSLocalizedString(@"Uploaded %d images", @"Description for upload complete Growl message"), imagesUploaded]
						   notificationName:SMGrowlUploadCompleted
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:[siteUrl description]];
}

-(void)notifyUploadError:(NSString *)error {
	[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"Upload Error", @"Growl title for upload error notification")
								description:error
						   notificationName:SMGrowlUploadError
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:nil];			
}

@end
