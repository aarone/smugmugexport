//
//  SMESession.m
//  SmugMugExport
//
//  Created by Aaron Evans on 10/7/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import "SMESession.h"
#import "SMEGlobals.h"
#import "SMEMethodRequest.h"
#import "SMEDecoder.h"
#import "SMEUserDefaultsAdditions.h"
#import "SMEJSONDecoder.h"
#import "SMEAlbum.h"
#import "SMEImageRef.h"
#import "SMEResponse.h"
#import "SMEAccountInfo.h"
#import "SMECategory.h"
#import "SMESubCategory.h"
#import "SMEImageURLs.h"
#import "SMEUploadRequest.h"

/*
 * Class wraps the repetitive process of invoking remote methods, asynchronously getting a callback
 * upon request completion, transforming the result, and returning the transformed response to a 
 * target on the main thread.
 * 
  send message invokeMethodAndHandleResponse:req to handler
   
  upon requestComplete for request r {
	on main thread, do:
		[target callback:[transformer transform:r]]
  }
 */
@interface ResponseHandler : NSObject {
	NSInvocation *inv;
	NSInvocation *transformInv;
}
+(ResponseHandler *)responseHandler:(id)target callback:(SEL)callback transformer:(id)transformer transformSel:(SEL)transformSel;
-(id)initWithResponseHandler:(id)target callback:(SEL)callback transformer:(id)transformer transformSel:(SEL)transformSel;
-(void)invokeMethodAndHandleResponse:(SMEMethodRequest *)req url:(NSURL *)aURL dict:(NSDictionary *)dict;
@end

@implementation ResponseHandler

+(ResponseHandler *)responseHandler:(id)target callback:(SEL)callback transformer:(id)transformer transformSel:(SEL)transformSel {
	return [[[[self class] alloc] initWithResponseHandler:target callback:callback transformer:transformer transformSel:transformSel] autorelease];
}

-(id)initWithResponseHandler:(id)target callback:(SEL)callback transformer:(id)aTransformer transformSel:(SEL)transformSel {
	if(! (self = [super init]))
		return nil;
	
	NSMethodSignature *sig = [[target class] instanceMethodSignatureForSelector:callback];
	if(nil == sig) {
		NSLog(@"Invalid callback for class: %@ selector: %@", NSStringFromClass([target class]), NSStringFromSelector(callback));
		return  nil;
	}
	
	inv = [[NSInvocation invocationWithMethodSignature:sig] retain];
	[inv setSelector:callback];
	[inv setTarget:target];	
	
	NSMethodSignature *transformSig = [[aTransformer class] instanceMethodSignatureForSelector:transformSel];
	if(nil == transformSig && transformSel != nil) {
		NSLog(@"Invalid transform callback for class: %@ selector: %@", NSStringFromClass([aTransformer class]), NSStringFromSelector(transformSel));
		return  nil;
	} else if(transformSig != nil) {
		transformInv = [[NSInvocation invocationWithMethodSignature:transformSig] retain];
		[transformInv setSelector:transformSel];
		[transformInv setTarget:aTransformer];
	}	
	
	return self;
}

-(void)dealloc {
	[inv release];
	[transformInv release];
	
	[super dealloc];
}

-(void)invokeMethodAndHandleResponse:(SMEMethodRequest *)req url:(NSURL *)aURL dict:(NSDictionary *)dict {
	[req invokeMethodWithURL:aURL
				 requestDict:dict
			responseCallback:@selector(transformResult:)
			  responseTarget:self];
}

