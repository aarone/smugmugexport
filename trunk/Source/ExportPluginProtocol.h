
@protocol ExportPluginProtocol
- (id)initWithExportImageObj:(id)fp8;
- (id)settingsView;
- (id)firstView;
- (id)lastView;
- (void)viewWillBeActivated;
- (void)viewWillBeDeactivated;
- (id)requiredFileType;
- (BOOL)wantsDestinationPrompt;
- (id)getDestinationPath;
- (id)defaultFileName;
- (id)defaultDirectory;
- (BOOL)treatSingleSelectionDifferently;
- (BOOL)validateUserCreatedPath:(id)fp8;
- (void)clickExport;
- (void)startExport:(id)fp8;
- (void)performExport:(id)fp8;
- (void *)progress;
- (void)lockProgress;
- (void)unlockProgress;
- (void)cancelExport;
- (id)name;
- (id)description;
@end