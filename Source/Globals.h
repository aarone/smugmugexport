
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

// max width for images if scaling is enabled
extern NSString *SMImageScaleWidth; 

// max height for images if scaling is enabled
extern NSString *SMImageScaleHeight; 

// show an alert before deleting an album
extern NSString *SMShowAlbumDeleteAlert;

// print smugmug requests to console ?
extern NSString *SMEnableNetworkTracing; 
// insert a delay between the time we modify the list of albums and when we 
// refresh the list of albusm from smugmug.  This is a workaround for a sm defect.
extern NSString *SMEnableAlbumFetchDelay; 

// jpeg quality factor v to use when scaling images v : 0 <= v <= 1 
extern NSString *SMJpegQualityFactor;

extern NSString *AlbumID;
extern NSString *CategoryID;
extern NSString *SubCategoryID;

extern const float DefaultJpegScalingFactor;


// new album property keys
extern NSString *IsPublicPref;
extern NSString *ShowFilenamesPref;
extern NSString *AllowCommentsPref;
extern NSString *AllowExternalLinkingPref;
extern NSString *DisplayEXIFInfoPref;
extern NSString *EnableEasySharePref;
extern NSString *AllowPurchasingPref;
extern NSString *AllowOriginalsToBeViewedPref;
extern NSString *AllowFriendsToEditPref;
extern NSString *AlbumTitlePref;
extern NSString *AlbumDescriptionPref;
extern NSString *AlbumKeywordsPref;
extern NSString *AlbumCategoryPref;


// conveinent macros
#define ShouldScaleImages() ([[[NSUserDefaults smugMugUserDefaults] objectForKey:SMSelectedScalingTag] intValue] != 0)
#define IsNetworkTracingEnabled() ([[[NSUserDefaults smugMugUserDefaults] objectForKey:SMEnableNetworkTracing] boolValue])
#define EnableAlbumFetchDelay() ([[[NSUserDefaults smugMugUserDefaults] objectForKey:SMEnableAlbumFetchDelay] boolValue])

static inline BOOL IsEmpty(id thing) {
    return thing == nil
	|| ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
	|| ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}