-(void)transformResult:(SMEMethodRequest *)req {
	if([[inv methodSignature] numberOfArguments] == 3) {
		id arg = nil;
		if(transformInv != nil && [[transformInv methodSignature] numberOfArguments] == 3) {
			[transformInv setArgument:&req atIndex:2];
			[transformInv invoke];
			[transformInv getReturnValue:&arg];
		}
		
		[inv setArgument:&arg atIndex:2];
		[arg retain]; // not retained by retainArguments above
	}

	[inv performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
}

@end

@interface SMESession (Private)
-(NSString *)sessionID;
-(void)setSessionID:(NSString *)anID;

-(NSURL *)baseRequestUrl;

-(NSDictionary *)defaultNewAlbumPreferences;
-(void)newAlbumCreationDidComplete:(SMEMethodRequest *)req;
-(NSString *)smugMugNewAlbumKeyForPref:(NSString *)preferenceKey;
-(SMEMethodRequest *)createRequest;
-(SMEUploadRequest *)lastUploadRequest;
-(void)setLastUploadRequest:(SMEUploadRequest *)request;	
@end

static const NSTimeInterval AlbumRefreshDelay = 1.0;

@interface NSDictionary (SMAdditions)
-(NSComparisonResult)compareByAlbumId:(NSDictionary *)aDict;
@end

@implementation NSDictionary (SMAdditions)
-(NSComparisonResult)compareByAlbumId:(NSDictionary *)aDict {
	
	if([self objectForKey:@"id"] == nil)
		return NSOrderedAscending;
	
	if([aDict objectForKey:@"id"] == nil)
		return NSOrderedDescending;
		
	return [[aDict objectForKey:@"id"] intValue] - [[self objectForKey:@"id"] intValue];
}

-(NSComparisonResult)compareByTitle:(NSDictionary *)aDict {
	return [[self objectForKey:@"Title"] caseInsensitiveCompare:[aDict objectForKey:@"Title"]];
}
@end


@implementation SMESession

+(SMESession *)session {
	return [[[[self class] alloc] init] autorelease];
}

-(void)dealloc {
	[[self sessionID] release];
	[[self lastUploadRequest] release];
	
	[super dealloc];
}

-(NSObject<SMEDecoder> *)decoder {
	return [SMEJSONDecoder decoder];
}

-(SMEMethodRequest *)createRequest {
	return [SMEMethodRequest request];
}

#pragma mark Miscellaneous Get/Set Methods

-(NSURL *)baseRequestUrl {
	return [NSURL URLWithString:@"https://api.smugmug.com/hack/json/1.2.0/"];
}
	
-(NSString *)sessionID {
	return sessionID;
}

-(void)setSessionID:(NSString *)anID {
	if(sessionID != anID) {
		[sessionID release];
		sessionID = [anID retain];
	}
}

+(NSString *)UserAgent {
	return [[[NSString alloc] initWithFormat:@"iPhoto SMExportPlugin/%@", [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:(NSString *)kCFBundleShortVersionStringKey]] autorelease];
}

#pragma mark Login

-(void)invokeMethodAndTransform:(NSURL *)aUrl
					requestDict:(NSDictionary *)dict
					   callback:(SEL)callback
						 target:(id)target
					transformer:(id)transformer 
				   transformSel:(SEL)transformSel{
	ResponseHandler *handler = [ResponseHandler responseHandler:target callback:callback transformer:transformer transformSel:transformSel];
	[handler invokeMethodAndHandleResponse:[self createRequest]
									   url:[self baseRequestUrl]
									  dict:dict];
}

-(void)loginWithTarget:(id)target callback:(SEL)sel username:(NSString *)username password:(NSString *)password apiKey:(NSString *)apiKey {
	[self invokeMethodAndTransform:[self baseRequestUrl]
					   requestDict:[NSDictionary dictionaryWithObjectsAndKeys:
									 @"smugmug.login.withPassword", @"method",
									 username, @"EmailAddress",
									 password, @"Password",
									 apiKey, @"APIKey", nil]
						  callback:sel
							target:target
					   transformer:self
					  transformSel:@selector(transformLoginRequest:)];
}

-(SMEResponse *)transformLoginRequest:(SMEMethodRequest *)req {
	SMEResponse* resp = [SMEResponse responseWithCompletedRequest:req decoder:[self decoder]];
	SMEAccountInfo *info = (SMEAccountInfo *)[SMEAccountInfo dataWithSourceData:[[resp decodedResponse] objectForKey:@"Login"]];
	[resp setSMData:info];
	
	// the only state of a session
	[self setSessionID:[info sessionId]];	
	return resp;
}

#pragma mark Logout
-(void)logoutWithTarget:(id)target
			   callback:(SEL)callback {

	[self invokeMethodAndTransform:[self baseRequestUrl]
					   requestDict:[NSDictionary dictionaryWithObjectsAndKeys:
									@"smugmug.logout", @"method",
									[self sessionID], @"SessionID", nil]
						  callback:callback
							target:target
					   transformer:self
					  transformSel:@selector(transformLogoutRequest:)];	
	
}

-(SMEResponse *)transformLogoutRequest:(SMEMethodRequest *)req {
	SMEResponse *resp = [SMEResponse responseWithCompletedRequest:req decoder:[self decoder]];
	return resp;
}

-(void)validateSessionId {
	if([self sessionID] == nil)
		@throw [NSException exceptionWithName:NSLocalizedString(@"InvalidSessionException", @"Exception name for invalid session exception")
									   reason:NSLocalizedString(@"Session id is invalid", @"Error string when session id is invalid.")
									 userInfo:NULL];
}


#pragma mark Fetch Albums
-(void)fetchAlbumsWithTarget:(id)target
					callback:(SEL)callback {
	[self validateSessionId];

	if(EnableAlbumFetchDelay())
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:AlbumRefreshDelay]];
		
	[self invokeMethodAndTransform:[self baseRequestUrl]
					   requestDict:[NSDictionary dictionaryWithObjectsAndKeys:
									@"smugmug.albums.get", @"method",
									[self sessionID], @"SessionID", nil]
						  callback:callback
							target:target
					   transformer:self
					  transformSel:@selector(transformAlbumsRequest:)];	
}

