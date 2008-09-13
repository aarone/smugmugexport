
// preference keys

// accounts are stored here
extern NSString *SMEAccountsDefaultsKey;

// the last selected account
extern NSString *SMESelectedAccountDefaultsKey;

// shall we store our passwords in the keychain?
extern NSString *SMStorePasswordInKeychain;

// shall we scale images?
extern NSString *SMSelectedScalingTag;

// use image keywords as smugmug tags?
extern NSString *SMUseKeywordsAsTags; 

// show an alert before deleting an album
extern NSString *SMShowAlbumDeleteAlert;

// print smugmug requests to console ?
extern NSString *SMEnableNetworkTracing; 
// insert a delay between the time we modify the list of albums and when we 
// refresh the list of albusm from smugmug.  This is a workaround for a sm defect.
extern NSString *SMEnableAlbumFetchDelay; 

// jpeg quality factor v to use when scaling images v : 0 <= v <= 1 
extern NSString *SMJpegQualityFactor;

extern NSString *SMUploadedFilename;
extern NSString *SMUploadedFilenameOptionFilename;
extern NSString *SMUploadedFilenameOptionTitle;


// conveinent macros
#define ShouldScaleImages() ([[[NSUserDefaults smugMugUserDefaults] objectForKey:SMSelectedScalingTag] intValue] != 0)
#define IsNetworkTracingEnabled() ([[[NSUserDefaults smugMugUserDefaults] objectForKey:SMEnableNetworkTracing] boolValue])
#define EnableAlbumFetchDelay() ([[[NSUserDefaults smugMugUserDefaults] objectForKey:SMEnableAlbumFetchDelay] boolValue])

#define kCFBundleShortVersionStringKey @"CFBundleShortVersionString"

#define THUMBNAIL_NOT_FOUND_ERROR_CODE 5
#define IMAGE_NOT_FOUND_ERROR_CODE 6
#define IMAGE_EDIT_SYSTEM_ERROR_CODE 5

#define SMUGMUG_VERSION_CHECK_ERROR 7

static inline BOOL IsEmpty(id thing) {
    return thing == nil
	|| ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
	|| ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}