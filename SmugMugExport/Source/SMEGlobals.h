
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

// the last selected album template ID ("quick setting")
extern NSString *SMEAlbumTemplateID;

extern NSString *SMUploadedFilename;
extern NSString *SMUploadedFilenameOptionFilename;
extern NSString *SMUploadedFilenameOptionTitle;

extern NSString *SMEIncludeLocation;

