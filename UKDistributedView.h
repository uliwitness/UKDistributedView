//
//  UKDistributedView.h
//  UKDistributedView
//
//  Created by Uli Kusterer on 2003-06-24.
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

/*
	An NSTableView-like class that allows arbitrary positioning
	of evenly-sized items. This is intended for things like the
	Finder's "icon view", and even lets you snap items to a grid
	in various ways, reorder them etc.
	
	Your data source must be able to provide a position for its
	list items, which are simply enumerated. An NSCell subclass
	can be used for actually displaying the data, e.g. as an
	NSImage or similar.
*/

/* -----------------------------------------------------------------------------
	Headers:
   -------------------------------------------------------------------------- */

#import <Cocoa/Cocoa.h>


/* -----------------------------------------------------------------------------
	Constants:
   -------------------------------------------------------------------------- */

/* Set this to zero to cause "snap guides" to be drawn as simple blue boxes
	with a semi-transparent white fill. If this is on (the default) you'll
	get a transparent version of the cell drawn in the location it will snap
	to. */

#ifndef UKDISTVIEW_DRAW_FANCY_SNAP_GUIDES
#define UKDISTVIEW_DRAW_FANCY_SNAP_GUIDES		1
#endif

/* Set this to 0 to cause deprecated methods to be excluded. This is useful
	for spotting where your app still makes calls to them. */

#ifndef UKDISTVIEW_BACKWARDS_COMPATIBLE
#define UKDISTVIEW_BACKWARDS_COMPATIBLE			1
#endif

/* The following is used to determine how many items to cache around the ones
	actually visible. More means speedier scrolling, less means better drawing
	and mouse tracking performance. Note that this doesn't really find that
	number of items on each side, but rather just extends the rect in which
	items must lie to be cached so it can hold that many items. */
#ifndef UKDISTVIEW_INVIS_ITEMS_CACHE_COUNT
#define UKDISTVIEW_INVIS_ITEMS_CACHE_COUNT		0
#endif


/* Amount of seconds within which another key must be pressed to still be added
    to the current "word" for type-ahead-selection. If you wait longer than
    this, the search string will be cleared and it will look for an item
    beginning with the typed character. */
#ifndef UKDV_TYPEAHEAD_INTERVAL
#define UKDV_TYPEAHEAD_INTERVAL                 0.8
#endif


/* This is the pasteboard type that is used during a real "drag and drop"
	drag to add the positions of the dragged items to the drag. Note that
	these positions are relative to the location of the dragged image, i.e.
	if you drag 5 items, the one in the lower left will probably be at 0,0.
	The coordinates are stored as an array of NSData objects containing an
	NSPoint, and are in Quartz coordinates, i.e. the y axis increases upwards. */
#define UKDistributedViewPositionsPboardType	@"UKDistributedViewPositionsPboardType"


/* -----------------------------------------------------------------------------
	Data Types:
   -------------------------------------------------------------------------- */

/* UKDVPersistentFlags:
	These flags are used to keep how you set up the view. They control general
	behaviour and are saved to NSArchivers and restored from there (think NIB). */
typedef union  UKDVPersistentFlags
{
    struct {
      #ifdef __BIG_ENDIAN__
        unsigned int        forceToGrid:1;				// Force all cells' positions to the grid. This behaves like "keep arranged by name" in Finder, and doesn't change actual cell positions.
        unsigned int        snapToGrid:1;               // Force moved and new cells' positions to the grid. This behaves like "snap to grid" in MacOS 9's Finder and actually changes cell positions, but doesn't move existing cells.
        unsigned int        dragMovesItems:1;           // Dragging an item changes its position.
        unsigned int        dragLocally:1;              // Try to drag locally even when the data source supports inter-application drag & drop, and only start DnD drag when the mouse leaves the view.
        unsigned int        allowsMultipleSelection:1;	// Can select more than one item?
        unsigned int        allowsEmptySelection:1;		// Can select less than one item?
        unsigned int        useSelectionRect:1;			// May user drag in empty areas to get a "rubber band"-style selection rect?
        unsigned int        sizeToFit:1;                // Should this view always resize to enclose its items?
        unsigned int        showSnapGuides:1;           // Show position indicator boxes during drag with grid?
        unsigned int        drawsGrid:1;                // Draw lines where the grid is?
        unsigned int        drawsBackground:1;          // Fill the background with white? (calls -drawBackgroundInRect:)
        unsigned int        reservedFlags:21;           // unused.
      #else
        unsigned int        reservedFlags:21;           // unused.
        unsigned int        drawsBackground:1;          // Fill the background with white? (calls -drawBackgroundInRect:)
        unsigned int        drawsGrid:1;                // Draw lines where the grid is?
        unsigned int        showSnapGuides:1;           // Show position indicator boxes during drag with grid?
        unsigned int        sizeToFit:1;                // Should this view always resize to enclose its items?
        unsigned int        useSelectionRect:1;			// May user drag in empty areas to get a "rubber band"-style selection rect?
        unsigned int        allowsEmptySelection:1;		// Can select less than one item?
        unsigned int        allowsMultipleSelection:1;	// Can select more than one item?
        unsigned int        dragLocally:1;              // Try to drag locally even when the data source supports inter-application drag & drop, and only start DnD drag when the mouse leaves the view.
        unsigned int        dragMovesItems:1;           // Dragging an item changes its position.
        unsigned int        snapToGrid:1;               // Force moved and new cells' positions to the grid. This behaves like "snap to grid" in MacOS 9's Finder and actually changes cell positions, but doesn't move existing cells.
        unsigned int        forceToGrid:1;				// Force all cells' positions to the grid. This behaves like "keep arranged by name" in Finder, and doesn't change actual cell positions.
      #endif
    } bits;
    int                 allFlags;
} UKDVPersistentFlags;


