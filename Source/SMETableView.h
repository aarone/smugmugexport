//
//  SMTableView.h
//  SmugMugExport
//
//  Created by Aaron Evans on 10/6/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class SMEExportPlugin;

@interface SMETableView : NSTableView {
	IBOutlet SMEExportPlugin *exporter;
}

@end
