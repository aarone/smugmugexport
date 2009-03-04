

#import "SMEDataAdditions.h"

#import "SMEAccountInfo.h"
#import "SMEAlbum.h"
#import "SMEAlbumRef.h"
#import "SMECategory.h"
#import "SMEConciseAlbum.h"
#import "SMEData.h"
#import "SMEDecoder.h"
#import "SMEImage.h"
#import "SMEImageRef.h"
#import "SMEImageURLs.h"
#import "SMEJSONDecoder.h"
#import "SMEMethodRequest.h"
#import "SMERequest.h"
#import "SMEResponse.h"
#import "SMESession.h"
#import "SMESmugMugCore.h"
#import "SMESubCategory.h"
#import "SMEUploadObserver.h"
#import "SMEUploadRequest.h"

#define THUMBNAIL_NOT_FOUND_ERROR_CODE 5
#define IMAGE_NOT_FOUND_ERROR_CODE 6
#define IMAGE_EDIT_SYSTEM_ERROR_CODE 5

#define SMUGMUG_VERSION_CHECK_ERROR 7

#define kCFBundleShortVersionStringKey @"CFBundleShortVersionString"

static inline BOOL IsEmpty(id thing) {
    return thing == nil
	|| ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
	|| ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}
