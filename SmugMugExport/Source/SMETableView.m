//
//  SMTableView.m
//  SmugMugExport
//
//  Created by Aaron Evans on 10/6/07.
//  Copyright 2007 Aaron Evans. All rights reserved.
//

#import "SMETableView.h"
#import "SMEExportPlugin.h"

@implementation SMETableView

/* make tableview 'Delete' button remove a selected album */
-(void)keyDown:(NSEvent *)theEvent {
	unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
	
	if ( ([[theEvent characters] isEqualToString:@"-"] || key == NSDeleteCharacter || key == NSBackspaceCharacter) && 
			[self numberOfRows] > 0 && [self selectedRow] != -1) {
		[exporter removeAlbum:self];
	} else if ([[theEvent characters] isEqualToString:@"+"] &&
			   [self numberOfRows] > 0 && [self selectedRow] != -1) {
		[exporter showNewAlbumSheet:self];
	} else {
		[super keyDown:theEvent];
	}
}

-(void)dealloc {
	[super dealloc];
}

@end
