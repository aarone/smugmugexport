extern NSString *SMEAccountsDefaultsKey;
extern NSString *SMESelectedAccountDefaultsKey;
extern NSString *SMStorePasswordInKeychain;
extern NSString *SMSelectedScalingTag;
extern NSString *SMUseKeywordsAsTags;
extern NSString *SMImageScaleWidth;
extern NSString *SMImageScaleHeight;

extern NSString *UserAgent;
extern NSString *AlbumID;
extern NSString *CategoryID;
extern NSString *SubCategoryID;

#define ShouldScaleImages() ([[[SmugMugUserDefaults smugMugDefaults] objectForKey:SMSelectedScalingTag] intValue] != 0)