/* UKDVRuntimeFlags
	These are flags that aren't persistent and are simply for state while the
	view is being used. Flags specified here won't be saved to an NSArchiver. */
typedef union  UKDVRuntimeFlags
{
    struct {
      #ifdef __BIG_ENDIAN__
        unsigned int        drawSnappedRects:1;         // Draw "snap position" indicator behind selected items right now?
        unsigned int        drawDropHilite:1;           // Draw highlight indicating we accept a drop around the edges of the view?
        unsigned int        multiPositioningMode:1;		// YES when we're in multi-position mode, which causes a speed-up when positioning new items by doing some caching.
        unsigned int        reservedFlag:29;            // unused.
      #else
        unsigned int        reservedFlag:29;            // unused.
        unsigned int        multiPositioningMode:1;		// YES when we're in multi-position mode, which causes a speed-up when positioning new items by doing some caching.
        unsigned int        drawDropHilite:1;           // Draw highlight indicating we accept a drop around the edges of the view?
        unsigned int        drawSnappedRects:1;         // Draw "snap position" indicator behind selected items right now?
      #endif
    } bits;
    int                 allFlags;
} UKDVRuntimeFlags;

/* -----------------------------------------------------------------------------
	UKDistributedView:
   -------------------------------------------------------------------------- */

@interface UKDistributedView : NSView
{
// You *should* be using the accessors below:
	IBOutlet id			dataSource;					// The data source thet provides our items.
	IBOutlet id			delegate;					// The delegate that receives messages from us.
	NSSize				cellSize;					// Size of cells and grid when ordering items by grid.
	NSSize				gridSize;					// Size of grid to align items on. Usually, this is half our cell size.
	float				contentInset;				// How many pixels of border to leave around the items.
	IBOutlet NSCell*	prototype;					// The prototype cell used for our items.
	NSMutableSet*		selectionSet;				// The selection. *not persistent*
	UKDVPersistentFlags flags;                      // Persistent flags and boolean properties.
    NSColor*			gridColor;					// Color to use for grid lines.

// private: *do not use*
	NSUInteger			mouseItem;					// Item currently being tracked on a click.
	NSPoint				lastPos;					// Last mouse position during mouse tracking.
	NSRect				selectionRect;				// Selection rect while we're tracking it.
	UKDVRuntimeFlags    runtimeFlags;               // Flags used to temporarily change behavior at runtime.
	NSPoint				lastSuggestedItemPos;		// Cached item position for multiPositionMode to more quickly allow positioning new items.
	NSMutableArray*		itemsBelowLastSuggested;	// Cached indexes of the items that are below the lastSuggestedItemPos. These are the only ones we have to collision-detect.
	NSRect				visibleItemRect;			// Rect in which we last cached the indexes of visible items.
	NSMutableArray*		visibleItems;				// Cached indexes of the items that are visible in the visibleItemRect.
	NSUInteger			dragDestItem;				// Item being highlighted during drop.
	NSPoint				dragStartImagePos;			// Position dragged image started out in.
	NSUInteger			editedItem;					// Item being edited using inline-editing. NSNotFound if we're not editing.
	NSMutableString*    typeAheadSearchStr;         // String used for type-selection.
    NSTimeInterval      lastTypeAheadKeypress;      // Last time user typed ahead, so we know when to clear typeAheadSearchStr.
    NSUInteger			oldItemCount;               // Used to find out how many items to add/remove on numberOfItemsChanged.
}