-(SMEResponse *)transformAlbumsRequest:(SMEMethodRequest *)req {
	SMEResponse *resp = [SMEResponse responseWithCompletedRequest:req decoder:[self decoder]];

	NSMutableArray *result = [NSMutableArray array];
	NSEnumerator *albumEnum = [[[resp decodedResponse] objectForKey:@"Albums"] objectEnumerator];
	NSDictionary *albumDict = nil;
	while(albumDict = [albumEnum nextObject])
		[result addObject:[SMEConciseAlbum albumWithDictionary:[NSMutableDictionary dictionaryWithDictionary:albumDict]]];
	
	[resp setSMData:[NSArray arrayWithArray:result]];
	return resp;
}

#pragma mark Fetch Categories
-(void)fetchCategoriesWithTarget:(id)target callback:(SEL)callback {
	[self validateSessionId];
	[self invokeMethodAndTransform:[self baseRequestUrl]
					   requestDict:[NSDictionary dictionaryWithObjectsAndKeys:
									@"smugmug.categories.get", @"method",
									[self sessionID], @"SessionID", nil]
						  callback:callback
							target:target
					   transformer:self
					  transformSel:@selector(transformCategoriesRequest:)];
}

-(SMEResponse *)transformCategoryForCategoryKey:(NSString *)categoryKey categoryClass:(Class)categoryClass request:(SMEMethodRequest *)req{
	SMEResponse *resp = [SMEResponse responseWithCompletedRequest:req decoder:[self decoder]];
	
	if([[[resp error] domain] isEqualToString:SMESmugMugErrorDomain] &&
	   [[resp error] code] == NO_CATEGORIES_FOUND_CODE) {
		[resp setSMData:[NSArray array]];
		return resp;
	}
	
	NSMutableArray *returnedCategories = [NSMutableArray arrayWithArray:[[resp decodedResponse] objectForKey:categoryKey]];
	
	[returnedCategories sortUsingSelector:@selector(compareByTitle:)];
	NSEnumerator *e = [returnedCategories objectEnumerator];
	NSDictionary *dict = nil;
	NSMutableArray *result = [NSMutableArray array];
	while(dict = [e nextObject])
		[result addObject:[categoryClass dataWithSourceData:dict]];
	[resp setSMData:result];
	return resp;
}

-(SMEResponse *)transformSubCategoriesRequest:(SMEMethodRequest *)req {
	return [self transformCategoryForCategoryKey:@"SubCategories" categoryClass:[SMESubCategory class] request:req];
}

-(SMEResponse *)transformCategoriesRequest:(SMEMethodRequest *)req {
	return [self transformCategoryForCategoryKey:@"Categories" categoryClass:[SMECategory class] request:req];
}

