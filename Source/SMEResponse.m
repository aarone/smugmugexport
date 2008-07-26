//
//  SMEResponse.m
//  SmugMugExport
//
//  Created by Aaron Evans on 6/28/08.
//  Copyright 2008 Aaron Evans. All rights reserved.
//

#import "SMEResponse.h"
#import "SMEDecoder.h"
#import "SMEGlobals.h"

@interface SMEResponse (Private)
-(NSDictionary *)decodeResponse:(NSData *)data decoder:(NSObject<SMEDecoder> *)decoder;
-(void)setConnectionError:(NSError *)err;
@end

@implementation SMEResponse

-(id)initWithCompletedRequest:(SMEMethodRequest *)req decoder:(NSObject<SMEDecoder> *)aDecoder {
	if( ! (self = [super init]))
		return nil;
		
	@try {
		if([req wasSuccessful]) {
			decodedResponse = IsEmpty([req data]) ? nil : [[self decodeResponse:[req data] decoder:aDecoder] retain];
		} else {
			[self setConnectionError:[req error]];
		}
		
	} @catch (NSException *ex) {
		NSLog(@"Error decoding response: %@", ex);
		decodedResponse = nil;
	}
	
	return self;
}

+(SMEResponse *)responseWithCompletedRequest:(SMEMethodRequest *)req decoder:(NSObject<SMEDecoder> *)aDecoder {
	return [[[[self class] alloc] initWithCompletedRequest:req decoder:aDecoder] autorelease];
}

-(void)dealloc {
	[decodedResponse release];
	[connectionError release];
	[smData release];
	
	[super dealloc];
}

-(NSString *)errorMessage {
	return connectionError != nil ? [connectionError localizedDescription] : [self smErrorMessage];
}

-(NSDictionary *)decodedResponse {
	return decodedResponse;
}

-(unsigned int)smErrorCode {
	return [[decodedResponse objectForKey:@"code"] intValue];
}

-(NSString *)smErrorMessage {
	return decodedResponse == nil ? 
		NSLocalizedString(@"No data in response", @"Error message when no response is received.") : 
		[decodedResponse objectForKey:@"message"];
}

-(NSDictionary *)decodeResponse:(NSData *)data decoder:(NSObject<SMEDecoder> *)decoder {	
	return [decoder decodedResponse:data];
}

-(BOOL)wasSuccessful {
	return connectionError != nil &&
		[[decodedResponse objectForKey:@"stat"] isEqualToString:@"ok"];
}

-(id)smData {
	return smData;
}

-(void)setSMData:(id)data {
	if(data != smData) {
		[smData release];
		smData = [data retain];
	}
}

-(NSError *)connectionError {
	return connectionError;
}

-(void)setConnectionError:(NSError *)err {
	if(err != connectionError) {
		[connectionError release];
		connectionError = [err retain];
	}
}

@end
