extern NSString *SMEAccountsDefaultsKey;
extern NSString *SMESelectedAccountDefaultsKey;
extern NSString *SMStorePasswordInKeychain;
extern NSString *SMSelectedScalingTag;
extern NSString *SMUseKeywordsAsTags;
extern NSString *SMImageScaleWidth;
extern NSString *SMImageScaleHeight;
extern NSString *SMShowAlbumDeleteAlert;
extern NSString *SMEnableNetworkTracing;
extern NSString *SMEnableAlbumFetchDelay;

extern NSString *AlbumID;
extern NSString *CategoryID;
extern NSString *SubCategoryID;

#define ShouldScaleImages() ([[[NSUserDefaults smugMugUserDefaults] objectForKey:SMSelectedScalingTag] intValue] != 0)
#define IsNetworkTracingEnabled() ([[[NSUserDefaults smugMugUserDefaults] objectForKey:SMEnableNetworkTracing] boolValue])
#define EnableAlbumFetchDelay() ([[[NSUserDefaults smugMugUserDefaults] objectForKey:SMEnableAlbumFetchDelay] boolValue])