//
//  RESTCall.h
//  SmugMugExport
//
//  Created by Aaron Evans on 12/30/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RESTCall : NSObject {
	NSURLConnection *connection;
	NSMutableData *response;
	SEL callback;
	id target;
	NSXMLDocument *document;
	BOOL wasSuccessful;
	NSError *error;
}

#pragma mark inititalizers
-(id)init;
+(RESTCall *)RESTCall;

#pragma mark REST method invocation API
-(void)invokeMethod:(NSURL *)url responseCallback:(SEL)callback responseTarget:(id)target;
-(void)invokeMethodWithHost:(NSURL *)baseUrl keys:(NSArray *)keys values:(NSArray *)values responseCallback:(SEL)callback responseTarget:(id)target;
-(void)invokeMethodWithHost:(NSURL *)baseURL keys:(NSArray *)keys valueDict:(NSDictionary *)keyValDict responseCallback:(SEL)callback responseTarget:(id)target;

-(BOOL)wasSuccessful;
-(NSError *)error;
-(NSXMLDocument *)document;

//-(void)invokeMethodWithRelativePath:(NSString *)path responseCallback:(SEL)callback responseTarget:(id)target;
//-(void)invokeMethodWithKeys:(NSArray *)keys values:(NSArray *)values responseCallback:(SEL)callback responseTarget:(id)target;
//-(void)invokeMethodWithDictionary:(NSDictionary *)dictionary orderedKey:(NSArray *)orderedKeys responseCallback:(SEL)callback responseTarget:(id)target;


@end
