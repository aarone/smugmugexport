//
//  SMEKeychainManager.m
//  SmugMugExport
//
//  Created by Aaron Evans on 11/14/06.
//  Copyright 2006 Aaron Evans. All rights reserved.
//


#import "SMEKeychainManager.h"
#import <Security/Security.h>
#import <CoreFoundation/CoreFoundation.h>

static SMEKeychainManager *sharedKeychainManager = nil;

@interface SMEKeychainManager (Private)
-(NSString *)passwordFromSecKeychainItemRef:(SecKeychainItemRef)item;
@end

@implementation SMEKeychainManager

+(SMEKeychainManager *)sharedKeychainManager {
  @synchronized(self) {
        if (sharedKeychainManager == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedKeychainManager;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedKeychainManager == nil) {
            sharedKeychainManager = [super allocWithZone:zone];
            return sharedKeychainManager;  // assignment and return on first allocation
        }
    }
    return nil;
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

-(NSArray *)keychainItemsForKind:(NSString *)itemKind {
  SecKeychainSearchRef search;
  SecKeychainItemRef item;
  SecKeychainAttributeList list;
  SecKeychainAttribute attributes[1];
    OSErr result;

  attributes[0].tag = kSecDescriptionItemAttr;
    attributes[0].data = (void *)[itemKind UTF8String];
    attributes[0].length = [itemKind length];
  
  list.count = 1;
  list.attr = attributes;
  
  // create our search for this keychain item kind
  result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
  if(result != noErr)
    return nil;

#define HACK_FOR_LABEL (7)
  SecItemAttr itemAttributes[] = {HACK_FOR_LABEL};

  SecExternalFormat externalFormats[] = {kSecFormatUnknown};
  
  SecKeychainAttributeList *attributeList = NULL;
  SecKeychainAttributeInfo info = {sizeof(itemAttributes) /
    sizeof(*itemAttributes), (void *)&itemAttributes,
    (void *)&externalFormats};

  NSMutableArray *foundItems = [NSMutableArray array];
  while (SecKeychainSearchCopyNext (search, &item) == noErr) {
    SecKeychainItemCopyAttributesAndData(item, &info, NULL, &attributeList, NULL, NULL);
    NSString *label = [[[NSString alloc] initWithBytes:(void *)attributeList->attr->data 
                           length:(unsigned)attributeList->attr->length 
                         encoding:NSUTF8StringEncoding] autorelease];
    
    [foundItems addObject:label];
    CFRelease (item);
    }

  return [NSArray arrayWithArray:foundItems];
}

-(BOOL)checkForExistanceOfKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username {
  SecKeychainSearchRef search;
  SecKeychainItemRef item;
  SecKeychainAttributeList list;
  SecKeychainAttribute attributes[3];
    OSErr result;
    int numberOfItemsFound = 0;
  
  attributes[0].tag = kSecAccountItemAttr;
    attributes[0].data = (void *)[username UTF8String];
    attributes[0].length = [username length];
    
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[1].data = (void *)[keychainItemKind UTF8String];
    attributes[1].length = [keychainItemKind length];
  
  attributes[2].tag = kSecLabelItemAttr;
    attributes[2].data = (void *)[keychainItemName UTF8String];
    attributes[2].length = [keychainItemName length];
  
    list.count = 3;
    list.attr = attributes;
  
    result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
  
    if (result != noErr)
    return NO;

  while (SecKeychainSearchCopyNext (search, &item) == noErr) {
        CFRelease (item);
        numberOfItemsFound++;
    }
  
    CFRelease (search);
  return numberOfItemsFound;
}

-(BOOL)deleteKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username {
  SecKeychainAttribute attributes[3];
    SecKeychainAttributeList list;
    SecKeychainItemRef item;
  SecKeychainSearchRef search;
    OSStatus status;
  OSErr result;
  int numberOfItemsFound = 0;
  
    attributes[0].tag = kSecAccountItemAttr;
    attributes[0].data = (void *)[username UTF8String];
    attributes[0].length = [username length];
    
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[1].data = (void *)[keychainItemKind UTF8String];
    attributes[1].length = [keychainItemKind length];
  
  attributes[2].tag = kSecLabelItemAttr;
    attributes[2].data = (void *)[keychainItemName UTF8String];
    attributes[2].length = [keychainItemName length];
  
    list.count = 3;
    list.attr = attributes;
  
  result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
  
  if(result != noErr)
    return NO;
  
  while (SecKeychainSearchCopyNext (search, &item) == noErr)
        numberOfItemsFound++;

  
  if (numberOfItemsFound)
    status = SecKeychainItemDelete(item);
  
  CFRelease (item);
  CFRelease(search);
  return !status;
}

-(BOOL)modifyKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username withNewPassword:(NSString *)newPassword {
  SecKeychainAttribute attributes[3];
    SecKeychainAttributeList list;
    SecKeychainItemRef item;
  SecKeychainSearchRef search;
    OSStatus status;
  OSErr result;
  
    attributes[0].tag = kSecAccountItemAttr;
    attributes[0].data = (void *)[username UTF8String];
    attributes[0].length = [username length];

    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[1].data = (void *)[keychainItemKind UTF8String];
    attributes[1].length = [keychainItemKind length];
  
  attributes[2].tag = kSecLabelItemAttr;
    attributes[2].data = (void *)[keychainItemName UTF8String];
    attributes[2].length = [keychainItemName length];
  
    list.count = 3;
    list.attr = attributes;
  
  result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
  if(result != noErr) {
    CFRelease(search);
    return NO;
  }
  
  SecKeychainSearchCopyNext (search, &item);
    status = SecKeychainItemModifyContent(item, &list, [newPassword length], [newPassword UTF8String]);
  
    if (status != noErr) {
    CFRelease (item);
    CFRelease(search);
        NSLog(@"Error modifying item: %d", (int)status);
    return NO;
  }
  
  CFRelease (item);
  CFRelease(search);
  return !status;
}

-(BOOL)addKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username withPassword:(NSString *)password {
  SecKeychainAttribute attributes[3];
    SecKeychainAttributeList list;
    SecKeychainItemRef item;
    OSStatus status;
  
    attributes[0].tag = kSecAccountItemAttr;
    attributes[0].data = (void *)[username UTF8String];
    attributes[0].length = [username length];

    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[1].data = (void *)[keychainItemKind UTF8String];
    attributes[1].length = [keychainItemKind length];
  
  attributes[2].tag = kSecLabelItemAttr;
    attributes[2].data = (void *)[keychainItemName UTF8String];
    attributes[2].length = [keychainItemName length];
  
    list.count = 3;
    list.attr = attributes;
  
    status = SecKeychainItemCreateFromContent(kSecGenericPasswordItemClass, &list, [password length], [password UTF8String], NULL,NULL,&item);
    if (status != 0) {
        NSLog(@"Error creating new item: %d\n", (int)status);
    }
  return !status;
  
}

-(NSString *)passwordFromKeychainItem:(NSString *)keychainItemName withItemKind:(NSString *)keychainItemKind forUsername:(NSString *)username {
  SecKeychainSearchRef search;
    SecKeychainItemRef item;
    SecKeychainAttributeList list;
    SecKeychainAttribute attributes[3];
    OSErr result;

  attributes[0].tag = kSecAccountItemAttr;
    attributes[0].data = (void *)[username UTF8String];
    attributes[0].length = [username length];
    
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[1].data = (void *)[keychainItemKind UTF8String];
    attributes[1].length = [keychainItemKind length];

  attributes[2].tag = kSecLabelItemAttr;
    attributes[2].data = (void *)[keychainItemName UTF8String];
    attributes[2].length = [keychainItemName length];
  
    list.count = 3;
    list.attr = attributes;
  
    result = SecKeychainSearchCreateFromAttributes(NULL, kSecGenericPasswordItemClass, &list, &search);
  
    if (result != noErr)
        NSLog (@"status %d from SecKeychainSearchCreateFromAttributes\n", result);
  
  NSString *password = nil;
    if (SecKeychainSearchCopyNext (search, &item) == noErr) {
    password = [self passwordFromSecKeychainItemRef:item];
    CFRelease(item);
    CFRelease (search);
  }
  return password;
}

-(NSString *)passwordFromSecKeychainItemRef:(SecKeychainItemRef)item {
  UInt32 length;
    char *password;
    SecKeychainAttribute attributes[8];
    SecKeychainAttributeList list;
    OSStatus status;
  
    attributes[0].tag = kSecAccountItemAttr;
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[2].tag = kSecLabelItemAttr;
    attributes[3].tag = kSecModDateItemAttr;
  
    list.count = 4;
    list.attr = attributes;
  
    status = SecKeychainItemCopyContent (item, NULL, &list, &length, 
                                         (void **)&password);
  
    // use this version if you don't really want the password,
    // but just want to peek at the attributes
    //status = SecKeychainItemCopyContent (item, NULL, &list, NULL, NULL);
    
    // make it clear that this is the beginning of a new
    // keychain item
    if (status == noErr) {
        if (password != NULL) {
      
            // copy the password into a buffer so we can attach a
            // trailing zero byte in order to be able to print
            // it out with printf
            char passwordBuffer[1024];
      
            if (length > 1023) {
                length = 1023; // save room for trailing \0
            }
            strncpy (passwordBuffer, password, length);
      
            passwordBuffer[length] = '\0';
      SecKeychainItemFreeContent (&list, password);
      return [NSString stringWithUTF8String:passwordBuffer];
        }
    }
  
  return nil;
}

@end