// Data source & delegate:
-(id)				dataSource;
-(void)				setDataSource: (id)d;

-(id)				delegate;
-(void)				setDelegate: (id)d;

// Selection:
-(void)				setAllowsMultipleSelection: (BOOL)state;
-(BOOL)				allowsMultipleSelection;

-(void)				setAllowsEmptySelection: (BOOL)state;
-(BOOL)				allowsEmptySelection;

-(void)				setUseSelectionRect: (BOOL)state;		// Set to YES to get a "rubber-band" selection rectangle when empty areas are clicked.
-(BOOL)				useSelectionRect;

-(NSUInteger)		selectedItemCount;
-(NSEnumerator*)	selectedItemEnumerator;
-(NSUInteger)		selectedItemIndex;						// Use above calls if possible, your users will be grateful.
#if UKDISTVIEW_BACKWARDS_COMPATIBLE
-(NSUInteger)		selectedItem;							// Deprecated name. Use selectedItemIndex instead.
#endif /*UKDISTVIEW_BACKWARDS_COMPATIBLE*/

-(void)				selectItem: (NSUInteger)index byExtendingSelection: (BOOL)ext;
-(void)				selectItemsInRect: (NSRect)aBox byExtendingSelection: (BOOL)ext;
-(void)             selectItemContainingString: (NSString*)str;
-(IBAction)			selectAll: (id)sender;
-(IBAction)			deselectAll: (id)sender;

// UKDistView-specific actions:
-(IBAction)			toggleDrawsGrid: (id)sender;
-(IBAction)			toggleSnapToGrid: (id)sender;

// Options for behavior:
-(void)		setForceToGrid: (BOOL)state;	// Nudges all items into the grid when displaying/hit testing.
-(BOOL)		forceToGrid;

-(void)		setSnapToGrid: (BOOL)state;		// Snaps items moved by the user and newly created ones to the grid, but keeps existing items at their positions.
-(BOOL)		snapToGrid;

-(void)		setShowSnapGuides: (BOOL)state;	// Shows little boxes when dragging an item with grid on, so the user knows where the item will actually end up.
-(BOOL)		showSnapGuides;

-(void)		setDragMovesItems: (BOOL)state;	// Clicking an item allows the user to drag it around.
-(BOOL)		dragMovesItems;

-(void)		setDragLocally: (BOOL)state;	// Use view-internal drags until mouse leaves this view, and only then try to DnD.
-(BOOL)		dragLocally;

// Options for drawing:
-(void)		setDrawsGrid: (BOOL)state;
-(BOOL)		drawsGrid;

-(void)		setGridColor: (NSColor*)c;
-(NSColor*)	gridColor;

-(void)		setDrawsBackground: (BOOL)drawIt;
-(BOOL)		drawsBackground;

// The cell used for displaying items:
-(id)		prototype;
-(void)		setPrototype: (NSCell*)aCell;

// Data management:
-(void)		noteNumberOfItemsChanged;
-(void)		reloadData;

// Sizing, margins etc.:
-(void)		setContentInset: (float)inset;	// Set margin around content area. This border isn't really enforced, but is used by the positioning and rescrolling methods.
-(float)	contentInset;

-(void)		setCellSize: (NSSize)size;	// Cell size. All items must be the same size. Also changes gridSize to cellSize /2.
-(NSSize)	cellSize;

-(void)		setGridSize: (NSSize)size;
-(NSSize)	gridSize;

-(void)		setSizeToFit: (BOOL)state;	// Always make this object resize so it encloses all its items or fills the visible area of the containing scroll view.
-(BOOL) 	sizeToFit;

/* Determining/changing positions of items in this view:
	Note that those of these for changing a position change the actual item positions, *permanently*. */
-(NSPoint)	suggestedPosition;						// Get best position for a new item.
-(NSPoint)  itemPositionBasedOnItemIndex: (NSUInteger)row; // Calculate a position based on its item number and the view's width. Use this to calculate item positions if you're implementing "keep arranged by..."-style views.

-(void)		positionItem: (NSUInteger)itemIndex;	// Move an item from its current to the next best position (as in, unoccupied and on-grid).
-(void)		setMultiPositioningMode: (BOOL)state;   // Set this to YES to speed up groups of positionItem: calls
-(BOOL)		multiPositioningMode;

