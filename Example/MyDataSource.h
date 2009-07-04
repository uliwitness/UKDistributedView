//
//  MyDataSource.h
//  UKDistributedView
//
//  Created by Uli Kusterer on Wed Jun 25 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DEMO_DRAG_AND_DROP		1		// Set this to 1 to get inter-application drags, otherwise they'll be local.

@class	UKDistributedView;
@class	MyDistViewItem;

@interface MyDataSource : NSObject
{
	NSMutableArray*				itemList;		// List of cells in this view, plus their positions etc.
	IBOutlet UKDistributedView*	distView;		// The UKDistributedView we display our data in.
}

-(MyDistViewItem*)	addCellWithTitle: (NSString*)title andImage: (NSImage*)img;	// Utility method for adding a new cell.

// Some actions we implement to more easily test the dist view:
-(IBAction)	toggleAllowsMultipleSelection: (id)sender;
-(IBAction)	toggleAllowsEmptySelection: (id)sender;
-(IBAction)	toggleUseSelectionRect: (id)sender;
-(IBAction)	toggleForceToGrid: (id)sender;
-(IBAction)	toggleShowSnapGuides: (id)sender;
-(IBAction)	toggleDragMovesItems: (id)sender;
-(IBAction)	toggleDragLocally: (id)sender;
-(IBAction)	toggleDrawsBackground: (id)sender;

-(IBAction)	addANewCell: (id)sender;

@end
