//
//  SMEUserDefaults.m
//  SmugMugExport
//
//  Created by Aaron Evans on 6/10/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "SMEUserDefaults.h"

static SMEUserDefaults *sharedSMUserDefaults = nil;

@implementation SMEUserDefaults

+(SMEUserDefaults *)smugMugDefaults {
	@synchronized(self) {
		if(sharedSMUserDefaults == nil) {
			[[self alloc] init];
		}
	}
	return sharedSMUserDefaults;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedSMUserDefaults == nil) {
            sharedSMUserDefaults = [super allocWithZone:zone];
            return sharedSMUserDefaults;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return UINT_MAX;  //denotes an object that cannot be released
}

- (oneway void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}

-(CFStringRef)appId {
	return (CFStringRef)[[[NSBundle bundleForClass:[SMEUserDefaults class]] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey];
}

-(void)registerDefaults:(NSDictionary *)dictionary {
	NSEnumerator *enumerator = [[dictionary allKeys] objectEnumerator];
	id key;
	while(key = [enumerator nextObject]) {
		id val = [self valueForKey:key];
		if(val == nil)
			[self setValue:[dictionary objectForKey:key] forKey:key];

	}
}

-(void)setValue:(id)val forUndefinedKey:(id)key {
	CFPreferencesSetValue((CFStringRef)key,
						  (CFPropertyListRef)val,
						  [self appId],
						  kCFPreferencesCurrentUser,
						  kCFPreferencesAnyHost);
	CFPreferencesSynchronize([self appId],
							 kCFPreferencesCurrentUser,
							 kCFPreferencesAnyHost);
}

-(void)setObject:(id)val forKey:(id)key {
	[self setValue:val forKey:key];
}

-(id)objectForKey:(id)key {
	return [self valueForKey:key];
}

- (id)valueForUndefinedKey:(id)key {
	CFPropertyListRef val = CFPreferencesCopyValue((CFStringRef)key,
												   [self appId],
												   kCFPreferencesCurrentUser,
												   kCFPreferencesAnyHost);
	return [(id)val autorelease];
}

@end
