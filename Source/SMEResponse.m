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
#import "SMERequest.h"

@interface SMEResponse (Private)
-(NSDictionary *)decodeResponse:(NSData *)data decoder:(NSObject<SMEDecoder> *)decoder;
-(void)setError:(NSError *)err;
-(NSError *)smugmugError;
@end

NSString *SMESmugMugErrorDomain = nil;

@implementation SMEResponse

/*
 Should just have a single NSError in public interface for smugmug errors
 */
-(id)initWithCompletedRequest:(NSObject<SMERequest> *)req decoder:(NSObject<SMEDecoder> *)aDecoder {
	if( ! (self = [super init]))
		return nil;
		
	@try {
		if([req wasSuccessful]) {
			decodedResponse = IsEmpty([req data]) ? nil : [[self decodeResponse:[req data] decoder:aDecoder] retain];
			[self setError:[self smugmugError]]; // may be nil which is ok
		} else {
			[self setError:[req error]]; // an underlying communication error
		}
	} @catch (NSException *ex) {
		NSLog(@"Error decoding response: %@", ex);
		decodedResponse = nil;
	}
	
	return self;
}

+(SMEResponse *)responseWithCompletedRequest:(NSObject<SMERequest> *)req decoder:(NSObject<SMEDecoder> *)aDecoder {
	return [[[[self class] alloc] initWithCompletedRequest:req decoder:aDecoder] autorelease];
}

+(void)initialize {
	SMESmugMugErrorDomain = @"SmugMug Error";
}

-(void)dealloc {
	[decodedResponse release];
	[smData release];
	[error release];
	
	[super dealloc];
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

-(NSError *)smugmugError {
	BOOL hasSmugMugError = ![[decodedResponse objectForKey:@"stat"] isEqualToString:@"ok"];
	if(!hasSmugMugError)
		return nil;
	
	return [NSError errorWithDomain:SMESmugMugErrorDomain
							   code:[self smErrorCode]
						   userInfo:[NSDictionary dictionaryWithObject:[self smErrorMessage]
																forKey:NSLocalizedDescriptionKey]];
}

-(NSDictionary *)decodeResponse:(NSData *)data decoder:(NSObject<SMEDecoder> *)decoder {	
	return [decoder decodedResponse:data];
}
	
-(BOOL)wasSuccessful {
	return error == nil;
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

-(NSError *)error {
	return error;
}

-(void)setError:(NSError *)err {
	if(err != error) {
		[error release];
		error = [err retain];
	}
}

@end
