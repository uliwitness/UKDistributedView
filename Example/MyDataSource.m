//
//  MyDataSource.m
//  UKDistributedView
//
//  Created by Uli Kusterer on Wed Jun 25 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//
//	This software is provided 'as-is', without any express or implied
//	warranty. In no event will the authors be held liable for any damages
//	arising from the use of this software.
//
//	Permission is granted to anyone to use this software for any purpose,
//	including commercial applications, and to alter it and redistribute it
//	freely, subject to the following restrictions:
//
//	   1. The origin of this software must not be misrepresented; you must not
//	   claim that you wrote the original software. If you use this software
//	   in a product, an acknowledgment in the product documentation would be
//	   appreciated but is not required.
//
//	   2. Altered source versions must be plainly marked as such, and must not be
//	   misrepresented as being the original software.
//
//	   3. This notice may not be removed or altered from any source
//	   distribution.
//

#import "UKDistributedView.h"
#import "UKFinderIconCell.h"
#import "MyDataSource.h"
#import "MyDistViewItem.h"


#define LAYER_BASED		0


@implementation MyDataSource

-(id)	init
{
    self = [super init];
    if( self )
	{
        itemList = [[NSMutableArray alloc] init];	// This example keeps its items in an array.
    }
    return self;
}


-(void)	dealloc
{
	[itemList release];
	[super dealloc];
}