-(IBAction)	positionAllItems: (id)sender;			// Places all items on grid positions, starting at the top left in horizontal lines. They are put in their natural order, i.e. starting with 0 in the top left, 1 to its right etc.
-(IBAction)	snapAllItemsToGrid: (id)sender;			// Places all items on the nearest grid positions. Does the same as "clean up" does in the Finder.
-(NSRect)	rectForItemAtIndex: (NSUInteger)index;	// Returns a flipped rect.

// Drawing:
-(void)		itemNeedsDisplay: (NSUInteger)itemNb;	// Cause redraw of an item (eventually calls setNeedsDisplayInRect: on this view).
-(BOOL)     itemIsVisible: (NSUInteger)itemNb;
-(BOOL)     itemIsVisibleAtPosition: (NSPoint)pos;  // Position has reversed Y-axis.

// Hit-testing:
-(NSUInteger)		getItemIndexAtPoint: (NSPoint)aPoint;
-(NSUInteger)		getItemIndexInRect: (NSRect)aBox;		// aBox must have a reversed Y-axis. This checks for intersection of the two rects.

// Goodies for zooming/sizing windows:
-(IBAction)	rescrollItems: (id)sender;		// This is what Finder X never gets right. This moves all items so the leftmost one is at the left of the view and the topmost one at the top, removing any empty space above them, but not changing the items' relative positions.
-(NSRect)	bestRect;						// Do this after a rescroll to get the best size for showing all window contents at their current positions.
-(NSSize)	bestSize;						// Similar to bestRect, but returns the extents of all items (plus margins). I.e. this is what bestRect.size would be after a rescroll.
-(NSSize)   windowFrameSizeForBestSize;		// Useful for zooming. Calls bestSize to determine a good size for this view.
-(NSRect)   windowFrameForBestSize;         // Same as windowFrameSizeForBestSize, but returns a rect so the window's upper left corner doesn't move.

// Inline editing:
-(void)		editItemIndex: (NSUInteger)item withEvent:(NSEvent*)evt /*may be NIL*/ select:(BOOL)select;

// Scrolling when embedded in an NSScrollView:
-(void)     scrollItemToVisible: (NSUInteger)index;
-(void)     scrollToPoint: (NSPoint)p;
-(void)     scrollByX: (float)dx y: (float)dy;

// Customization:
-(void)		drawSnapGuideInRect: (NSRect)box;	// Draws one of the "snap guide" boxes indicating where your item will end up.
-(void)		drawBackgroundInRect: (NSRect)box;	// By default fills the rect with white.
-(NSImage*) dragImageForItems:(NSArray*)dragIndexes event:(NSEvent*)dragEvent
				dragImageOffset:(NSPointPointer)dragImageOffset;

@end


/* -----------------------------------------------------------------------------
	Data source protocol:
   -------------------------------------------------------------------------- */

// If you want a layer-based view, implement this new protocol.
//	for cell-based, implement the UKDistributedViewDataSource informal protocol below.
@protocol ULIDistributedViewDataSource <NSObject>

/* NOTE: Item positions are in "flipped" coordinates, i.e. the y-axis has
		been reversed and starts at the top and increases down. That way,
		items will not need to be repositioned when the view or window
		are resized. */

/* You *must* implement these to do anything useful: */
-(NSUInteger)	numberOfItemsInDistributedView: (UKDistributedView*)distributedView;

-(NSPoint)		distributedView: (UKDistributedView*)distributedView
						positionAtItemIndex: (NSUInteger)row;

-(NSImage*)		distributedView: (UKDistributedView*)distributedView
						imageAtItemIndex: (NSUInteger)row;

-(NSString*)	distributedView: (UKDistributedView*)distributedView
						titleAtItemIndex: (NSUInteger)row;

@optional

// Implement this if you want the user to be able to reposition your items:
-(void)			distributedView: (UKDistributedView*)distributedView
						setPosition: (NSPoint)pos
						forItemIndex: (NSUInteger)row;

// Implement this if you want tool tips for items in the view:
-(NSString*)    distributedView: (UKDistributedView*)distributedView toolTipForItemAtIndex: (NSUInteger)row;

@end


@interface NSObject (UKDistributedViewDataSource)

/* NOTE: Item positions are in "flipped" coordinates, i.e. the y-axis has
		been reversed and starts at the top and increases down. That way,
		items will not need to be repositioned when the view or window
		are resized. */

