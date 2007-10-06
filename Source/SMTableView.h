//
//  SMTableView.h
//  SMExportPlugin
//
//  Created by Aaron Evans on 10/6/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SMExportPlugin;

@interface SMTableView : NSTableView {
	IBOutlet SMExportPlugin *exporter;
}

@end