// When we've finished building, set up our custom cell type and a few sample items to play with:
-(void)	awakeFromNib
{
	/* Set up a finder icon cell to use: */
	UKFinderIconCell*		bCell = [[[UKFinderIconCell alloc] autorelease] init];
	[bCell setImagePosition: NSImageAbove];
	[bCell setEditable: YES];
	[distView setPrototype: bCell];
	[distView setCellSize: NSMakeSize(100.0,80.0)];
	
	// Add a few items:
	//	These must be in alphabetic order for type-ahead-selection to work:
	int		x = 0;
	[distView setMultiPositioningMode: YES];	// Makes adding lots of items in a row faster, by cacheing the most recently added item's position.
	for( x = 0; x < 50; x++ )
	{
		[self addANewCell: nil];
	}
	[distView setMultiPositioningMode: NO];		// Turn it back off, so we don't use stale cached data for positioning.
	
	// Make items draggable and initially position them neatly:
	[distView positionAllItems:self];	// Instead of this you'd probably load the positions from wherever you get your items from.
	[distView setDragMovesItems:YES];	// Allow dragging around items in the view.
	[distView setDragLocally: YES];		// Try to drag locally until the mouse leaves the window.
	
	[distView registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
}


// Menu item action for adding new items at runtime to play with:
-(IBAction)	addANewCell: (id)sender
{
	static NSArray*	icons = nil;
	if( !icons )
	{
		icons = [[NSArray arrayWithObjects: [NSImage imageNamed: @"HelpStack.png"],
											[NSImage imageNamed: @"Juggler.png"],
											[NSImage imageNamed: @"BeanieCopter.png"],
											[NSImage imageNamed: @"ButtonIdeas.png"],
											[NSImage imageNamed: @"ChartMaker.png"],
											[NSImage imageNamed: @"FieldIdeas.png"],
											[NSImage imageNamed: @"Letter.png"],
											[NSImage imageNamed: @"LockedStack.png"],
											[NSImage imageNamed: @"Puzzle.png"],
											[NSImage imageNamed: @"Sort.png"],
											[NSImage imageNamed: @"PhoneDirectory.png"],
											[NSImage imageNamed: @"SearchStack.png"],
											nil] retain];
		srand( time(NULL) );
	}
	static NSArray*	names = nil;
	if( !names )
		names = [[NSArray arrayWithObjects: @"Susan Foreman",
											@"Barbara Wright",
											@"Ian Chesterton",
											@"Vicki",
											@"Steven Taylor",
											@"Katarina",
											@"Sara Kingdom",
											@"Dorothea Chaplet",
											@"Ben Jackson",
											@"Polly",
											@"James Robert McCrimmon",
											@"Dr. Elizabeth Shaw",
											@"Josephine Grant",
											@"Sarah Jane Smith",
											@"Harry Sullivan",
											@"Leela",
											@"K9 Mark I",
											@"K9 Mark II",
											@"Romanadvoratrelundar",
											@"Adric",
											@"Nyssa of Traken",
											@"Tegan Jovanka",
											@"Vislor Turlough",
											@"Kamelion",
											@"Perpugilliam Brown",
											@"Melanie Bush",
											@"Dorothy",
											@"Dr. Grace Holloway",
											@"Rose Tyler",
											@"Adam Mitchell",
											@"Captain Jack Harkness",
											@"Mickey Smith",
											@"Martha Jones",
											nil] retain];
	int	imageNum = rand() % [icons count],
		nameNum = rand() % [names count];
	
	MyDistViewItem*	item = [self addCellWithTitle: [names objectAtIndex: nameNum] andImage: [icons objectAtIndex: imageNum]];
	[item setPosition: [distView suggestedPosition]];
	
	// Now re-sort so type-ahead selection still works:
	[itemList sortUsingSelector: @selector(compare:)];
	[distView reloadData];	// Can't call numberOfItemsChanged here, as order may have changed as well.
}

-(MyDistViewItem*)	addCellWithTitle: (NSString*)title andImage: (NSImage*)img
{
	MyDistViewItem*		item = [[[MyDistViewItem alloc] autorelease] initWithTitle:title andImage:img];
	[itemList addObject: item];
	return item;
}

// -----------------------------------------------------------------------------
// DistributedView delegate methods:
-(int)	numberOfItemsInDistributedView: (UKDistributedView*)distributedView
{
	return [itemList count];	// Tell our list view how many items to expect:
}


#if LAYER_BASED
-(NSPoint)	distributedView: (UKDistributedView*)distributedView positionAtItemIndex: (int)row
{
	MyDistViewItem*		item = [itemList objectAtIndex: row];
	
	/* Tell list view where to display this item:
		You *must* keep track of your items' positions, and if you
		want to be able to move them, you must also implement setPosition:forItemIndex: */
	return [item position];
}


-(NSImage*)	distributedView: (UKDistributedView*)distributedView imageAtItemIndex: (int)row
{
	MyDistViewItem*		item = [itemList objectAtIndex: row];
	
	return [item image];
}


-(NSString*)	distributedView: (UKDistributedView*)distributedView titleAtItemIndex: (int)row
{
	MyDistViewItem*		item = [itemList objectAtIndex: row];
	
	return [item title];
}
#endif


-(NSPoint)	distributedView: (UKDistributedView*)distributedView positionForCell:(NSCell*)cell atItemIndex: (int)row
{
	MyDistViewItem*		item = [itemList objectAtIndex: row];
	
	// Display item data in cell:
	[cell setImage: [item image]];
	[cell setTitle: [item title]];
	
	/* Tell list view where to display this item:
		You *must* keep track of your items' positions, and if you
		want to be able to move them, you must also implement setPosition:forItemIndex: */
	return [item position];
}


// User has repositioned this item. Pick up the change:
-(void)	distributedView: (UKDistributedView*)distributedView setPosition: (NSPoint)pos forItemIndex: (int)row
{
	MyDistViewItem*		item = [itemList objectAtIndex: row];
	
	[item setPosition: pos];
}


// User changed item text through inline editing. Change store:
-(void)			distributedView: (UKDistributedView*)distributedView
						setObjectValue: (id)val
						forItemIndex: (int)row
{
	MyDistViewItem*		item = [itemList objectAtIndex: row];
	
	[item setTitle: val];
}


// User double-clicked an item. You don't have to implement this method, but we do, just for fun:
-(void) distributedView: (UKDistributedView*)distributedView cellDoubleClickedAtItemIndex: (int)item
{
	NSRunInformationalAlertPanel( @"Item double-clicked", @"You double-clicked on the item \"%@\".%@", @"OK", @"", @"",
									[[itemList objectAtIndex: item] title], ([distView selectedItemCount] > 1) ? @" There are additional items selected." : @"");
}

// -----------------------------------------------------------------------------
// Zooming:

-(NSRect)	windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame
{
	return [distView windowFrameForBestSize];	// Yes, it's that easy!
}


// -----------------------------------------------------------------------------
// Inter-application drag and drop:
#if DEMO_DRAG_AND_DROP
-(BOOL)				distributedView: (UKDistributedView*)dv writeItems:(NSArray*)indexes
						toPasteboard: (NSPasteboard*)pboard
{
	NSEnumerator*	enny = [indexes objectEnumerator];
	NSNumber*		currIndex = nil;
	NSMutableArray*	names = [NSMutableArray array];
	
	// Loop over dragged items and collect data for each:
	while( (currIndex = [enny nextObject]) )
	{
		NSString*	currName = [[itemList objectAtIndex: [currIndex intValue]] title];
		[names addObject: [@"/Users/" stringByAppendingString: currName]];	// Build pseudo file path as data so people can see the Finder actually accept our drags.
	}
	
	// Add data to pasteboard:
	[pboard addTypes: [NSArray arrayWithObject: NSFilenamesPboardType] owner: self];
	[pboard setPropertyList: names forType: NSFilenamesPboardType];
	
	return YES;
}

// Are we copying when dragging out of this view?
-(NSDragOperation)  distributedView: (UKDistributedView*)dv
						draggingSourceOperationMaskForLocal: (BOOL)isLocal
{
	if( isLocal )
		return NSDragOperationMove;
	else
		return NSDragOperationCopy;
}

// Specify where the dropped data should end up. On ("inside") an item, or just among them?
-(NSDragOperation)  distributedView: (UKDistributedView*)dv validateDrop: (id <NSDraggingInfo>)info
						proposedItem: (int*)row
{
	*row = -1;	// Just accept it in the general area of our view.
	
	return NSDragOperationCopy;
}

// Say whether you accept a drop of an item:
-(BOOL)				distributedView: (UKDistributedView*)dv acceptDrop:(id <NSDraggingInfo>)info
						onItem:(int)row
{
	return YES;
}

// Use this to handle drops on the trash etc:
-(void)				distributedView: (UKDistributedView*)dv dragEndedWithOperation: (NSDragOperation)operation
{
	if( operation == NSDragOperationDelete )	// Drag to trash!
	{
		// You could loop over the items here and delete all selected items from your array.
	}
}


-(void)	delete:(id)sender
{
	int		currIdx = [distView selectedItemIndex];
	while( currIdx >= 0 )
	{
		[itemList removeObjectAtIndex: currIdx];
		[distView noteNumberOfItemsChanged];
		currIdx = [distView selectedItemIndex];
	}
	[distView reloadData];
}

#endif

// -----------------------------------------------------------------------------

// Additional menu actions for testing dist view:

-(BOOL)	validateMenuItem: (NSMenuItem*)menuItem
{
	if( [menuItem action] == @selector(toggleAllowsMultipleSelection:) )
	{
		[menuItem setState: [distView allowsMultipleSelection]];
		return YES;
	}
	else if( [menuItem action] == @selector(toggleAllowsEmptySelection:) )
	{
		[menuItem setState: [distView allowsEmptySelection]];
		return YES;
	}
	else if( [menuItem action] == @selector(toggleUseSelectionRect:) )
	{
		[menuItem setState: [distView useSelectionRect]];
		return YES;
	}
	else if( [menuItem action] == @selector(toggleForceToGrid:) )
	{
		[menuItem setState: [distView forceToGrid]];
		return YES;
	}
	else if( [menuItem action] == @selector(toggleShowSnapGuides:) )
	{
		[menuItem setState: [distView showSnapGuides]];
		return YES;
	}
	else if( [menuItem action] == @selector(toggleDragMovesItems:) )
	{
		[menuItem setState: [distView dragMovesItems]];
		return YES;
	}
	else if( [menuItem action] == @selector(toggleDragLocally:) )
	{
		[menuItem setState: [distView dragLocally]];
		return YES;
	}
	else if( [menuItem action] == @selector(toggleDrawsBackground:) )
	{
		[menuItem setState: [distView drawsBackground]];
		return YES;
	}
	else
		return [self respondsToSelector: [menuItem action]];
}

-(IBAction)	toggleAllowsMultipleSelection: (id)sender
{
	[distView setAllowsMultipleSelection: ![distView allowsMultipleSelection]];
}

-(IBAction)	toggleAllowsEmptySelection: (id)sender
{
	[distView setAllowsEmptySelection: ![distView allowsEmptySelection]];
}

-(IBAction)	toggleUseSelectionRect: (id)sender
{
	[distView setUseSelectionRect: ![distView useSelectionRect]];
}

-(IBAction)	toggleForceToGrid: (id)sender
{
	[distView setForceToGrid: ![distView forceToGrid]];
}

-(IBAction)	toggleShowSnapGuides: (id)sender
{
	[distView setShowSnapGuides: ![distView showSnapGuides]];
}

-(IBAction)	toggleDragMovesItems: (id)sender
{
	[distView setDragMovesItems: ![distView dragMovesItems]];
}

-(IBAction)	toggleDragLocally: (id)sender
{
	[distView setDragLocally: ![distView dragLocally]];
}

-(IBAction)	toggleDrawsBackground: (id)sender
{
	[distView setDrawsBackground: ![distView drawsBackground]];
}


@end