#pragma mark Fetch SubCategories
-(void)fetchSubCategoriesWithTarget:(id)target callback:(SEL)callback {
	[self validateSessionId];
	[self invokeMethodAndTransform:[self baseRequestUrl]
					   requestDict:[NSDictionary dictionaryWithObjectsAndKeys:
									@"smugmug.subcategories.getAll", @"method",
									[self sessionID], @"SessionID", nil]
						  callback:callback
							target:target
					   transformer:self
					  transformSel:@selector(transformSubCategoriesRequest:)];
}

#pragma mark Delete Album
-(void)deleteAlbum:(SMEAlbumRef *)ref withTarget:(id)target callback:(SEL)callback {
	[self validateSessionId];
	[self invokeMethodAndTransform:[self baseRequestUrl]
					   requestDict:[NSDictionary dictionaryWithObjectsAndKeys:
									@"smugmug.albums.delete", @"method",
									[self sessionID], @"SessionID",
									[ref albumId], @"AlbumID", nil]
						  callback:callback
							target:target
					   transformer:self
					  transformSel:@selector(transformDeleteResponse:)];
}

-(SMEResponse *)transformDeleteResponse:(SMEMethodRequest *)req {
	SMEResponse *resp = [SMEResponse responseWithCompletedRequest:req decoder:[self decoder]];
	return resp;
}

#pragma mark Create Album
-(void)createNewAlbum:(SMEAlbum *)album withTarget:(id)target callback:(SEL)callback {
	[self validateSessionId];
	
	NSMutableDictionary *requestDict = [NSMutableDictionary dictionaryWithDictionary:[album toDictionary]];
	[requestDict setObject:@"smugmug.albums.create" forKey:@"method"];
	[requestDict setObject:[self sessionID] forKey:@"SessionID"];
	
	[self invokeMethodAndTransform:[self baseRequestUrl]
					   requestDict:requestDict
						  callback:callback
							target:target
					   transformer:self
					  transformSel:@selector(transformCreateNewAlbumResponse:)];
}

-(SMEResponse *)transformCreateNewAlbumResponse:(SMEMethodRequest *)req {
	SMEResponse *resp = [SMEResponse responseWithCompletedRequest:req decoder:[self decoder]];
	return resp;
}

#pragma mark Edit Album
-(void)editAlbum:(SMEAlbum *)album withTarget:(id)target callback:(SEL)callback {
	[self validateSessionId];
	
	NSMutableDictionary *reqArgs = [NSMutableDictionary dictionaryWithDictionary:[album toEditDictionary]];
	[reqArgs setObject:[self sessionID] forKey:@"SessionID"];
	[reqArgs setObject:@"smugmug.albums.changeSettings" forKey:@"method"];
	[self invokeMethodAndTransform:[self baseRequestUrl]
					   requestDict:reqArgs
						  callback:callback
							target:target
					   transformer:self
					  transformSel:@selector(transformEditAlbumResponse:)];
}

-(SMEResponse *)transformEditAlbumResponse:(SMEMethodRequest *)req {
	SMEResponse *resp = [SMEResponse responseWithCompletedRequest:req decoder:[self decoder]];
	return resp;
}

#pragma mark Full Album Fetch
-(void)fetchExtendedAlbumInfo:(SMEAlbumRef *)ref withTarget:(id)target callback:(SEL)callback {
	[self validateSessionId];
	
	NSMutableDictionary *args = [NSMutableDictionary dictionary];
	[args setObject:@"smugmug.albums.getInfo" forKey:@"method"];
	[args setObject:[self sessionID] forKey:@"SessionID"];
	[args setObject:[ref albumId] forKey:@"AlbumID"];
	[args setObject:[ref albumKey] forKey:@"AlbumKey"];
	[self invokeMethodAndTransform:[self baseRequestUrl]
					   requestDict:args
						  callback:callback
							target:target
					   transformer:self
					  transformSel:@selector(albumInfoFetchDidComplete:)];
}

-(SMEResponse *)albumInfoFetchDidComplete:(SMEMethodRequest *)req {
	SMEResponse *resp = [SMEResponse responseWithCompletedRequest:req decoder:[self decoder]];
	[resp setSMData:[SMEAlbum albumWithDictionary:[[resp decodedResponse] objectForKey:@"Album"]]];
	return resp;
}