/* You *must* implement these to do anything useful:
	You are supposed to directly manipulate the cell passed to display your
	data in it appropriately. Handy tip: Messages to nil objects are simply
	ignored. */
-(NSUInteger)	numberOfItemsInDistributedView: (UKDistributedView*)distributedView;

-(NSPoint)		distributedView: (UKDistributedView*)distributedView
						positionForCell:(NSCell*)cell /* may be nil if the view only wants the item position. */
						atItemIndex: (NSUInteger)row;

// Implement this if you want the user to be able to reposition your items:
-(void)			distributedView: (UKDistributedView*)distributedView
						setPosition: (NSPoint)pos
						forItemIndex: (NSUInteger)row;

// Implement this if you want user to be able to edit cell titles:
//  In addition, you will have to set your prototype cell's isEditable property
//  either when creating it, or in distributedView:positionForCell:atItemIndex:
//  in the course of preparing your cell.
-(void)			distributedView: (UKDistributedView*)distributedView
						setObjectValue: (id)val
						forItemIndex: (NSUInteger)row;

// Implement this if you want tool tips for items in the view:
-(NSString*)    distributedView: (UKDistributedView*)distributedView toolTipForItemAtIndex: (NSUInteger)row;

@end


/* -----------------------------------------------------------------------------
	Drag & Drop protocol for data source:
   -------------------------------------------------------------------------- */

//  These are optional. If not implemented, but setPosition is, you can still
//  perform old-style "live" moving of the items inside their window.

@interface NSObject (UKDistributedViewDnDDataSource)

// Write the requested items' data to the specified pasteboard:
-(BOOL)				distributedView: (UKDistributedView*)dv writeItems:(NSArray*)indexes
						toPasteboard: (NSPasteboard*)pboard;

// Are we copying when dragging out of this view?
-(NSDragOperation)  distributedView: (UKDistributedView*)dv
						draggingSourceOperationMaskForLocal: (BOOL)isLocal;

// Specify where the dropped data should end up. On ("inside") an item, or just among them?
-(NSDragOperation)  distributedView: (UKDistributedView*)dv validateDrop: (id <NSDraggingInfo>)info
						proposedItem: (NSUInteger*)row;	// Change "row", if you want. NSNotFound means it's not on any item.

// Say whether you accept a drop of an item:
-(BOOL)				distributedView: (UKDistributedView*)dv acceptDrop:(id <NSDraggingInfo>)info
						onItem:(NSUInteger)row;

// Use this to handle drops on the trash etc:
-(void)				distributedView: (UKDistributedView*)dv dragEndedWithOperation: (NSDragOperation)operation;

@end


/* -----------------------------------------------------------------------------
	Delegate protocol:
   -------------------------------------------------------------------------- */

@interface NSObject (UKDistributedViewDelegate)

// Called upon a mouseUp in a cell: (except if it was a drag)
-(void) distributedView: (UKDistributedView*)distributedView cellClickedAtItemIndex: (NSUInteger)item;

// Called on the second mouseDown of a double-click in a cell: (except if it was on the text area and the cell is editable)
-(void) distributedView: (UKDistributedView*)distributedView cellDoubleClickedAtItemIndex: (NSUInteger)item;

// Selection changes: (not sent for programmatic selection changes)
-(BOOL) distributedView: (UKDistributedView*)distributedView shouldSelectItemIndex: (NSUInteger)item;
-(void) distributedView: (UKDistributedView*)distributedView didSelectItemIndex: (NSUInteger)item;

// Return the item that matches a string:
//  UKDV sends this for type-ahead with options being NSCaseInsensitiveSearch and NSAnchoredSearch
//  (meaning ignore case and match only strings that start with this string), and
//  when you call selectItemContainingString: with options NSCaseInsensitiveSearch.
//	UKDV provides a default implementation of this that works if your items are
//	ordered alphabetically already.
-(int)  distributedView: (UKDistributedView*)distributedView itemIndexForString: (NSString*)str options: (NSStringCompareOptions)opts;

// For displaying progress info for large lists:
-(void) distributedViewDidStartCachingItems: (UKDistributedView*)distributedView;
-(void) distributedViewWillEndCachingItems: (UKDistributedView*)distributedView;

@end


/* -----------------------------------------------------------------------------
	Notifications:
   -------------------------------------------------------------------------- */

extern NSString*		UKDistributedViewSelectionDidChangeNotification;	// Object is the UKDistributedView.