-(void)fetchImageURLs:(SMEImageRef *)ref withTarget:(id)target callback:(SEL)callback {
	[self validateSessionId];
	
	NSMutableDictionary *args = [NSMutableDictionary dictionary];
	[args setObject:@"smugmug.images.getURLs" forKey:@"method"];
	[args setObject:[self sessionID] forKey:@"SessionID"];
	[args setObject:[ref imageId] forKey:@"ImageID"];
	[args setObject:[ref imageKey] forKey:@"ImageKey"];
	[self invokeMethodAndTransform:[self baseRequestUrl]
					   requestDict:args
						  callback:callback
							target:target
					   transformer:self
					  transformSel:@selector(imageFetchDidComplete:)];
}

#pragma mark Fetch Image
-(SMEResponse *)imageFetchDidComplete:(SMEMethodRequest *)req {
	SMEResponse *resp = [SMEResponse responseWithCompletedRequest:req decoder:[self decoder]];
	SMEImageURLs *urls = (SMEImageURLs *)[SMEImageURLs dataWithSourceData:[[resp decodedResponse] objectForKey:@"Image"]];
	[resp setSMData:urls];
	return resp;
}

#pragma mark Upload
-(void)uploadImage:(SMEImage *)theImage
		 intoAlbum:(SMEAlbumRef *)albumRef
		  observer:(NSObject<SMEUploadObserver> *)anObserver {
	
	SMEUploadRequest *uploadRequest = [SMEUploadRequest uploadRequest];
	[self setLastUploadRequest:uploadRequest];
	observer = anObserver; // delegate non-retaining semantics to avoid retain cycles
	[uploadRequest uploadImage:theImage withSession:self intoAlbum:albumRef observer:self];
}

-(NSObject<SMEUploadObserver>*)observer {
	return observer;
}

-(void)notifyDelegateOfProgress:(NSArray *)args {
	[[self observer] uploadMadeProgress:[args objectAtIndex:0]
						   bytesWritten:[[args objectAtIndex:1] longValue]
						   ofTotalBytes:[[args objectAtIndex:2] longValue]];
}

-(void)uploadMadeProgress:(SMEUploadRequest *)request bytesWritten:(long)numberOfBytes ofTotalBytes:(long)totalBytes {
	[self performSelectorOnMainThread:@selector(notifyDelegateOfProgress:) 
						   withObject:[NSArray arrayWithObjects:[request image] , [NSNumber numberWithLong:numberOfBytes], [NSNumber numberWithLong:totalBytes], nil]
						waitUntilDone:NO];
}

-(void)uploadCanceled:(SMEUploadRequest *)request {
	[[self observer] performSelectorOnMainThread:@selector(uploadWasCanceled)
									  withObject:nil
								   waitUntilDone:NO];	
}

-(void)uploadFailed:(SMEUploadRequest *)request withError:(NSString *)reason {
	SMEResponse *resp = [SMEResponse responseWithCompletedRequest:request decoder:[self decoder]];
	[[self observer] performSelectorOnMainThread:@selector(uploadDidFail:)
									  withObject:resp
								   waitUntilDone:NO];
}

-(void)notifyDelegateOfUploadSuccess:(SMEResponse *)resp {
	[[self observer] uploadDidComplete:resp
								 image:[[self lastUploadRequest] image]];
}

-(void)uploadComplete:(SMEUploadRequest *)request {
	SMEResponse *resp = [SMEResponse responseWithCompletedRequest:request decoder:[self decoder]];
	SMEImageRef *ref = [SMEImageRef refWithDictionary:[[resp decodedResponse] objectForKey:@"Image"]];
	[resp setSMData:ref];
	[self performSelectorOnMainThread:@selector(notifyDelegateOfUploadSuccess:)
						   withObject:resp
						waitUntilDone:NO];
}

-(void)stopUpload {
	[[self lastUploadRequest] cancelUpload];
}

-(SMEUploadRequest *)lastUploadRequest {
	return lastUploadRequest;
}

-(void)setLastUploadRequest:(SMEUploadRequest *)request {
	if(lastUploadRequest != request) {
		[lastUploadRequest release];
		lastUploadRequest = [request retain];
	}
}

@end


