//
//  UKDistributedView.m
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

/* -----------------------------------------------------------------------------
	Headers:
   -------------------------------------------------------------------------- */

#import "UKDistributedView.h"
#import <limits.h>
#import <QuartzCore/QuartzCore.h>


/* -----------------------------------------------------------------------------
	Notifications:
   -------------------------------------------------------------------------- */

NSString*		UKDistributedViewSelectionDidChangeNotification = @"UKDistributedViewSelectionDidChange";



/* -----------------------------------------------------------------------------
	Private Methods:
   -------------------------------------------------------------------------- */

@interface UKDistributedView ()

-(NSRect)	snapRectToGrid: (NSRect)box;	// Calls forceRectToGrid if forceToGrid is true, otherwise returns the rect unmodified.
-(NSRect)	forceRectToGrid: (NSRect)box;
-(NSRect)	flipRectsYAxis: (NSRect)box;
-(void)		contentSizeChanged;
-(void)		drawGridForDrawRect: (NSRect)rect;
-(void)		drawCellsForDrawRect: (NSRect)rect;
-(void)		drawSelectionRectForDrawRect: (NSRect)rect;
-(void)     drawDropHiliteForDrawRect: (NSRect)rect;
-(void)		selectionSetNeedsDisplay;

-(void)		invalidateVisibleItemsCache;
-(void)		extendCacheByVisibleItemIndexesInRect: (NSRect)inBox startingAtIndex: (int)startIdx;   // Build cache of (potentially) visible items used for drawing and mouse tracking.
-(int)      getItemIndexForSuggestionInRect: (NSRect)aBox;  // Uses cache in multi-positioning mode, otherwise calls getUncachedItemIndexInRect:.
-(int)		getUncachedItemIndexInRect: (NSRect)aBox;
-(void)     removeAllRowsFromSuggestionCacheBelow: (float)yPos;
-(NSRect)   rectAroundItems: (NSArray*)dragIndexes;

-(void)             initiateDrag: (NSEvent*)event;
-(void)             initiateMove;
-(void)             addPositionsOfItems: (NSArray*)indexes toPasteboard: (NSPasteboard*)pboard;
-(NSMutableArray*)  positionsOfItemsOnPasteboard: (NSPasteboard*)pboard forImagePosition: (NSPoint)imgPos;

-(IBAction)	cellClicked: (id)sender;

-(NSRect)   computeFrame;

@end


/* -----------------------------------------------------------------------------
	UKDistributedView:
   -------------------------------------------------------------------------- */

@implementation UKDistributedView

-(id)	initWithFrame: (NSRect)frame
{
    self = [super initWithFrame:frame];
    if( self )
	{
		lastPos = NSMakePoint(0,0);
		cellSize = NSMakeSize( 100.0,100.0 );
		gridSize.width = cellSize.width /2;
		gridSize.height = cellSize.height /2;
		contentInset = 8.0;
		flags.bits.forceToGrid = flags.bits.snapToGrid = NO;
		prototype = [[NSCell alloc] init];
		mouseItem = -1;
		dragDestItem = -1;
		flags.bits.dragMovesItems = NO;
		delegate = dataSource = nil;
		selectionSet = [[NSMutableSet alloc] init];
		flags.bits.useSelectionRect = flags.bits.allowsMultipleSelection = flags.bits.allowsEmptySelection = YES;
		flags.bits.sizeToFit = YES;
		flags.bits.showSnapGuides = YES;
		runtimeFlags.bits.drawSnappedRects = NO;
		flags.bits.drawsGrid = NO;
		flags.bits.drawsBackground = NO;
		gridColor = [[NSColor gridColor] retain];
		selectionRect = NSZeroRect;
		visibleItemRect = NSZeroRect;
		visibleItems = [[NSMutableArray alloc] init];
		editedItem = -1;
	}
    return self;
}

-(id)	init
{
	// always route through designated initializer
	return [self initWithFrame:NSZeroRect];
}


/* -----------------------------------------------------------------------------
	initWithCoder:
		Persistence constructor needed for IB palette.
	
	REVISIONS:
        2004-12-02  UK  Changed to use flags structure instead of lots of BOOLs.
		2004-12-01	UK	Documented.
   -------------------------------------------------------------------------- */

-(id)   initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
	
    lastPos = NSMakePoint(0,0);
    mouseItem = -1;
    dragDestItem = -1;
    delegate = dataSource = nil;
    selectionRect = NSZeroRect;
    visibleItemRect = NSZeroRect;
    visibleItems = [[NSMutableArray alloc] init];
    editedItem = -1;
    
    if( [decoder allowsKeyedCoding] )
    {
        unsigned len = sizeof(NSSize);
        cellSize = *(NSSize*)[decoder decodeBytesForKey: @"UKDVcellSize" returnedLength: &len];
        gridSize = *(NSSize*)[decoder decodeBytesForKey: @"UKDVgridSize" returnedLength: &len];
        contentInset = [decoder decodeFloatForKey: @"UKDVcontentInset"];
        flags.allFlags = [decoder decodeIntForKey: @"UKDVflags"];
        prototype = [[decoder decodeObjectForKey: @"UKDVprototype"] retain];
        gridColor = [[decoder decodeObjectForKey: @"UKDVgridColor"] retain];
    }
    else
    {
        [decoder decodeValueOfObjCType:@encode(NSSize) at: &cellSize];
        [decoder decodeValueOfObjCType:@encode(NSSize) at: &gridSize];
        [decoder decodeValueOfObjCType:@encode(float) at: &contentInset];
        [decoder decodeValueOfObjCType:@encode(int) at: &flags.allFlags];
        prototype = [[decoder decodeObject] retain];
        gridColor = [[decoder decodeObject] retain];
    }

    // Apply defaults, if needed:
    if( !prototype )
        prototype = [[NSCell alloc] init];
    selectionSet = [[NSMutableSet set] retain];
    if( !gridColor )
        gridColor = [[NSColor gridColor] retain];
    
    return self;
}


/* -----------------------------------------------------------------------------
	encodeWithCoder:
		Save this view to a file. Used by IB.
	
	REVISIONS:
        2004-12-02  UK  Changed to use flags structure instead of lots of BOOLs.
		2004-12-01	UK	Documented.
   -------------------------------------------------------------------------- */

-(void) encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
	
    if( [coder allowsKeyedCoding] )
    {
        [coder encodeBytes: (const uint8_t *)&cellSize length: sizeof(NSSize) forKey: @"UKDVcellSize"];
        [coder encodeBytes: (const uint8_t *)&gridSize length: sizeof(NSSize) forKey: @"UKDVgridSize"];
        [coder encodeFloat: contentInset forKey: @"UKDVcontentInset"];
        [coder encodeInt: flags.allFlags forKey: @"UKDVflags"];
        [coder encodeObject: prototype forKey: @"UKDVprototype"];
        [coder encodeObject: gridColor forKey: @"UKDVgridColor"];
    }
    else
    {
        [coder encodeValueOfObjCType:@encode(NSSize) at: &cellSize];
        [coder encodeValueOfObjCType:@encode(NSSize) at: &gridSize];
        [coder encodeValueOfObjCType:@encode(float) at: &contentInset];
        [coder encodeValueOfObjCType:@encode(int) at: &flags.allFlags];
        [coder encodeObject: prototype];
        [coder encodeObject: gridColor];
    }
}


-(void)	dealloc
{
	[visibleItems release];
	[selectionSet release];
	[prototype release];
	
	[super dealloc];
}


// -----------------------------------------------------------------------------
//  Selection Management:
// -----------------------------------------------------------------------------
#pragma mark Selection Management

-(int)	selectedItem
{
	return [self selectedItemIndex];
}

-(int)	selectedItemIndex
{
	NSEnumerator*	enny = [selectionSet objectEnumerator];
	int				i = -1;
	NSNumber*		num;
	
	if( (num = [enny nextObject]) )
		i = [num intValue];
	
	return i;
}


-(NSEnumerator*)	selectedItemEnumerator
{
	return [selectionSet objectEnumerator];
}


-(int)				selectedItemCount
{
	return [selectionSet count];
}


-(void)	selectItem: (int)index byExtendingSelection: (BOOL)ext
{
	NSParameterAssert( index >= 0 && index < [[self dataSource] numberOfItemsInDistributedView: self] );
    
	if (![self allowsMultipleSelection])
		ext = NO;

    if( !ext )
    {
        [self selectionSetNeedsDisplay];
        [selectionSet removeAllObjects];
    }

	if( index != -1 && ![selectionSet containsObject:[NSNumber numberWithInt: index]] )
		[selectionSet addObject:[NSNumber numberWithInt: index]];
	
	[self itemNeedsDisplay: index];
}

-(void)	deselectItem: (int)index {

	[selectionSet removeObject: [NSNumber numberWithInt: index]];
	[[NSNotificationCenter defaultCenter] postNotificationName: UKDistributedViewSelectionDidChangeNotification
			object: self];
	[self itemNeedsDisplay: index];
}

-(void)	selectItemsInRect: (NSRect)aBox byExtendingSelection: (BOOL)ext
{
	if (![self allowsMultipleSelection])
		return;
	
	int		x, count = [[self dataSource] numberOfItemsInDistributedView:self];
	
	if( !ext )
	{
		[self selectionSetNeedsDisplay];	// Make sure items are redrawn unselected.
		[selectionSet removeAllObjects];
	}
	
	aBox = [self flipRectsYAxis: aBox];

	for( x = 0; x < count; x++ )
	{
		NSRect		box = [self rectForItemAtIndex:x];
		box = [self snapRectToGrid: box];

		if( NSIntersectsRect( aBox, box ) )
		{
			if( ![selectionSet containsObject:[NSNumber numberWithInt: x]] )
				[selectionSet addObject:[NSNumber numberWithInt: x]];
			if( [delegate respondsToSelector: @selector(distributedView:didSelectItemIndex:)] )
				[delegate distributedView:self didSelectItemIndex: x];
		}
	}
	
	[self selectionSetNeedsDisplay];	// Make sure newly selected items are drawn that way.
	
	[[NSNotificationCenter defaultCenter] postNotificationName: UKDistributedViewSelectionDidChangeNotification
											object: self];
}


-(void) selectItemContainingString: (NSString*)str
{
    int matchItem = [delegate distributedView:self itemIndexForString: str options: NSCaseInsensitiveSearch];
    if( matchItem != -1 )
    {
        [self selectItem: matchItem byExtendingSelection: NO];
        [self scrollItemToVisible: matchItem];
    }
}


-(void)  updateSelectionSet
{
	NSEnumerator*		selEnny = [selectionSet objectEnumerator];
	int					count = [[self dataSource] numberOfItemsInDistributedView:self];
	NSNumber*			currIndex = nil;
	
	while( (currIndex = [selEnny nextObject]) )
	{
		if( [currIndex intValue] >= count )
			[selectionSet removeObject: currIndex];
	}
}


// -----------------------------------------------------------------------------
//  Menu actions:
// -----------------------------------------------------------------------------
#pragma mark Menu Actions

-(IBAction)			selectAll: (id)sender
{
	int		count = [[self dataSource] numberOfItemsInDistributedView:self];
	
	[selectionSet removeAllObjects];
	
	while( --count >= 0 )
	{
		if( [delegate respondsToSelector: @selector(distributedView:didSelectItemIndex:)] )
			[delegate distributedView:self didSelectItemIndex: count];
		[selectionSet addObject:[NSNumber numberWithInt: count]];
	}
	
	[self setNeedsDisplay:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName: UKDistributedViewSelectionDidChangeNotification
											object: self];
}


-(IBAction)			deselectAll: (id)sender
{
	if( flags.bits.allowsEmptySelection )
	{
		NSSet*	oldSelection = [[selectionSet copy] autorelease];
		[selectionSet removeAllObjects];
		[self itemSetNeedsDisplay: oldSelection];
	
		[[NSNotificationCenter defaultCenter] postNotificationName: UKDistributedViewSelectionDidChangeNotification
												object: self];
	}
}


-(IBAction)			toggleDrawsGrid: (id)sender
{
	[self setDrawsGrid: !flags.bits.drawsGrid];
}


-(IBAction)			toggleSnapToGrid: (id)sender
{
	[self setSnapToGrid: !flags.bits.snapToGrid];
}


/* -----------------------------------------------------------------------------
	validateMenuItem:
		Make sure menu items are enabled properly.
	
	REVISIONS:
		2003-06-29	UK	Created.
   -------------------------------------------------------------------------- */

-(BOOL)	validateMenuItem: (NSMenuItem*)menuItem
{
	// Edit menu commands:
	if( [menuItem action] == @selector(selectAll:) )
		return flags.bits.allowsMultipleSelection;
	else if( [menuItem action] == @selector(deselectAll:) )
		return( ([self selectedItemCount] > 0) && flags.bits.allowsEmptySelection );
	// Grid, repositioning and other Finder-like behaviour:
	else if( [menuItem action] == @selector(positionAllItems:) )
		return [[self dataSource] respondsToSelector: @selector(distributedView:setPosition:forItemIndex:)];
	else if( [menuItem action] == @selector(snapAllItemsToGrid:) )
		return [[self dataSource] respondsToSelector: @selector(distributedView:setPosition:forItemIndex:)];
	else if( [menuItem action] == @selector(toggleDrawsGrid:) )
	{
		[menuItem setState: flags.bits.drawsGrid];
		return YES;
	}
	else if( [menuItem action] == @selector(toggleSnapToGrid:) )
	{
		[menuItem setState: flags.bits.snapToGrid];
		return YES;
	}
	else if( [menuItem action] == @selector(rescrollItems:) )	// Don't see why you'd want a menu item for this (besides debugging). You should really call this from your window zooming code.
		return YES;
	else if( [delegate respondsToSelector: [menuItem action]] )
	{
		if( [delegate respondsToSelector: @selector(validateMenuItem:)] )
			return [delegate validateMenuItem: menuItem];
		else
			return YES;
	}
	else
		return [self respondsToSelector: [menuItem action]];
}


// -----------------------------------------------------------------------------
//  Accessors:
// -----------------------------------------------------------------------------
#pragma mark Accessors

/* Set this to NO if you never want more than one item to be selected: */
-(void)				setAllowsMultipleSelection: (BOOL)state
{
	flags.bits.allowsMultipleSelection = state;
	
	if( !state && [selectionSet count] > 1 )
	{
		[self selectionSetNeedsDisplay];	// Make sure all unselected items are redrawn.
		[selectionSet autorelease];
		selectionSet = [[NSMutableSet setWithObject: [selectionSet anyObject]] retain];
	}
}


-(BOOL)				allowsMultipleSelection
{
	return flags.bits.allowsMultipleSelection;
}


/* Set this to NO if you always want at least one item to be selected: */
-(void)				setAllowsEmptySelection: (BOOL)state
{
	flags.bits.allowsEmptySelection = state;
	
	if( !state && [selectionSet count] == 0 )
	{
		[selectionSet addObject:[NSNumber numberWithInt: 0]];
		[self itemNeedsDisplay: 0];
	}
}


-(BOOL)				allowsEmptySelection
{
	return flags.bits.allowsEmptySelection;
}


/* If you want the user to be able to click in the view's background to drag
    a "rubber-band" selection rectangle for selecting multiple items, set this
    to YES: */
-(void)				setUseSelectionRect: (BOOL)state
{
	flags.bits.useSelectionRect = state;
	
	// Selection rect implicitly turns on allowsMultipleSelection:
	if( (!flags.bits.allowsMultipleSelection) && state )
		[self setAllowsMultipleSelection:YES];
	if( (!flags.bits.allowsEmptySelection) && state )
		[self setAllowsEmptySelection:YES];
}


-(BOOL)				useSelectionRect
{
	return flags.bits.useSelectionRect && flags.bits.allowsMultipleSelection && flags.bits.allowsEmptySelection;
}


/* If drawsGrid == YES, this color will be used to draw grid lines: */
-(void)		setGridColor: (NSColor*)c
{
	[c retain];
	[gridColor release];
	gridColor = c;
}


-(NSColor*)	gridColor
{
	return gridColor;
}


/* The prototype is the "data cell" used for displaying items:
	Use this to change the cell type used for display. */
-(void)	setPrototype: (NSCell*)aCell
{
	[aCell retain];
	[prototype autorelease];
	prototype = aCell;
	
    NS_DURING
        [prototype setTarget: self];
        [prototype setAction: @selector(cellClicked:)];
    NS_HANDLER
        // NSImageCell throws on setTarget/setAction :-T
    NS_ENDHANDLER
}


-(id)	prototype
{
	return prototype;
}


/* All items's positions will be nudged to lie on a grid coordinate:
	This will only modify the coordinates during display. This will
	*not* change any actual item positions, and this doesn't make sure
	that no items overlap. */
-(void)	setForceToGrid: (BOOL)state
{
	flags.bits.forceToGrid = state;
	[self setNeedsDisplay: YES];
}


-(BOOL) forceToGrid
{
	return flags.bits.forceToGrid;
}


/* Dragging an item moves the items or starts drag and drop. If you're just
    after NSTableView-ish behavior, you'll want this to be NO. */
-(void)	setDragMovesItems: (BOOL)state
{
	flags.bits.dragMovesItems = state;
}


-(BOOL) dragMovesItems
{
	return flags.bits.dragMovesItems;
}


/* When dragMovesItems == YES and the data source doesn't implement DnD, drags
    happen locally and 'live' within the view, and simply reposition the items.
    If you set dragLocally to YES, local drags will also be used when the data
    source implements DnD, and "real" DnD will not happen until the mouse leaves
    the view's visible rectangle. */
-(void)		setDragLocally: (BOOL)state
{
    flags.bits.dragLocally = state;
}

-(BOOL)		dragLocally
{
    return flags.bits.dragLocally;
}



/* Whenever an object moves, make this view resize to fit. */ 
-(void)	setSizeToFit: (BOOL)state
{
	flags.bits.sizeToFit = state;
}


-(BOOL) sizeToFit
{
	return flags.bits.sizeToFit;
}


/* If you need to positionItem: or suggestedPosition a number of items in a row,
	call this around these calls. That way, the view will keep track of the
	previous item's position and start looking for a position for the next
	one after that, instead of starting at the top again. */ 
-(void)	setMultiPositioningMode: (BOOL)state
{
	if( state )
    {
		lastSuggestedItemPos = NSMakePoint(0,0);
        int count = [[self dataSource] numberOfItemsInDistributedView: self];
        
        [itemsBelowLastSuggested release];
        itemsBelowLastSuggested = [[NSMutableArray alloc] initWithCapacity: count];
        
        int x;
        for( x = 0; x < count; x++ )
            [itemsBelowLastSuggested addObject: [NSNumber numberWithInt: x]];
    }
    else
    {
        [itemsBelowLastSuggested release];
        itemsBelowLastSuggested = nil;
    }
	runtimeFlags.bits.multiPositioningMode = state;
}


-(BOOL) multiPositioningMode
{
	return runtimeFlags.bits.multiPositioningMode;
}


/* Always force newly positioned and moved items to lie on the grid. */ 
-(void)	setSnapToGrid: (BOOL)state
{
	flags.bits.snapToGrid = state;
}


-(BOOL) snapToGrid
{
	return flags.bits.snapToGrid;
}


-(void)		setShowSnapGuides: (BOOL)state
{
	flags.bits.showSnapGuides = state;
}


-(BOOL)		showSnapGuides
{
	return flags.bits.showSnapGuides;
}


-(void)		setDrawsGrid: (BOOL)state
{
	flags.bits.drawsGrid = state;
	[self setNeedsDisplay: YES];
}


-(BOOL)		drawsGrid
{
	return flags.bits.drawsGrid;
}


// The number of pixels of border to keep around the items:
-(void)	setContentInset: (float)inset
{
	contentInset = inset;
	if( flags.bits.forceToGrid )
		[self setNeedsDisplay: YES];
}


-(float) contentInset
{
	return contentInset;
}


// The cell size to use for our items:
-(void)	setCellSize: (NSSize)size
{
	cellSize = size;
	gridSize.width = cellSize.width /2;
	gridSize.height = cellSize.height /2;
	if( flags.bits.forceToGrid )
		[self setNeedsDisplay: YES];
}


-(NSSize) cellSize
{
	return cellSize;
}


// The size to use for our positioning grid:
-(void)	setGridSize: (NSSize)size
{
	gridSize = size;
	if( flags.bits.forceToGrid )
		[self setNeedsDisplay: YES];
}


-(NSSize) gridSize
{
	return gridSize;
}


-(id)	dataSource
{
	return dataSource;
}


-(void)	setDataSource: (id)d
{
	dataSource = d;
}


-(id)	delegate
{
	return delegate;
}


-(void)	setDelegate: (id)d
{
	delegate = d;
}


-(void)		setDrawsBackground: (BOOL)drawIt
{
	flags.bits.drawsBackground = drawIt;
	[self setNeedsDisplay: YES];
}

-(BOOL)		drawsBackground
{
	return flags.bits.drawsBackground;
}


// -----------------------------------------------------------------------------
//  Item Positioning:
// -----------------------------------------------------------------------------
#pragma mark Item Positioning

/* Position all items in order on the grid:
	This changes all items' positions *permanently*. Note that this simply tries to
	fit the items as orderly rows in the given rect, wrapping at the right edge. */
-(IBAction)	positionAllItems: (id)sender
{
    if( ![[self dataSource] respondsToSelector: @selector(distributedView:setPosition:forItemIndex:)] )
        return;
    
	NSRect			myFrame = [self frame];
	int				numCols,
					x,
					col = 0,
					row = 0,
					count = [[self dataSource] numberOfItemsInDistributedView:self];
	
	// Calculate display rect:
	myFrame.origin.x += contentInset;
	myFrame.origin.y += contentInset;
	myFrame.size.width -= contentInset *2;
	myFrame.size.height -= contentInset *2;
	
	// Calculate # of items that fit in display area in an orderly fashion:
	numCols = truncf(myFrame.size.width / cellSize.width);
	
	// Now loop over all slots in the window where we would put something:
	for( x = 0; x < count; x++ )
	{
		if( col >= numCols )
		{
			col = 0;
			row++;
		}
		
		NSRect		testBox = NSMakeRect( (col * cellSize.width) +contentInset,
											(row * cellSize.height) +contentInset,
											cellSize.width, cellSize.height );
		
		[[self dataSource] distributedView:self setPosition:testBox.origin forItemIndex:x];
		col++;
	}
	
	[[self window] invalidateCursorRectsForView:self];
	[self contentSizeChanged];
	[self setNeedsDisplay:YES];
}


/* Position all items on the closest grid location to their current location:
	This changes all items' positions *permanently*. */
-(IBAction)	snapAllItemsToGrid: (id)sender
{
    if( ![[self dataSource] respondsToSelector: @selector(distributedView:setPosition:forItemIndex:)] )
        return;
	BOOL			layerBased = [self.dataSource respondsToSelector: @selector(distributedView:titleAtItemIndex:)];
	
	int				x,
					count = [[self dataSource] numberOfItemsInDistributedView:self];
	
	// Now loop over all slots in the window where we would put something:
	for( x = 0; x < count; x++ )
	{
		NSRect		testBox = [self rectForItemAtIndex:x];
		testBox = [self forceRectToGrid:testBox];
		
		[[self dataSource] distributedView:self setPosition:testBox.origin forItemIndex:x];
		if( layerBased )
			[self itemNeedsDisplay: x];
	}
	
	[[self window] invalidateCursorRectsForView:self];
	[self contentSizeChanged];
	[self setNeedsDisplay:YES];
}


/* -----------------------------------------------------------------------------
	suggestedPosition:
		Reposition the item at the specified index. This moves the item
        somewhere where there is no other item.
        
        Note that this will *always* move the current item.
	
	REVISIONS:
		2004-12-02	UK	Added NSParameterAssert call.
   -------------------------------------------------------------------------- */

-(void)	positionItem: (int)itemIndex
{
	NSParameterAssert( itemIndex >= 0 && itemIndex < [[self dataSource] numberOfItemsInDistributedView: self] );
    
	NSRect			myFrame = [self frame];
	int				numCols, numRows,
					col, row;
	
	// Calculate display rect:
	myFrame.origin.x += contentInset;
	myFrame.origin.y += contentInset;
	myFrame.size.width -= contentInset *2;
	myFrame.size.height -= contentInset *2;
	
	// Calculate # of grid locations where we can put items:
	numCols = myFrame.size.width / gridSize.width;
	//numRows = myFrame.size.height / gridSize.height;
	numRows = INT_MAX;
	int		startRow = 0, startCol = 0;
	
	if( runtimeFlags.bits.multiPositioningMode )
		startRow = lastSuggestedItemPos.y;
	
	if( runtimeFlags.bits.multiPositioningMode )
		startCol = lastSuggestedItemPos.x;
	
	// Now loop over all slots in the window where we would put something:
	for( row = startRow; row < numRows; row++ )
	{
		for( col = startCol; col < numCols; col++ )
		{
			NSRect		testBox = NSMakeRect( (col * gridSize.width) +contentInset,
												(row * cellSize.height) +contentInset,
												cellSize.width, cellSize.height );
			
			int foundIndex = [self getUncachedItemIndexInRect:testBox];
			if( foundIndex == -1 )	// No item in this rect?
			{
				[[self dataSource] distributedView:self setPosition:testBox.origin forItemIndex:itemIndex];
				lastSuggestedItemPos.x = col;
				lastSuggestedItemPos.y = row;
				[[self window] invalidateCursorRectsForView:self];
				return;
			}
		}
		startCol = 0;   // Only first time round do we want to start in that row.
	}
}


/* -----------------------------------------------------------------------------
	suggestedPosition:
		Returns a position that is suggested for a new item. This doesn't
        propose any positions at which there already are items.
	
	REVISIONS:
		2004-12-02	UK	Documented.
   -------------------------------------------------------------------------- */

-(NSPoint)	suggestedPosition
{
	NSRect			myFrame = [self frame];
	int				numCols, numRows,
					col, row, startRow = 0, startCol = 0;
	
	// Calculate display rect:
	myFrame.origin.x += contentInset;
	myFrame.origin.y += contentInset;
	myFrame.size.width -= contentInset *2;
	myFrame.size.height -= contentInset *2;
	
	// Calculate # of grid slots where we could put this item:
	numCols = myFrame.size.width / gridSize.width;
	numRows = myFrame.size.height / gridSize.height;

	if( runtimeFlags.bits.multiPositioningMode )
		startRow = lastSuggestedItemPos.y;
	
	if( runtimeFlags.bits.multiPositioningMode )
		startCol = lastSuggestedItemPos.x;
	
	// Now loop over all slots in the window where we would put something:
	for( row = startRow; row < (startRow +(numRows *10)); row++ )	// * 10 so we don't try infinitely. Add to startRow since otherwise long lists would start stacking too early.
	{
		for( col = startCol; col < numCols; col++ )
		{
			NSRect		testBox = NSMakeRect( (col * gridSize.width) +contentInset,
												(row * gridSize.height) +contentInset,
												cellSize.width, cellSize.height );
			
			if( [self getItemIndexForSuggestionInRect: testBox] == -1 )	// No item in this rect?
            {
                if( runtimeFlags.bits.multiPositioningMode && row > lastSuggestedItemPos.y )
                    [self removeAllRowsFromSuggestionCacheBelow: testBox.origin.y];
                
                [itemsBelowLastSuggested addObject: [NSNumber numberWithInt: [[self dataSource]  numberOfItemsInDistributedView: self]]];
                
                lastSuggestedItemPos.x = col;
                lastSuggestedItemPos.y = row;
                
				return testBox.origin;
            }
		}
        
        startCol = 0;
	}
	
	return NSMakePoint(contentInset,contentInset);
}


/* -----------------------------------------------------------------------------
	itemPositionBasedOnItemIndex:
		Calculate a position for an item based on the item's index. Call this
        from your data source if you want items to "wrap" to the width of the
        view, like the Finder's "keep arranged by XX" option.
	
	REVISIONS:
		2004-12-02	UK	Added NSParameterAssert call.
   -------------------------------------------------------------------------- */

-(NSPoint)  itemPositionBasedOnItemIndex: (int)row
{
    NSPoint		pos = { 0, 0 };
	int			numCols = truncf(([self frame].size.width -(contentInset *2)) / cellSize.width);
	
    if( numCols < 1 )
		numCols = 1;
	
	pos.x = contentInset +(row % numCols) * cellSize.width;
	pos.y = contentInset +truncf( row / numCols ) * cellSize.height;
	
	return pos;
}



/* -----------------------------------------------------------------------------
	rectAroundItems:
		Return a rectangle enclosing all the items whose indexes are specified
		in the NSNumbers in the array dragIndexes.
	
	REVISIONS:
		2003-12-20	UK	Created.
   -------------------------------------------------------------------------- */

-(NSRect)   rectAroundItems: (NSArray*)dragIndexes
{
	NSRect			extents;
	NSEnumerator*   enny = [dragIndexes objectEnumerator];
	NSNumber*		currIndex = nil;
	float			l = INT_MAX, t = INT_MIN,
					r = INT_MIN, b = INT_MAX;
	
	// Find the lowest/highest X and Y coordinates and stuff them in l, t, r, and b:
	while( (currIndex = [enny nextObject]) )
	{
		NSRect		currBox = [self rectForItemAtIndex: [currIndex intValue]];
		
		currBox = [self flipRectsYAxis: currBox];
		
		if( NSMinX(currBox) < l )
			l = NSMinX(currBox);
		if( NSMinY(currBox) < b )
			b = NSMinY(currBox);
		if( NSMaxX(currBox) > r )
			r = NSMaxX(currBox);
		if( NSMaxY(currBox) > t )
			t = NSMaxY(currBox);
	}
	
	// Return the whole shebang as a rect:
	extents.origin.x = l;
	extents.origin.y = b;
	extents.size.width = r - l;
	extents.size.height = t - b;
	
	return extents;
}


-(NSRect)	snapRectToGrid: (NSRect)box
{
	if( flags.bits.forceToGrid )
		box = [self forceRectToGrid:box];
	return box;
}


-(NSRect)	forceRectToGrid: (NSRect)box
{
	float		xoffs = 0,
				yoffs = 0;

	// Offset objects relative to content inset:
	box.origin.x -= contentInset;
	box.origin.y -= contentInset;
	
	// Move rect to positive coordinates, otherwise they crowd at 0,0:
	if( box.origin.x < 0 )
	{
		xoffs = (truncf((-box.origin.x) / gridSize.width) +1) * gridSize.width;
		box.origin.x += xoffs;
	}
	if( box.origin.y < 0 )
	{
		yoffs = (truncf((-box.origin.y) / gridSize.height) +1) * gridSize.height;
		box.origin.y += yoffs;
	}
	
	// Actually move it onto the grid:
	box.origin.x = truncf((box.origin.x +(gridSize.width /2)) / gridSize.width) * gridSize.width;
	box.origin.y = truncf((box.origin.y +(gridSize.width /2)) / gridSize.height) * gridSize.height;
	
	// Undo origin shift:
	if( xoffs > 0 )
		box.origin.x -= xoffs;
	if( yoffs > 0 )
		box.origin.y -= yoffs;
	
	// Undo content inset shift:
	box.origin.x += contentInset;
	box.origin.y += contentInset;
	
	// Return adjusted box:
	return box;
}


-(NSRect)	flipRectsYAxis: (NSRect)box
{
	NSRect		result = box;
	result.origin.y = [self frame].size.height -box.origin.y -box.size.height;
	
	return result;
}




// Point must be in regular (non-flipped) coordinates:
-(int)	getItemIndexAtPoint: (NSPoint)aPoint
{
	NSEnumerator*   indexEnny = [visibleItems reverseObjectEnumerator]; // Opposite from drawing order, so we hit last drawn object (on top) first.
	NSNumber*		currIndex = nil;
	BOOL			layerBased = [self.dataSource respondsToSelector: @selector(distributedView:titleAtItemIndex:)];
	
	while( (currIndex = [indexEnny nextObject]) )
	{
		int			x = [currIndex intValue];
		NSRect		box;
		
		box.size = cellSize;
		if( layerBased )
			box.origin = [[self dataSource] distributedView: self positionAtItemIndex: x];
		else
			box.origin = [[self dataSource] distributedView: self positionForCell:prototype atItemIndex: x];
		box = [self snapRectToGrid: box];
		box = [self flipRectsYAxis: box];

		// if we're in the vicinity...		
		if( NSPointInRect( aPoint, box ) )
		{
			NSColor *colorAtPoint = nil;

			// Lock focus on ourselves to perform some spot drawing:
			[self lockFocus];
				// First empty the pixels inside our box:
				[[NSColor clearColor] set];
				NSRectFillUsingOperation( box, NSCompositeClear );

				// Next, draw our cell and grab the color at our mouse:
				[prototype drawWithFrame:box inView:self];
				colorAtPoint = NSReadPixel(aPoint);
			[self unlockFocus];

			[self setNeedsDisplayInRect: box];  // Update or our temporary drawing screws up the looks.
			
			/* Now if we've found a color, and if it's sufficiently
				opaque, then call the hit a success: */
			if( colorAtPoint && [colorAtPoint alphaComponent] > 0.1 )
				return x;
		}
	}
	
	return -1;
}


// Rect must be in flipped coordinates:
-(int)	getItemIndexInRect: (NSRect)aBox
{
	NSEnumerator*   indexEnny = [visibleItems reverseObjectEnumerator];
	NSNumber*		currIndex = nil;
	
	while( (currIndex = [indexEnny nextObject]) )
	{
		int			x = [currIndex intValue];
		NSRect		box = [self rectForItemAtIndex:x];
		
		box = [self snapRectToGrid: box];
		//box = [self flipRectsYAxis: box];
		
		NSRect textRect = [prototype titleRectForBounds:box];
		NSRect imageRect = [prototype imageRectForBounds:box];
		
		if( NSIntersectsRect( aBox, imageRect ) || NSIntersectsRect(aBox, textRect) )
			return x;
	}
	
	return -1;
}


// Rect must be in flipped coordinates:
-(int)	getUncachedItemIndexInRect: (NSRect)aBox
{
	int		x, count = [[self dataSource] numberOfItemsInDistributedView:self];
	
	for( x = 0; x < count; x++ )
	{
		NSRect		box = [self rectForItemAtIndex:x];
		box = [self snapRectToGrid: box];

		if( NSIntersectsRect( aBox, box ) )
			return x;
	}
	
	return -1;
}


// Rect must be in flipped coordinates:
-(int)	getItemIndexForSuggestionInRect: (NSRect)aBox
{
    if( !runtimeFlags.bits.multiPositioningMode )
        return [self getUncachedItemIndexInRect: aBox];
    
    NSEnumerator*   enny = [itemsBelowLastSuggested objectEnumerator];
    NSNumber*       currIdx = nil;
	
	while( (currIdx = [enny nextObject]) )
	{
		NSRect		box = [self rectForItemAtIndex: [currIdx intValue]];
		box = [self snapRectToGrid: box];

		if( NSIntersectsRect( aBox, box ) )
			return [currIdx intValue];
	}
	
	return -1;
}


// yPos must be in flipped coordinates:
-(void)	removeAllRowsFromSuggestionCacheBelow: (float)yPos
{
    int             count= [itemsBelowLastSuggested count];
    int             x = 0;
	
	for( x = 0; x < count; x++ )
	{
		NSRect		box = [self rectForItemAtIndex: [[itemsBelowLastSuggested objectAtIndex: x] intValue]];
		box = [self snapRectToGrid: box];

		if( box.origin.y +box.size.height < yPos )
        {
            [itemsBelowLastSuggested removeObjectAtIndex: x];
            --x; --count;
        }
	}
}


/* Return the best rect for this object that encloses all items at their current positions plus the
	content inset: */
-(NSRect)	bestRect
{
	int		x, count = [[self dataSource] numberOfItemsInDistributedView:self];
	NSRect	bestBox = [self frame];
	
	bestBox.size.width = bestBox.size.height = 0;
	
	for( x = 0; x < count; x++ )
	{
		NSRect		box = [self rectForItemAtIndex:x];
		box = [self snapRectToGrid: box];

		if( (box.size.width +box.origin.x) > bestBox.size.width )
			bestBox.size.width = (box.size.width +box.origin.x);
		if( (box.size.height +box.origin.y) > bestBox.size.height )
			bestBox.size.height = (box.size.height +box.origin.y);
	}
	
	bestBox.size.width += contentInset;
	bestBox.size.height += contentInset;
		
	return bestBox;
}

-(NSSize)	bestSize
{
	int		x, count = [[self dataSource] numberOfItemsInDistributedView:self];
	float   minX = INT_MAX,
			maxX = INT_MIN,
			minY = INT_MAX,
			maxY = INT_MIN;
	
	for( x = 0; x < count; x++ )
	{
		NSRect		box = [self rectForItemAtIndex:x];
		box = [self snapRectToGrid: box];

		if( (box.size.width +box.origin.x) > maxX )
			maxX = (box.size.width +box.origin.x);
		if( (box.size.height +box.origin.y) > maxY )
			maxY = (box.size.height +box.origin.y);
		if( box.origin.x < minX )
			minX = box.origin.x;
		if( box.origin.y < minY )
			minY = box.origin.y;
	}
		
	return NSMakeSize( maxX -minX +(contentInset *2), maxY -minY +(contentInset*2) );
}


/* -----------------------------------------------------------------------------
	windowFrameSizeForBestSize:
		This assumes this view is set up so it always keeps the same distance
		to window edges and resizes along with the window, i.e. the "Size" view
		in IB looks something like the following:
		
	    |
	 +--+--+
	 |  s  |       "s" and "un" are supposed to be "springs".
	-+un+un+-
	 |  s  |
	 +--+--+
	    |
	
	REVISIONS:
		2003-12-18	UK	Created.
   -------------------------------------------------------------------------- */

-(NSSize)   windowFrameSizeForBestSize
{
	// Calculate rect for our window's content area:
	NSRect		contentRect = [NSWindow contentRectForFrameRect:[[self window] frame] styleMask:[[self window] styleMask]];

	// Calculate how many pixels are around this view in the window:
	NSSize wdSize = contentRect.size;
	
	wdSize.width -= [[self enclosingScrollView] bounds].size.width;
	wdSize.height -= [[self enclosingScrollView] bounds].size.height;
	
	// Calc best size and enlarge it by that many pixels:
	NSSize  finalSize = [self bestSize];
    if( finalSize.width == 0 )
        finalSize.width = 100;
    if( finalSize.height == 0 )
        finalSize.height = 100;
	finalSize.width += wdSize.width;
	finalSize.height += wdSize.height;
	
	// Adjust for scrollbars:
	finalSize.width += 17;
	finalSize.height += 17;
	
	contentRect.size = finalSize;
	
	// Return that as best size for our window:
	return [NSWindow frameRectForContentRect:contentRect styleMask:[[self window] styleMask]].size;
}


/* -----------------------------------------------------------------------------
	windowFrameForBestSize:
		Calls windowFrameSizeForBestSize, then returns a rectangle of that size
        which has its upper left corner in the same position as the view's
        window. Handy one-shot call for decent in-place zooming.
	
	REVISIONS:
		2004-11-18	UK	Created.
   -------------------------------------------------------------------------- */

-(NSRect)   windowFrameForBestSize
{
    NSSize      bestSz = [self windowFrameSizeForBestSize];
	NSRect		frameRect = [[self window] frame];
    float       diff;
    
    diff = frameRect.size.height -bestSz.height;
    
    frameRect.size = bestSz;
    frameRect.origin.y += diff;
    
	return frameRect;
}


// Rect is in flipped coordinates:
-(NSRect)	rectForItemAtIndex: (int)index
{
	NSParameterAssert( index >= 0 && index < [[self dataSource] numberOfItemsInDistributedView: self] );
    
	BOOL		layerBased = [self.dataSource respondsToSelector: @selector(distributedView:titleAtItemIndex:)];
	NSRect		box = NSMakeRect( 0,0, cellSize.width,cellSize.height );
	if( layerBased )
		box.origin = [[self dataSource] distributedView: self positionAtItemIndex: index];
	else
		box.origin = [[self dataSource] distributedView:self positionForCell:nil atItemIndex:index];
	return box;
}


// -----------------------------------------------------------------------------
//  Drawing and Display:
// -----------------------------------------------------------------------------
#pragma mark Drawing and Display

-(void)	drawGridForDrawRect: (NSRect)rect
{
	if( !flags.bits.drawsGrid )
		return;

	NSRect		box = [self frame];
	int			cols, rows, x, y;
	
	// Draw outline around margin:
	box.origin.x += contentInset +0.5;		// 0.5 so it draws on a full pixel
	box.origin.y += contentInset -0.5;		// 0.5 so it draws on a full pixel, - because it has to match the Y-flipped rects below
	box.size.width -= contentInset *2;
	box.size.height -= contentInset *2;
	[[self gridColor] set];
	[NSBezierPath setDefaultLineWidth: 1.0];
	[NSBezierPath strokeRect:box];
	
	NSRectClip(box);	// TODO Do we want this to clip drawing of cells? Or should we restore graf state?
	
	// Now draw grid itself:
	cols = (box.size.width / gridSize.width) +1;
	rows = (box.size.height / gridSize.height) +1;
	
	for( x = 0; x < cols; x++ )
	{
		for( y = 0; y < rows; y++ )
		{
			NSRect		gridBox = NSMakeRect( (x * gridSize.width) +0.5 +contentInset, (y * gridSize.height) +0.5 +contentInset,
												gridSize.width, gridSize.height );
			gridBox = [self flipRectsYAxis:gridBox];
			[NSBezierPath strokeRect:gridBox];
		}
	}
}


-(void)	drawCellsForDrawRect: (NSRect)rect	// Only used for cell-based tables
{
	/* This rect isn't in our cache?
		Redo the cache, including 5 item heights above/below and 5 item widths
		left/right beyond what is currently visible: */
	if( !NSContainsRect( visibleItemRect, [self flipRectsYAxis: rect] ) )
	{
		NSRect		cacheRect = NSInsetRect( [self visibleRect], cellSize.width *-(UKDISTVIEW_INVIS_ITEMS_CACHE_COUNT *2), cellSize.height *-(UKDISTVIEW_INVIS_ITEMS_CACHE_COUNT *2) );
		[self invalidateVisibleItemsCache];
		[self extendCacheByVisibleItemIndexesInRect: [self flipRectsYAxis: cacheRect] startingAtIndex: 0];
	}
	
	// Now use the cache to draw all visible items:
	NSEnumerator*   indexEnny = [visibleItems objectEnumerator];
	NSNumber*		currIndex = nil;
	int				icount = [[self dataSource] numberOfItemsInDistributedView: self];
	
	//NSLog(@"count visible: %d",[visibleItems count]);
	
	while( (currIndex = [indexEnny nextObject]) )
	{
		NSRect		box = NSMakeRect( 0,0, cellSize.width,cellSize.height );
		int			x = [currIndex intValue];
		
		if( x > icount )
			continue;
		box.origin = [[self dataSource] distributedView: self positionForCell:prototype atItemIndex: x];
		box = [self snapRectToGrid: box];	// Does nothing if "force to grid" is off.
		
		BOOL		isSelected = [selectionSet containsObject:[NSNumber numberWithInt: x]];
		
		isSelected |= (dragDestItem == x);
		
		if( runtimeFlags.bits.drawSnappedRects && isSelected )
		{
			NSRect		indicatorBox = box;
			indicatorBox = [self forceRectToGrid: box];
			indicatorBox = [self flipRectsYAxis: indicatorBox];
			
			if( NSIntersectsRect( indicatorBox, rect ) )
				[self drawSnapGuideInRect: indicatorBox];
		}
		box = [self flipRectsYAxis: box];
		
		if( NSIntersectsRect( box, rect ) )
		{
			[prototype setHighlighted: isSelected];
			[prototype drawWithFrame:box inView:self];
		}
	}
}


/* A simple blue frame with slight white fill. You can also get a transparent
	version of the cell instead, if that's what you like. */

-(void)	drawSnapGuideInRect: (NSRect)box
{
  #if UKDISTVIEW_DRAW_FANCY_SNAP_GUIDES
	NSRect		drawBox = box;
	drawBox.origin.x = drawBox.origin.y = 0;
	NSImage*	snapGuideImg = [[[NSImage alloc] initWithSize: drawBox.size] autorelease];
	[snapGuideImg lockFocus];
		[prototype drawWithFrame: drawBox inView: self];
	[snapGuideImg unlockFocus];
	[snapGuideImg dissolveToPoint: box.origin fraction: 0.2];
  #else
	box = NSInsetRect( box, 2, 2 );
	box.origin.x += 0.5; box.origin.y += 0.5;	// Move them onto full pixels.
	[[[NSColor whiteColor] colorWithAlphaComponent:0.5] set];
	[NSBezierPath setDefaultLineWidth: 2.0];
	[NSBezierPath fillRect:box];
	[[[NSColor knobColor] colorWithAlphaComponent: 1.0] set];
	[NSBezierPath strokeRect:box];
  #endif
}


-(void)	drawSelectionRectForDrawRect: (NSRect)rect
{
	if( ![self useSelectionRect] )
		return;
		
	if( selectionRect.size.width > 0 && selectionRect.size.height > 0 )
	{
		NSRect		drawRect = selectionRect;
		drawRect.origin.x += 0.5; drawRect.origin.y += 0.5;		// Move them onto full pixels
	
		[[NSColor colorWithCalibratedWhite:0.5 alpha:0.3] set];
		[NSBezierPath fillRect:drawRect];
		[NSBezierPath setDefaultLineWidth: 1.0];
		[[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] set];
		[NSBezierPath strokeRect:drawRect];
	}
}


-(void)	drawDropHiliteForDrawRect: (NSRect)rect
{
	NSRect		drawRect = NSInsetRect( [self visibleRect], 1.5, 1.5 );
	
    [[[NSColor selectedControlColor] colorWithAlphaComponent: 0.5] set];
    [NSBezierPath setDefaultLineWidth: 3.0];
    [NSBezierPath strokeRect:drawRect];
    [NSBezierPath setDefaultLineWidth: 1.0];
}


// Draw this view's contents:
-(void)	drawRect: (NSRect)rect
{
    if( ![self dataSource] )
    {
        NSDrawGroove( [self bounds], rect );
        [@"UKDistributedView" drawAtPoint: NSMakePoint(8,20) withAttributes: [NSDictionary dictionary]];
    }
    if( flags.bits.drawsBackground )
		[self drawBackgroundInRect: rect];
	[self drawGridForDrawRect: rect];
    if( runtimeFlags.bits.drawDropHilite )
        [self drawDropHiliteForDrawRect: rect];
    if( [self dataSource] && ![self.dataSource respondsToSelector: @selector(distributedView:positionAtItemIndex:)] )
        [self drawCellsForDrawRect:rect];
	[self drawSelectionRectForDrawRect:rect];
}

-(void)	drawBackgroundInRect: (NSRect)box
{
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect: box];
}


-(BOOL)     itemIsVisible: (int)itemNb
{
	return [visibleItems containsObject: [NSNumber numberWithInt: itemNb]];
}


-(void) itemNeedsDisplay: (int)itemNb
{
	NSParameterAssert( itemNb >= 0 && itemNb < [[self dataSource] numberOfItemsInDistributedView: self] );
    
	NSRect  ibox = [self rectForItemAtIndex: itemNb];
	NSRect  box = [self flipRectsYAxis: ibox];
	
	BOOL	layerBased = [self.delegate respondsToSelector: @selector(distributedView:imageAtItemIndex:)];
	
	if( layerBased )
	{
		[CATransaction begin];
		[CATransaction setAnimationDuration: 0.0];
			CALayer*	containerLayer = [self.layer.sublayers objectAtIndex: itemNb];
			[containerLayer setFrame: box];
			CALayer*		imageLayer = [containerLayer.sublayers objectAtIndex: 0];
			CATextLayer*	textLayer = [containerLayer.sublayers objectAtIndex: 1];
			imageLayer.contents = [self.delegate distributedView: self imageAtItemIndex: itemNb];
			textLayer.string = [self.delegate distributedView: self titleAtItemIndex: itemNb];
			BOOL	isSelected = [selectionSet containsObject: [NSNumber numberWithInt: itemNb]];
			textLayer.foregroundColor = (isSelected ? [NSColor alternateSelectedControlTextColor] : [NSColor blackColor]).CGColor;
			textLayer.backgroundColor = (isSelected ? [NSColor alternateSelectedControlColor] : [NSColor whiteColor]).CGColor;
		[CATransaction commit];
	}
	else
	{
		if( !flags.bits.forceToGrid )	// If item image can move freely, invalidate that rect.
			[self setNeedsDisplayInRect: box];
		
		if( runtimeFlags.bits.drawSnappedRects || flags.bits.forceToGrid )	// If we force to grid, only invalidate grid position. If we show "snap" rects, invalidate grid position in addition to free one so we see item and "snap" indicator fully.
		{
			NSRect		indicatorBox = [self forceRectToGrid: ibox];
			indicatorBox = [self flipRectsYAxis: indicatorBox];
			[self setNeedsDisplayInRect: indicatorBox];
		}
	}
}


-(void) selectionSetNeedsDisplay
{
	[self itemSetNeedsDisplay: selectionSet];
}


-(void)	itemSetNeedsDisplay: (NSSet*)inSet
{
	NSEnumerator*   enny = [inSet objectEnumerator];
	NSNumber*		currIndex = nil;
	
	while( (currIndex = [enny nextObject]) )
		[self itemNeedsDisplay: [currIndex intValue]];
}

// Position is in flipped coordinates:
-(BOOL) itemIsVisibleAtPosition: (NSPoint)pos
{
    NSRect  currBox;
    
    currBox.size = cellSize;
    currBox.origin = pos;
    currBox = [self snapRectToGrid: currBox];
    
    BOOL isV = NSIntersectsRect( visibleItemRect, currBox );
    
    return isV;
}


// Rect is in item coordinates, i.e. flipped Y-axis compared to Quartz:
//	Call invalidateVisibleItemsCache before this if you are recacheing to get rid of the old items.
-(void) extendCacheByVisibleItemIndexesInRect: (NSRect)inBox startingAtIndex: (int)startIdx
{
	int		x = 0,
			count = [[self dataSource] numberOfItemsInDistributedView:self];
	NSRect  currBox;
	
	if( [delegate respondsToSelector: @selector(distributedViewDidStartCachingItems:)] )
		[delegate distributedViewDidStartCachingItems: self];
	
    BOOL    supportsToolTips = [[self dataSource] respondsToSelector: @selector(distributedView:toolTipForItemAtIndex:)];
	
	for( x = startIdx; x < count; x++ )
	{
		currBox = [self rectForItemAtIndex: x];
		if( NSIntersectsRect( currBox, inBox ) )	// Visible!
        {
            NSNumber*   iidx = [NSNumber numberWithInt: x];
			[visibleItems addObject: iidx];
            
            if( supportsToolTips )
            {
                currBox = [self flipRectsYAxis: currBox];
                [self addToolTipRect: currBox owner: self userData: (void*) x];
            }
        }
	}
	
	visibleItemRect = inBox;
	
	if( [delegate respondsToSelector: @selector(distributedViewWillEndCachingItems:)] )
		[delegate distributedViewWillEndCachingItems: self];
}


-(void) invalidateVisibleItemsCache
{
	visibleItemRect = NSZeroRect;
	[visibleItems removeAllObjects];
}


// -----------------------------------------------------------------------------
//  Moving and Drag and Drop:
// -----------------------------------------------------------------------------
#pragma mark Moving and Drag and Drop

/* -----------------------------------------------------------------------------
	initiateMove:
		There has been a mouse down, and now we want the mouseItem/selection
		set to be moved on subsequent mouseDragged events. This is old-style
		"live" dragging, not inter-application drag and drop.
	
	REVISIONS:
		2003-12-20	UK	Extracted from mouseDown so initiateDrag can call it.
   -------------------------------------------------------------------------- */

-(void) initiateMove
{
	[[self window] setAcceptsMouseMovedEvents:YES];
}


/* -----------------------------------------------------------------------------
	initiateDrag:
		There has been a mouse down, and now we want the mouseItem/selection
		set to be dragged using the Drag & drop protocol. Takes care of setting
		up the drag image etc. by querying the data source.
		
		If the drag fails due to unsupported data source calls or similar, this
		will cause a local old-style "live" move using initiateMove.
	
	REVISIONS:
		2003-12-20	UK	Created.
   -------------------------------------------------------------------------- */

-(void) initiateDrag: (NSEvent*)event
{
    NSMutableSet*   set = [NSMutableSet setWithArray: visibleItems];
    [set intersectSet: selectionSet];
	NSArray*		itemsArr = [set allObjects];
	NSPasteboard*   pb = [NSPasteboard pasteboardWithName: NSDragPboard];
	NSImage*		theDragImg = [self dragImageForItems: itemsArr
											event: event
											dragImageOffset: &dragStartImagePos];
	
	if( !theDragImg
		|| ![[self dataSource] distributedView:self writeItems:itemsArr toPasteboard: pb] )
	{
		[self initiateMove];
		return;
	}
	
	[self addPositionsOfItems: itemsArr toPasteboard: pb];
	
	// Actually commence the drag:
	[self dragImage:theDragImg at:dragStartImagePos offset:NSMakeSize(0,0)
				event:event pasteboard:pb source:self slideBack:YES];
}


/* -----------------------------------------------------------------------------
	addPositionsOfItems:toPasteboard:
		Determine the positions of items (relative to the drag image's origin)
        and add them to the drag as an additional drag item. That way we can
		position the items exactly where their drag image was dropped, when
		someone drags between two UKDistributedViews.
	
	REVISIONS:
		2003-12-20	UK	Created.
   -------------------------------------------------------------------------- */

// I'll leave this in to remind myself how annoying it was to store a point in a plist:
//#define PLIST_POINT(p)    [NSValue valueWithPoint: p]
//#define PLIST_POINT(p)    NSStringFromPoint(p)
#define PLIST_POINT(p)      [NSData dataWithBytes: &p length: sizeof(NSPoint)]
//#define PLIST_POINT_X(p)  [p pointValue]
//#define PLIST_POINT_X(p)  NSPointFromString(p)
#define PLIST_POINT_X(p)    (*(NSPoint*) [p bytes])

-(void) addPositionsOfItems: (NSArray*)indexes toPasteboard: (NSPasteboard*)pboard
{
	
	NSEnumerator*   enny = [indexes objectEnumerator];
	NSNumber*		currIndex = nil;
	NSMutableArray* files = [NSMutableArray arrayWithCapacity: [indexes count]];
	BOOL			layerBased = [self.dataSource respondsToSelector: @selector(distributedView:positionAtItemIndex:)];
	
	// Build an array of our icon positions:
	while( (currIndex = [enny nextObject]) )
	{
		int						x = [currIndex intValue];
		NSRect					box;
		
		box.size = cellSize;
		
		if( layerBased )
			box.origin = [[self dataSource] distributedView: self positionAtItemIndex: x];
		else
			box.origin = [[self dataSource] distributedView: self positionForCell: nil
										atItemIndex: x];
		
		box = [self flipRectsYAxis: box];
		
		// Make position relative to drag image's loc:
		box.origin.x -= dragStartImagePos.x;
		box.origin.y -= dragStartImagePos.y;
		
		[files addObject: PLIST_POINT(box.origin)];
	}
	
	// Put it on the drag pasteboard:
	[pboard addTypes: [NSArray arrayWithObject: UKDistributedViewPositionsPboardType] owner: self];
	[pboard setPropertyList: files forType: UKDistributedViewPositionsPboardType];
}


/* -----------------------------------------------------------------------------
	positionsOfItemsOnPasteboard:forImagePosition:
		This is the opposite of addPositionsOfItems:toPasteboard: and gives you
        back the actual positions at which the individual items in the drag have
        been dropped.
	
	REVISIONS:
		2004-12-07	UK	Created.
   -------------------------------------------------------------------------- */

-(NSMutableArray*) positionsOfItemsOnPasteboard: (NSPasteboard*)pboard forImagePosition: (NSPoint)imgPos
{
    NSArray*        positions = [pboard propertyListForType: UKDistributedViewPositionsPboardType];
    NSEnumerator*   enny = [positions objectEnumerator];
    NSData*         currPosVal = nil;
    NSMutableArray* outPositions = [NSMutableArray array];
    NSRect          currBox;
    currBox.size = cellSize;
    imgPos = [self convertPoint: imgPos fromView: nil];
    
    while( (currPosVal = [enny nextObject]) )
    {
        currBox.origin = PLIST_POINT_X(currPosVal);
        
        currBox.origin.x += imgPos.x;
        currBox.origin.y += imgPos.y;
        currBox = [self flipRectsYAxis: currBox];
        
        if( flags.bits.snapToGrid || flags.bits.forceToGrid )
            currBox = [self forceRectToGrid: currBox];
        
        [outPositions addObject: [NSValue valueWithPoint: currBox.origin]];
    }
    
    return outPositions;
}


/* -----------------------------------------------------------------------------
	dragImageForItems:event:dragImageOffset:
		Paint a nice drag image of all our items being dragged.
	
	REVISIONS:
		2003-12-20	UK	Created.
   -------------------------------------------------------------------------- */

-(NSImage*) dragImageForItems:(NSArray*)dragIndexes event:(NSEvent*)dragEvent
				dragImageOffset:(NSPointPointer)dragImageOffset
{
	NSRect			extents = [self rectAroundItems: dragIndexes];
	NSEnumerator*   enny = [dragIndexes objectEnumerator];
	NSNumber*		currIndex = nil;
	NSImage*		img = [[[NSImage alloc] initWithSize: extents.size] autorelease];
	
	[img lockFocus];
	
	// Draw each one: 
	while( (currIndex = [enny nextObject]) )
	{
		NSRect		currBox;
		int			x = [currIndex intValue];
		
		currBox.size = cellSize;
		currBox.origin = [[self dataSource] distributedView: self positionForCell:prototype
										atItemIndex: x];
        currBox = [self flipRectsYAxis: currBox];
        currBox.origin.x -= extents.origin.x;
        currBox.origin.y -= extents.origin.y;
        
        [prototype setHighlighted: YES];
        [prototype drawWithFrame:currBox inView:self];
	}
	
	[img drawAtPoint:NSZeroPoint fromRect:NSMakeRect(0.0, 0.0, extents.size.width, extents.size.height)
		   operation:NSCompositeCopy fraction:.5];
	
	[img unlockFocus];
	
	*dragImageOffset = extents.origin;
	
	return img;
}


/* -----------------------------------------------------------------------------
	draggingEntered:
		Someone moved a dragged item over our view, and it's of a flavor
		we've been declared to understand. Return what operation we want to
		do.
	
	REVISIONS:
		2003-12-21	UK	Created.
   -------------------------------------------------------------------------- */

-(NSDragOperation)  draggingEntered:(id <NSDraggingInfo>)sender
{
	NSDragOperation		retVal;
	
	if( dragDestItem != -1 )
		[self itemNeedsDisplay: dragDestItem];
	
	NSPoint viewPoint = [self convertPoint:[sender draggingLocation] fromView:nil];
	dragDestItem = [self getItemIndexAtPoint:viewPoint];
	
	retVal = [[self dataSource] distributedView:self validateDrop:sender
						proposedItem: &dragDestItem];
    if( retVal != NSDragOperationNone )
    {
        runtimeFlags.bits.drawDropHilite = YES;
        [self setNeedsDisplay: YES];
	}
    
	return retVal;
}


/* -----------------------------------------------------------------------------
	draggingUpdated:
		Someone moved a dragged item over our view, and it's of a flavor
		we've been declared to understand. Return what operation we want to
		do.
	
	REVISIONS:
		2003-12-21	UK	Created.
   -------------------------------------------------------------------------- */

-(NSDragOperation)  draggingUpdated:(id <NSDraggingInfo>)sender
{
	NSDragOperation		retVal;
	
	if( dragDestItem != -1 )
		[self itemNeedsDisplay: dragDestItem];
	dragDestItem = [self getItemIndexAtPoint:[self convertPoint:[sender draggingLocation] fromView:nil]];
	
	retVal = [[self dataSource] distributedView:self validateDrop:sender
						proposedItem: &dragDestItem];
	if( dragDestItem != -1 )
		[self itemNeedsDisplay: dragDestItem];
	
	return retVal;
}


/* -----------------------------------------------------------------------------
	draggingExited:
		The mouse has left this object during a drag to drop an item elsewhere.
        Reset all drag-related vars so we can start freshly on the next drag.
	
	REVISIONS:
        2004-12-02  UK  Fixed comment, made this clear drop highlight.
		2003-12-21	UK	Created.
   -------------------------------------------------------------------------- */

-(void)  draggingExited:(id <NSDraggingInfo>)sender
{
	dragDestItem = -1;
	mouseItem = -1;
    
    runtimeFlags.bits.drawDropHilite = NO;
    [self setNeedsDisplay: YES];
}


/* -----------------------------------------------------------------------------
	performDragOperation:
		The user dropped something in this window. Let the data source handle
        the drop and clean up in preparation for future drags.
	
	REVISIONS:
		2003-12-21	UK	Created.
   -------------------------------------------------------------------------- */

-(BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
	BOOL retVal = [[self dataSource] distributedView:self acceptDrop:sender
							onItem:dragDestItem];
							
	dragDestItem = -1;
	mouseItem = -1;
    
    runtimeFlags.bits.drawDropHilite = NO;
    [self invalidateVisibleItemsCache];
    [self setNeedsDisplay: YES];
	
	return retVal;
}


/* -----------------------------------------------------------------------------
	draggedImage:endedAt:operation:
		React to special drags, like on trash.
	
	REVISIONS:
		2004-12-07	UK	Created.
   -------------------------------------------------------------------------- */

-(void) draggedImage: (NSImage*)image endedAt: (NSPoint)screenPoint operation: (NSDragOperation)operation
{
    if( [[self dataSource] respondsToSelector: @selector(distributedView:dragEndedWithOperation:)] )
        [[self dataSource] distributedView: self dragEndedWithOperation: operation];
}


/* -----------------------------------------------------------------------------
	draggingSourceOperationMaskForLocal:
		Forward this DnD message to our delegate.
	
	REVISIONS:
		2003-12-20	UK	Created.
   -------------------------------------------------------------------------- */

-(NSDragOperation)  draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	if( [[self dataSource] respondsToSelector:@selector(distributedView:draggingSourceOperationMaskForLocal:)] )
		return [[self dataSource] distributedView:self draggingSourceOperationMaskForLocal: isLocal];
	else
		return NSDragOperationNone;
}


/* -----------------------------------------------------------------------------
	mouseDown:
		Find whatever was clicked and start tracking drags/the selection rect
        as needed.
	
	REVISIONS:
		2007-04-06	UK	Changed to ignore shift key if allowMultipleSelection
						is off.
		2006-07-06	UK	Fixed to unselect all items on mouseDown when we only
						allow a single selection.
		2004-12-02	UK	Documented.
   -------------------------------------------------------------------------- */

-(void)	mouseDown: (NSEvent*)event
{
	BOOL	layerBased = [self.dataSource respondsToSelector: @selector(distributedView:positionAtItemIndex:)];
	lastPos = [event locationInWindow];
	lastPos = [self convertPoint:lastPos fromView:nil];
    mouseItem = [self getItemIndexAtPoint: lastPos];
	
    [[self window] endEditingFor: prototype];
    
	if( mouseItem == -1 )	// No item hit? Remove selection and start mouse tracking for selection rect.
	{
		if( !flags.bits.allowsEmptySelection )	// Empty selection not allowed? Can't unselect, and since rubber band needs to reset the selection, can't do selection rect either.
			return;
		NSSet*	oldSelection = [[selectionSet copy] autorelease];
		[selectionSet removeAllObjects];
		[self itemSetNeedsDisplay: oldSelection];    // Possible threading deadlock here ... ?
		[[NSNotificationCenter defaultCenter] postNotificationName: UKDistributedViewSelectionDidChangeNotification
												object: self];
	}
	else    // An item was clicked?
	{
		if( [event clickCount] % 2 == 0 )   // Double click!
		{
			if( [prototype isEditable] )    // Editable item double-clicked?
			{
				NSRect		itemBox = [self rectForItemAtIndex: mouseItem];
				itemBox = [self flipRectsYAxis: itemBox];
				itemBox = [prototype titleRectForBounds: itemBox];
				if( NSPointInRect( lastPos, itemBox ) ) // Title of editable item double-clicked? User wants to edit!
				{
					[self editItemIndex: mouseItem withEvent:event select:YES];
					return;
				}
			}
			
			if( [delegate respondsToSelector: @selector(distributedView:cellDoubleClickedAtItemIndex:)] )
				[delegate distributedView:self cellDoubleClickedAtItemIndex:mouseItem];
			return;
		}
		
		if( !flags.bits.allowsMultipleSelection )
			[self deselectAll: nil];
		
		if( ([event modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask && flags.bits.allowsMultipleSelection )    // Single click but shift key held down?
		{
			// If shift key is down, toggle this item's selection status
			if( [selectionSet containsObject:[NSNumber numberWithInt: mouseItem]] )
			{
				[selectionSet removeObject:[NSNumber numberWithInt: mouseItem]];
				[[NSNotificationCenter defaultCenter] postNotificationName: UKDistributedViewSelectionDidChangeNotification
														object: self];
				[self itemNeedsDisplay: mouseItem];
				return;	// Don't drag unselected item.
			}
			else
			{
				if( ![delegate respondsToSelector: @selector(distributedView:shouldSelectItemIndex:)]
					|| [delegate distributedView:self shouldSelectItemIndex: mouseItem] )
				{
					[selectionSet addObject:[NSNumber numberWithInt: mouseItem]];
					if( [delegate respondsToSelector: @selector(distributedView:didSelectItemIndex:)] )
						[delegate distributedView:self didSelectItemIndex: mouseItem];
					[self itemNeedsDisplay: mouseItem];
					[[NSNotificationCenter defaultCenter] postNotificationName: UKDistributedViewSelectionDidChangeNotification
							object: self];
				}
				else
					return; // Bail. Delegate told us not to select this item.
			}
		}
		else	// If shift isn't down, make sure we're selected and drag:
		{
			if( ![delegate respondsToSelector: @selector(distributedView:shouldSelectItemIndex:)]
				|| [delegate distributedView:self shouldSelectItemIndex: mouseItem] )
			{
				if( ![selectionSet containsObject:[NSNumber numberWithInt: mouseItem]] )
				{	
					NSSet*	oldSelection = [[selectionSet copy] autorelease];
					[selectionSet removeAllObjects];
					[self itemSetNeedsDisplay: oldSelection];    // Possible threading deadlock here ... ?
					[selectionSet addObject:[NSNumber numberWithInt: mouseItem]];
					if( [delegate respondsToSelector: @selector(distributedView:didSelectItemIndex:)] )
						[delegate distributedView:self didSelectItemIndex: mouseItem];
					[[NSNotificationCenter defaultCenter] postNotificationName: UKDistributedViewSelectionDidChangeNotification
							object: self];
					[self itemNeedsDisplay: mouseItem];
				}
			}
			else
				return; // Bail. Delegate told us not to select this item.
		}
	}
	
	if( [self useSelectionRect] || mouseItem != -1 )	// Don't start tracking if we're dealing with a selection rect and we're not allowed to do a selection rect.
		[self initiateMove];
}


/* -----------------------------------------------------------------------------
	mouseDragged:
		This is where we handle "live" old-style "moves" as well as the
		selection rectangles.
	
	REVISIONS:
		2007-04-06	UK	Made this do nothing in the case where selection rect
						is off and no item was clicked, so clicks in the empty
						area don't cause item drags.
		2006-07-06	UK	Fixed to again allow having old-style "moves" that don't
						turn into DnD drags when we leave the window.
		2003-12-20	UK	Documented.
   -------------------------------------------------------------------------- */

-(void)	mouseDragged:(NSEvent *)event
{
	BOOL				layerBased = [self.dataSource respondsToSelector: @selector(distributedView:positionAtItemIndex:)];
	NSPoint				eventLocation = [event locationInWindow];
	eventLocation = [self convertPoint:eventLocation fromView:nil];
	
	if( mouseItem == -1 && [self useSelectionRect] )	// No item hit? Selection rect!
	{
		[self setNeedsDisplayInRect: NSInsetRect(selectionRect, -1, -1)];	// Invalidate old position.
		
		// Build rect:
		selectionRect.origin.x = lastPos.x;
		selectionRect.origin.y = lastPos.y;
		selectionRect.size.width = eventLocation.x -selectionRect.origin.x;
		selectionRect.size.height = eventLocation.y -selectionRect.origin.y;
		
		// Flip it if we have negative width or height:
		if( selectionRect.size.width < 0 )
		{
			selectionRect.size.width *= -1;
			selectionRect.origin.x -= selectionRect.size.width;
		}
		if( selectionRect.size.height < 0 )
		{
			selectionRect.size.height *= -1;
			selectionRect.origin.y -= selectionRect.size.height;
		}
		
		[self setNeedsDisplayInRect: NSInsetRect(selectionRect,-1,-1)];	// Invalidate new position.

		// Select items in the rect:
		[self selectItemsInRect:selectionRect byExtendingSelection:NO];
	}
	else if( flags.bits.dragMovesItems && mouseItem != -1 )	// Item hit? Drag the item, if we're set up that way:
	{
		BOOL	dataSourceDoesRemoteDrags = [[self dataSource] respondsToSelector: @selector(distributedView:writeItems:toPasteboard:)];
		// If mouse is inside our rect, drag locally:
		if( !dataSourceDoesRemoteDrags || (NSPointInRect( eventLocation, [self visibleRect] ) && flags.bits.dragLocally) )
		{
			NSEnumerator*		enummy = [selectionSet objectEnumerator];
			NSNumber*			currentItemNum;
		
			if( ((([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask && !flags.bits.snapToGrid)		// snapToGrid is toggled using command key.
					|| (([event modifierFlags] & NSCommandKeyMask) != NSCommandKeyMask && flags.bits.snapToGrid))
					&& !flags.bits.forceToGrid
					&& flags.bits.showSnapGuides )
				runtimeFlags.bits.drawSnappedRects = YES;
			
			while( (currentItemNum = [enummy nextObject]) )
			{
				NSPoint		pos;
				int			x = [currentItemNum intValue];
				
				if( layerBased )
					pos = [[self dataSource] distributedView:self positionAtItemIndex: x];
				else
					pos = [[self dataSource] distributedView:self positionForCell:nil atItemIndex: x];
				pos.x += [event deltaX];
				pos.y += [event deltaY];
				
				if( !layerBased )
					[self itemNeedsDisplay: x]; // Invalidate old position.
				[[self dataSource] distributedView:self setPosition:pos forItemIndex: x];
				[self itemNeedsDisplay: x]; // Invalidate new position/update layers to new position.
			}
			[[self window] invalidateCursorRectsForView:self];
			
		}
		else if( dataSourceDoesRemoteDrags )	// Left our rect? Use system drag & drop service instead:
			[self initiateDrag: event];
	}
}


/* -----------------------------------------------------------------------------
	mouseUp:
		A local drag or selection rectangle drag finished. This also ends
        editing in the previous cell and sends cellClicked: messages.
	
	REVISIONS:
		2006-07-06	UK	Fixed to trigger not just on move, but also when we're
						snapping to grid.
		2004-12-02	UK	Documented.
   -------------------------------------------------------------------------- */

-(void)	mouseUp: (NSEvent*)event
{
	[[self window] setAcceptsMouseMovedEvents:NO];
	
	if( mouseItem == -1 )	// No item hit? Must be selection rect. Reset that.
	{
		[self setNeedsDisplayInRect: NSInsetRect(selectionRect,-1,-1)];	// Make sure old selection rect is removed.
		selectionRect.size.width = selectionRect.size.height = 0;
	}
	else	// An item hit? Must be end of drag or so:
	{
		NSPoint		eventLocation = [event locationInWindow];
		NSRect		box = [self rectForItemAtIndex:mouseItem];
		
		eventLocation = [self convertPoint:eventLocation fromView:nil];
		box = [self snapRectToGrid: box];
		box = [self flipRectsYAxis: box];
	
		if( NSPointInRect(eventLocation,box) && (((lastPos.x == eventLocation.x) && (lastPos.y == eventLocation.y)) || !flags.bits.dragMovesItems) )	// Wasn't a drag.
		{
			[self cellClicked:self];
		}
		lastPos = eventLocation;
		mouseItem = -1;
		
		if( flags.bits.dragMovesItems && (([event deltaX] != 0 || [event deltaY] != 0) || flags.bits.snapToGrid) )	// Item hit? Drag the item, if we're set up that way:
		{
			NSEnumerator*		enummy = [selectionSet objectEnumerator];
			NSNumber*			currentItemNum;
			BOOL				layerBased = [self.dataSource respondsToSelector: @selector(distributedView:positionAtItemIndex:)];
		
			runtimeFlags.bits.drawSnappedRects = NO;
			
			while( (currentItemNum = [enummy nextObject]) )
			{
				NSRect		ibox;
				
				if( layerBased )
				{
					ibox.origin = [[self dataSource] distributedView:self positionAtItemIndex: [currentItemNum intValue]];
				}
				else
				{
					ibox.origin = [[self dataSource] distributedView:self positionForCell:nil atItemIndex: [currentItemNum intValue]];
					[self setNeedsDisplayInRect: [self flipRectsYAxis: ibox]];
				}
				
				ibox.origin.x += [event deltaX];
				ibox.origin.y += [event deltaY];
				
				// Apply grid to item, if necessary:
				if( (([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask && !flags.bits.snapToGrid)		// snapToGrid is toggled using command key.
					|| (([event modifierFlags] & NSCommandKeyMask) != NSCommandKeyMask && flags.bits.snapToGrid) 
					|| flags.bits.forceToGrid )
				{
					
					ibox = [self forceRectToGrid: ibox];
					if( !layerBased )
						[self itemNeedsDisplay: [currentItemNum intValue]];
				}
				
				[[self dataSource] distributedView:self setPosition:ibox.origin forItemIndex: [currentItemNum intValue]];
				if( !layerBased )
					[self itemNeedsDisplay: [currentItemNum intValue]];
			}
		}
	}
	
	[self contentSizeChanged];
	
	if( [self acceptsFirstResponder] && ![[self prototype] isEditable] )	// TODO: We should check whether the cell actually *is* being edited here!
		[[self window] makeFirstResponder:self];
}


/* -----------------------------------------------------------------------------
	acceptsFirstMouse:
		This view will use clicks that bring it to the front.
	
	REVISIONS:
		2004-12-01	UK	Documented.
   -------------------------------------------------------------------------- */

-(BOOL) acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}


// -----------------------------------------------------------------------------
//  Callbacks:
// -----------------------------------------------------------------------------
#pragma mark Callbacks

-(NSString*)    view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)userData
{
    int     x = (int) userData;
    
    if( [[self dataSource] respondsToSelector: @selector(distributedView:toolTipForItemAtIndex:)] )
        return [[self dataSource] distributedView: self toolTipForItemAtIndex: x];
    else
        return @"";
}


-(IBAction)	cellClicked: (id)sender
{
	if( [delegate respondsToSelector: @selector(distributedView:cellClickedAtItemIndex:)] )
		[delegate distributedView:self cellClickedAtItemIndex: mouseItem];
}


// -----------------------------------------------------------------------------
//  Data Source Management:
// -----------------------------------------------------------------------------
#pragma mark Data Source Management

-(void)	reloadData
{
	[self invalidateVisibleItemsCache];
	[self updateSelectionSet];
	[[self window] invalidateCursorRectsForView:self];
	[self contentSizeChanged];
	if( [self.delegate respondsToSelector: @selector(distributedView:positionAtItemIndex:)] )
		[self rebuildLayersInRect: self.bounds];
	else
		[self setNeedsDisplay:YES];
    oldItemCount = [delegate numberOfItemsInDistributedView: self];
}


-(void)	noteNumberOfItemsChanged
{
	// try to preserve the selection set here, this is most likely called when the current set
	// of items has changed (but not to a different set)
	
    int ic = [delegate numberOfItemsInDistributedView: self];
	NSMutableSet* sel = selectionSet;
    selectionSet = [[NSMutableSet alloc] init];
    if( ic > oldItemCount )
    {
        [self extendCacheByVisibleItemIndexesInRect: visibleItemRect startingAtIndex: oldItemCount];
        [[self window] invalidateCursorRectsForView: self];
        [self contentSizeChanged];
        [self setNeedsDisplay:YES];
    }
    else
        [self reloadData];
	[selectionSet autorelease];
    selectionSet = sel;
	[self updateSelectionSet];
    oldItemCount = [delegate numberOfItemsInDistributedView: self];
}


-(void)	contentSizeChanged
{
	if( flags.bits.sizeToFit )
	{
		NSRect newFrame = [self computeFrame];
		
		NSScrollView*	sv = [self enclosingScrollView];
		NSPoint newScroll = [sv documentVisibleRect].origin;

		// Adjust for change in size so window doesn't "scroll away":
		NSRect		oldFrame = [self frame];
		NSSize		contentSize = [sv contentSize];
		
		if (newFrame.size.width > contentSize.width || newFrame.size.height > contentSize.height)
		{
			// if the new frame is bigger than the content size (i.e. it grew), adjust scroll
			// position so that it maintains the same relative position.  Note that this only
			// has to adjust the y position (because of the bottom->top coordinate orientation).
			
			newScroll.y += newFrame.size.height - oldFrame.size.height;
		}
		else
		{
			// new frame is entirely inside the scroll view
			newScroll = NSZeroPoint;
		}
		
		// Resize and maintain scroll position:
		if( !NSEqualRects(oldFrame, newFrame) )
		{
			[self setFrame:newFrame];
			//NSLog(@"newscroll: %f, %f newFrame: %@\n", newScroll.x, newScroll.y,NSStringFromRect( newFrame ));
			[[sv contentView] scrollToPoint: newScroll];
			[sv reflectScrolledClipView: [sv contentView]];

			[self setNeedsDisplay:YES];
			[sv setNeedsDisplay:YES];
		}
	}
	[[self window] invalidateCursorRectsForView:self];
}


// -----------------------------------------------------------------------------
//  Scrolling
// -----------------------------------------------------------------------------
#pragma mark Scrolling

/* -----------------------------------------------------------------------------
	rescrollItems:
		Move the items, maintaining their relative positions, so the topmost
        and leftmost items are positioned at exactly contentInset pixels from
        the top left.
	
	REVISIONS:
		2004-12-02	UK	Fixed comment, moved to be with other scroll methods.
   -------------------------------------------------------------------------- */

-(IBAction)	rescrollItems: (id)sender
{
	int		x, count = [[self dataSource] numberOfItemsInDistributedView:self];
	int		leftPos = INT_MAX, topPos = INT_MAX,
			leftoffs, topoffs;
	
	//  Find topmost and leftmost positions of our items:
	for( x = 0; x < count; x++ )
	{
		NSRect		box = [self rectForItemAtIndex:x];

		if( box.origin.x < leftPos )
			leftPos = box.origin.x;
		if( box.origin.y < topPos )
			topPos = box.origin.y;
	}

	leftoffs = contentInset -leftPos;
	topoffs = contentInset -topPos;
	
	// Now reposition all our items:
	BOOL			layerBased = [self.dataSource respondsToSelector: @selector(distributedView:positionAtItemIndex:)];
	for( x = 0; x < count; x++ )
	{
		NSPoint		pos = NSZeroPoint;
		if( layerBased )
			pos = [[self dataSource] distributedView:self positionAtItemIndex:x];
		else
			pos = [[self dataSource] distributedView:self positionForCell:nil atItemIndex:x];
		pos.x += leftoffs;
		pos.y += topoffs;
		[[self dataSource] distributedView:self setPosition:pos forItemIndex:x];
	}
	
	[[self window] invalidateCursorRectsForView:self];
	[self contentSizeChanged];
	if( !layerBased )
		[self setNeedsDisplay:YES];
}



/* -----------------------------------------------------------------------------
	scrollByX:y:
		Scroll our containing scroll view by a certain distance.
        
        Calls scrollToPoint: to do the actual work.
	
	REVISIONS:
		2004-12-01	UK	Copied from David Rozga's modifications.
   -------------------------------------------------------------------------- */

-(void) scrollByX: (float)dx y: (float)dy
{
	NSScrollView*	sv = [self enclosingScrollView];
	NSPoint         scrollPoint = [sv documentVisibleRect].origin;
    
	scrollPoint.x += dx;
	scrollPoint.y += dy;
    
	[self scrollToPoint: scrollPoint];
}


/* -----------------------------------------------------------------------------
	scrollToPoint:
		Scroll our containing scroll view to a certain location.
	
	REVISIONS:
		2004-12-01	UK	Copied from David Rozga's modifications.
   -------------------------------------------------------------------------- */

-(void) scrollToPoint:(NSPoint)p
{
	NSScrollView*	sv = [self enclosingScrollView];
	NSClipView*     clip = [sv contentView];
    
	p = [clip constrainScrollPoint:p];
	[clip scrollToPoint:p];
	[sv reflectScrolledClipView:clip];
    
	[self setNeedsDisplay:YES];
	[[self window] invalidateCursorRectsForView:self];
}


/* -----------------------------------------------------------------------------
	scrollItemToVisible:
		Scroll our containing scroll view so the specified item is visible.
        
        Calls scrollToPoint: to do the actual scrolling.
	
	REVISIONS:
		2004-12-02	UK	Copied from David Rozga's modifications, changed to use
                        NSParameterAssert instead of quietly returning.
   -------------------------------------------------------------------------- */

-(void) scrollItemToVisible: (int)index
{
	NSParameterAssert( index >= 0 && index < [[self dataSource] numberOfItemsInDistributedView: self] );

	NSScrollView*	sv = [self enclosingScrollView];
	NSRect          docRect = [sv documentVisibleRect];
	NSRect          itemRect = [self flipRectsYAxis:[self rectForItemAtIndex:index]];
	
	if( NSContainsRect( docRect, itemRect ) )   // Item already visible?
		return;                                 // Nothing to do.
	
    // Calc minimum distance we need to scroll to see the item:
	docRect.origin.x = NSMinX(itemRect) < NSMinX(docRect)
		? NSMinX(itemRect)
		: NSMinX(itemRect) - (NSWidth(docRect) - NSWidth(itemRect));
	
	docRect.origin.y = NSMinY(itemRect) < NSMinY(docRect)
		? NSMinY(itemRect)
		: NSMinY(itemRect) - (NSHeight(docRect) - NSHeight(itemRect));
    
    // Scroll!
	[self scrollToPoint: docRect.origin];
	//[sv setNeedsDisplay: YES];
}



-(void)viewDidMoveToSuperview
{
	// when this happens, we need to establish a base frame position/size
	if( flags.bits.sizeToFit )
	{
		[self setFrame:[self computeFrame]];
	}
}


-(void) setFrame: (NSRect) box
{
    [super setFrame: box];
    [self invalidateVisibleItemsCache]; // Make sure tool tips etc. are current.
}


-(NSRect)   computeFrame
{
	NSRect			box = [self bestRect];
	NSScrollView*	sv = [self enclosingScrollView];
	NSSize			svBox = [sv contentSize];

	// at least consume all of the scroll area
	if( svBox.width > box.size.width )
	{
		box.size.width = svBox.width;
	}
	
	if( svBox.height > box.size.height )
	{
		box.size.height = svBox.height;
	}
	
	return box;
}

/* -----------------------------------------------------------------------------
	resizeWithOldSuperviewSize:
		This view was resized. Make sure view is displayed properly.
	
	REVISIONS:
		2003-12-20	UK	Commented.
   -------------------------------------------------------------------------- */

-(void) resizeWithOldSuperviewSize:(NSSize)oldSize
{
	[super resizeWithOldSuperviewSize:oldSize];
	
	[self contentSizeChanged];
	
	// Set line and page values of owning scroll view:
    //  Note: page values are percentages expressed as fractions between 0.0 and
    //  1.0, while line values are in pixels.
	NSRect  visFrame = [self visibleRect],
            frame = [self frame];
	[[self enclosingScrollView] setVerticalPageScroll: NSHeight(visFrame)/NSHeight(frame)];
	[[self enclosingScrollView] setHorizontalPageScroll: NSWidth(visFrame)/NSWidth(frame)];
	[[self enclosingScrollView] setVerticalLineScroll: gridSize.height];
	[[self enclosingScrollView] setHorizontalLineScroll: gridSize.width];
}


// -----------------------------------------------------------------------------
//  Keyboard Navigation
// -----------------------------------------------------------------------------
#pragma mark Keyboard Navigation

-(BOOL)	acceptsFirstResponder
{
	return YES;
}

-(BOOL)	becomeFirstResponder
{
	[self selectionSetNeedsDisplay];
	return [super becomeFirstResponder];
}

-(BOOL)	resignFirstResponder
{
	[self selectionSetNeedsDisplay];
	return [super resignFirstResponder];
}


/* -----------------------------------------------------------------------------
	keyDown:
		Make sure insertText:, moveUp: etc. are called in response to key
        presses while this view has focus.
	
	REVISIONS:
		2004-12-01	UK	Created.
   -------------------------------------------------------------------------- */

-(void) keyDown: (NSEvent*)evt
{
    [self interpretKeyEvents: [NSArray arrayWithObject: evt]];
}


/* -----------------------------------------------------------------------------
	moveRight:
		Right arrow key has been pressed. Select the item next to the current
        selection.
	
	REVISIONS:
		2004-12-01	UK	Documented.
   -------------------------------------------------------------------------- */

-(void) moveRight:(id)sender
{
    int         selIndex = [self selectedItemIndex];
    if( selIndex < 0 )
        selIndex = 0;
	NSRect		flippedSearchBox = [self rectForItemAtIndex: selIndex];
	int			foundIndex = -1;
	
	flippedSearchBox.origin.x += cellSize.width;
	flippedSearchBox = NSInsetRect( flippedSearchBox, 8, 8 );
	
	if( NSIntersectsRect( flippedSearchBox, visibleItemRect ) )	// Try using cache.
		foundIndex = [self getItemIndexInRect: flippedSearchBox];
	else													// But otherwise fall back on full list.
		foundIndex = [self getUncachedItemIndexInRect: flippedSearchBox];
	
	if( foundIndex > -1 )
    {
		[self selectItem: foundIndex byExtendingSelection: NO];
        [self scrollItemToVisible: foundIndex];
    }
}


/* -----------------------------------------------------------------------------
	moveLeft:
		Left arrow key has been pressed. Select the item next to the current
        selection.
	
	REVISIONS:
		2004-12-01	UK	Documented.
   -------------------------------------------------------------------------- */

-(void) moveLeft:(id)sender
{
    int         selIndex = [self selectedItemIndex];
    if( selIndex < 0 )
        selIndex = [[self dataSource] numberOfItemsInDistributedView: self] -1;
	NSRect		flippedSearchBox = [self rectForItemAtIndex: selIndex];
	int			foundIndex = -1;
	
	flippedSearchBox.origin.x -= cellSize.width;
	flippedSearchBox = NSInsetRect( flippedSearchBox, 8, 8 );
	
	if( NSIntersectsRect( flippedSearchBox, visibleItemRect ) )	// Try using cache.
		foundIndex = [self getItemIndexInRect: flippedSearchBox];
	else													// But otherwise fall back on full list.
		foundIndex = [self getUncachedItemIndexInRect: flippedSearchBox];
	
	if( foundIndex > -1 )
    {
		[self selectItem: foundIndex byExtendingSelection: NO];
        [self scrollItemToVisible: foundIndex];
    }
}


/* -----------------------------------------------------------------------------
	moveUp:
		Up arrow key has been pressed. Select the item next to the current
        selection.
	
	REVISIONS:
		2004-12-01	UK	Documented.
   -------------------------------------------------------------------------- */

-(void) moveUp:(id)sender
{
    int         selIndex = [self selectedItemIndex];
    if( selIndex < 0 )
        selIndex = [[self dataSource] numberOfItemsInDistributedView: self] -1;
	NSRect		flippedSearchBox = [self rectForItemAtIndex: selIndex];
	int			foundIndex = -1;
	
	flippedSearchBox.origin.y -= cellSize.height;
	flippedSearchBox = NSInsetRect( flippedSearchBox, 8, 8 );
	
	if( NSIntersectsRect( flippedSearchBox, visibleItemRect ) )	// Try using cache.
		foundIndex = [self getItemIndexInRect: flippedSearchBox];
	else													// But otherwise fall back on full list.
		foundIndex = [self getUncachedItemIndexInRect: flippedSearchBox];
	
	if( foundIndex > -1 )
    {
		[self selectItem: foundIndex byExtendingSelection: NO];
        [self scrollItemToVisible: foundIndex];
    }
}


/* -----------------------------------------------------------------------------
	moveDown:
		Down arrow key has been pressed. Select the item next to the current
        selection.
	
	REVISIONS:
		2004-12-01	UK	Documented.
   -------------------------------------------------------------------------- */

-(void) moveDown:(id)sender
{
    int         selIndex = [self selectedItemIndex];
    if( selIndex < 0 )
        selIndex = 0;
	NSRect		flippedSearchBox = [self rectForItemAtIndex: selIndex];
	int			foundIndex = -1;
	
	flippedSearchBox.origin.y += cellSize.height;
	flippedSearchBox = NSInsetRect( flippedSearchBox, 8, 8 );
	
	if( NSIntersectsRect( flippedSearchBox, visibleItemRect ) )	// Try using cache.
		foundIndex = [self getItemIndexInRect: flippedSearchBox];
	else													// But otherwise fall back on full list.
		foundIndex = [self getUncachedItemIndexInRect: flippedSearchBox];
	
	if( foundIndex > -1 )
    {
		[self selectItem: foundIndex byExtendingSelection: NO];
        [self scrollItemToVisible: foundIndex];
    }
}



-(void) scrollPageDown:(id)sender
{
    [self scrollByX: 0 y: -NSHeight([self visibleRect])];
}


-(void) scrollPageUp:(id)sender
{
    [self scrollByX: 0 y: NSHeight([self visibleRect])];
}



/* -----------------------------------------------------------------------------
	insertTab:
		Tab key was hit. Select the next item in the list.
	
	REVISIONS:
		2004-12-01	UK	Created.
   -------------------------------------------------------------------------- */

-(void) insertTab: (id)sender
{
    int selItem = [self selectedItemIndex];
    selItem++;
    if( selItem >= [[self dataSource] numberOfItemsInDistributedView: self] )
        selItem = 0;
    
    [self selectItem: selItem byExtendingSelection: NO];
    [self scrollItemToVisible: selItem];
}


/* -----------------------------------------------------------------------------
	insertBacktab:
		Back-tab (shift-tab) key was hit. Select the previous item in the list.
	
	REVISIONS:
		2004-12-01	UK	Created.
   -------------------------------------------------------------------------- */

-(void) insertBacktab: (id)sender
{
    int selItem = [self selectedItemIndex];
    selItem--;
    if( selItem < 0 )
        selItem = [[self dataSource] numberOfItemsInDistributedView: self] -1;
    
    [self selectItem: selItem byExtendingSelection: NO];
    [self scrollItemToVisible: selItem];
}


/* -----------------------------------------------------------------------------
	insertText:
		User typed some text. Perform type-ahead selection.
	
	REVISIONS:
		2004-12-01	UK	Created.
   -------------------------------------------------------------------------- */

-(void) insertText: (id)insertString
{
    if( lastTypeAheadKeypress +UKDV_TYPEAHEAD_INTERVAL < [NSDate timeIntervalSinceReferenceDate] )
    {
        [typeAheadSearchStr release];
        typeAheadSearchStr = nil;
    }
    
    if( typeAheadSearchStr == nil )
        typeAheadSearchStr = [insertString mutableCopy];
    else
        [typeAheadSearchStr appendString: insertString];
    
	NSLog( @"typeaheadstring: %@", typeAheadSearchStr );
	
    int matchItem = [delegate distributedView:self itemIndexForString: typeAheadSearchStr
                                    options: NSCaseInsensitiveSearch | NSAnchoredSearch];
    if( matchItem != -1 )
    {
        [self selectItem: matchItem byExtendingSelection: NO];
        [self scrollItemToVisible: matchItem];
    }
    
    lastTypeAheadKeypress = [NSDate timeIntervalSinceReferenceDate];
}


// -----------------------------------------------------------------------------
//  Inline Editing:
// -----------------------------------------------------------------------------
#pragma mark Inline Editing

/* -----------------------------------------------------------------------------
	editItemIndex:withEvent:select:
		Open the field editor for a particular item's cell.
	
	REVISIONS:
		2004-12-01	UK	Documented.
   -------------------------------------------------------------------------- */

-(void) editItemIndex: (int)item withEvent:(NSEvent*)evt /*may be NIL*/ select:(BOOL)select
{
	NSParameterAssert( item >= 0 && item < [[self dataSource] numberOfItemsInDistributedView: self] );
    
	// Take over editor:
	if( ![[self window] makeFirstResponder: self] )		// Does it give up willingly?
		[[self window] endEditingFor: nil];				// Otherwise, force field editor to give up and reset it.
	
	// Remember who we're messing with:
	editedItem = item;

	// Set up our cell for display:
    NSRect		cellFrame = [self rectForItemAtIndex: editedItem];
    cellFrame = [self flipRectsYAxis: cellFrame];
	
    [[self dataSource] distributedView: self positionForCell: prototype
					atItemIndex: editedItem];
	
	// Fetch us one of them new-fangled field editors:
	NSText  *baseEditor = [[self window] fieldEditor:YES forObject: prototype];
    NSText  *fieldEditor = [prototype setUpFieldEditorAttributes: baseEditor];
	
	if( select )
	{
		// Get the object value as a string so we can measure it:
		id				oVal = [prototype objectValue];
		NSString*		val = nil;
		if( [oVal isKindOfClass: [NSString class]] )
			val = oVal;
		else
			val = [oVal stringValue];
		
		// Select the string and open a field editor for it:
		[prototype selectWithFrame: cellFrame inView: self
				editor: fieldEditor delegate:self
				start: 0 length: [val length] ];
	}
	
	// Actually start editing:
	[prototype editWithFrame: cellFrame inView: self
			editor: fieldEditor delegate: self event: evt];
	
	//[self itemNeedsDisplay: editedItem];
}


/* -----------------------------------------------------------------------------
	textDidEndEditing:
		Clean up after the editor has been closed.
	
	REVISIONS:
		2004-12-01	UK	Documented.
   -------------------------------------------------------------------------- */

-(void) textDidEndEditing: (NSNotification*)aNotification
{
    NSText      *fieldEditor = [aNotification object];
    NSString    *string = [[[fieldEditor string] copy] autorelease];
    NSRect      cellBox = [self rectForItemAtIndex: editedItem];
    cellBox = [self flipRectsYAxis: cellBox];

    // Finish the edit:
    [fieldEditor setFrame: NSZeroRect];
	[[self window] endEditingFor: prototype];
    [prototype endEditing: fieldEditor];
    //cellBox = [prototype titleRectForBounds: cellBox];
    //[prototype resetCursorRect: cellBox inView: self];
    
    // I'm outta ideas what I can do to remove the cell's cursor rect:
	//[fieldEditor setHidden: YES];
	//[prototype setEditable: NO];
    
	/*[[self window] makeFirstResponder: self];
 	[[self window] invalidateCursorRectsForView: self];	
 	[[self window] invalidateCursorRectsForView: fieldEditor];	
  	[[self window] discardCursorRects];
  	[[self window] resetCursorRects];
  	[fieldEditor discardCursorRects];*/

    if( string )
    {
		if( [[self dataSource] respondsToSelector: @selector(distributedView:setObjectValue:forItemIndex:)] )
		{
			[[self dataSource] distributedView: self
						setObjectValue: string
						forItemIndex: editedItem];
			[self itemNeedsDisplay: editedItem];
		}
		editedItem = -1;
    }
}


-(void) resetCursorRects
{
    // Anything else I can try to get my NSCell to remove its cursor rectangle?
    [self discardCursorRects];
    [self addCursorRect: [self bounds] cursor: [NSCursor arrowCursor]];
    
    if( editedItem != -1 )
    {
        NSRect      cellBox = [self rectForItemAtIndex: editedItem];
        cellBox = [self flipRectsYAxis: cellBox];
        cellBox = [prototype titleRectForBounds: cellBox];

        [prototype resetCursorRect: cellBox inView: self];
    }
    else
        ;/*[prototype resetCursorRect: [self frame] inView: self];*/ // tried NSZeroRect here, too...
}

#pragma mark Live Resize

-(void)	viewWillStartLiveResize
{
	[self setNeedsDisplay: YES];
}


-(void)	viewDidEndLiveResize
{
	[self setNeedsDisplay: YES];
}


#pragma mark Layer-based tables

-(void) rebuildLayersInRect: (NSRect)rect
{
	/* This rect isn't in our cache?
		Redo the cache, including 5 item heights above/below and 5 item widths
		left/right beyond what is currently visible: */
	if( !NSContainsRect( visibleItemRect, [self flipRectsYAxis: rect] ) )
	{
		NSRect		cacheRect = NSInsetRect( [self visibleRect], cellSize.width *-(UKDISTVIEW_INVIS_ITEMS_CACHE_COUNT *2), cellSize.height *-(UKDISTVIEW_INVIS_ITEMS_CACHE_COUNT *2) );
		[self invalidateVisibleItemsCache];
		[self extendCacheByVisibleItemIndexesInRect: [self flipRectsYAxis: cacheRect] startingAtIndex: 0];
	}
	
	// Now use the cache to generate layers for all visible items:
	NSEnumerator*   indexEnny = [visibleItems objectEnumerator];
	NSNumber*		currIndex = nil;
	int				icount = [[self dataSource] numberOfItemsInDistributedView: self];
	
	self.wantsLayer = YES;
	self.layer.sublayers = @[];
	
	//NSLog(@"count visible: %d",[visibleItems count]);
	
	while( (currIndex = [indexEnny nextObject]) )
	{
		NSRect		box = NSMakeRect( 0,0, cellSize.width,cellSize.height );
		int			x = [currIndex intValue];
		
		if( x > icount )
			continue;

		box.origin = [[self dataSource] distributedView: self positionAtItemIndex: x];
		box = [self snapRectToGrid: box];	// Does nothing if "force to grid" is off.
		NSImage*	img = [[self dataSource] distributedView: self imageAtItemIndex: x];
		NSString*	title = [[self dataSource] distributedView: self titleAtItemIndex: x];
		
		BOOL		isSelected = [selectionSet containsObject:[NSNumber numberWithInt: x]];
		
		isSelected |= (dragDestItem == x);
		
		if( runtimeFlags.bits.drawSnappedRects && isSelected )
		{
			NSRect		indicatorBox = box;
			indicatorBox = [self forceRectToGrid: box];
			indicatorBox = [self flipRectsYAxis: indicatorBox];
			
			if( NSIntersectsRect(indicatorBox, rect) )
			{
				CALayer*	snapGuideLayer = [CALayer layer];
				snapGuideLayer.frame = indicatorBox;
				snapGuideLayer.contents = img;
				snapGuideLayer.opacity = 0.7;
				snapGuideLayer.contentsGravity = kCAGravityResizeAspect;
				[self.layer addSublayer: snapGuideLayer];
			}
		}
		box = [self flipRectsYAxis: box];
		
		if( NSIntersectsRect(box, rect) )
		{
			CALayer*	containerLayer = [CALayer layer];
			containerLayer.frame = box;
			containerLayer.masksToBounds = YES;
			containerLayer.autoresizingMask = kCALayerMaxXMargin | kCALayerMinYMargin;
//			if( isSelected )
//			{
//				containerLayer.borderWidth = 1;
//				containerLayer.borderColor = [NSColor whiteColor].CGColor;
//				containerLayer.backgroundColor = [NSColor lightGrayColor].CGColor;
//			}
			
			CALayer*	imageLayer = [CALayer layer];
			NSRect		imageRect = box;
			imageRect.size.width /= 2;
			imageRect.size.height /= 2;
			imageRect.origin.y = box.size.height / 4;
			imageRect.origin.x = (box.size.width -imageRect.size.width) /2;
			
			imageLayer.frame = imageRect;
			imageLayer.contents = img;
			imageLayer.contentsGravity = kCAGravityResizeAspect;
//			imageLayer.borderWidth = 2;
//			imageLayer.borderColor = [NSColor cyanColor].CGColor;
			[containerLayer addSublayer: imageLayer];
			
			NSRect			labelRect = box;
			labelRect.origin = NSZeroPoint;
			labelRect.size.height /= 4;
			CATextLayer*	textLayer = [CATextLayer layer];
			textLayer.frame = labelRect;
			textLayer.string = title;
			textLayer.truncationMode = kCATruncationMiddle;
			textLayer.alignmentMode = kCAAlignmentCenter;
//			textLayer.borderWidth = 2;
			textLayer.fontSize = [NSFont systemFontSize];
			textLayer.font = [NSFont systemFontOfSize: [NSFont systemFontSize]];
			textLayer.cornerRadius = labelRect.size.height / 3;
			textLayer.contentsGravity = kCAGravityCenter;
			if( isSelected )
			{
				textLayer.foregroundColor = [NSColor alternateSelectedControlTextColor].CGColor;
				textLayer.backgroundColor = [NSColor alternateSelectedControlColor].CGColor;
//				containerLayer.borderColor = [NSColor keyboardFocusIndicatorColor].CGColor;
			}
			else
			{
				textLayer.foregroundColor = [NSColor blackColor].CGColor;
				textLayer.backgroundColor = [NSColor whiteColor].CGColor;
//				containerLayer.borderColor = [NSColor greenColor].CGColor;
			}
			[containerLayer addSublayer: textLayer];
			
			[self.layer addSublayer: containerLayer];
		}
	}
}

@end

/* -----------------------------------------------------------------------------
	Make sure delegate gets all messages we don't have a use for:
   -------------------------------------------------------------------------- */

@implementation UKDistributedView (UKDelegationForwarding)


-(BOOL) respondsToSelector: (SEL)theSel
{
	return( [[delegate class] instancesRespondToSelector: theSel]
			|| [[self class] instancesRespondToSelector: theSel] );
}

-(void) forwardInvocation:(NSInvocation *)invocation
{
    if ([delegate respondsToSelector:[invocation selector]])
        [invocation invokeWithTarget: delegate];
    else
        [self doesNotRecognizeSelector:[invocation selector]];
}


-(NSMethodSignature*)   methodSignatureForSelector:(SEL)aSelector
{
	NSMethodSignature*		sig = [super methodSignatureForSelector: aSelector];
	if( sig == nil && [delegate respondsToSelector: aSelector] )
		sig = [delegate methodSignatureForSelector: aSelector];
	
	return sig;
}


@end

@implementation NSObject (UKDistributedViewDelegateDefaultImpl)     // This isn't UKDistributedViewDelegate!!! That way we avoid warnings about unimplemented methods in category.

/* -----------------------------------------------------------------------------
	distributedView:itemIndexForString:options:
		Default implementation of type-ahead-selection so people using simple
        cells (like NSButtonCell or NSCell) get type-ahead-selection for free.
		
		Note that, for this to work, the items must be in alphabetic order.
	
	REVISIONS:
        2004-12-11  UK  Added options, renamed from itemIndexForTypeAheadString:
		2004-12-01	UK	Documented.
   -------------------------------------------------------------------------- */

-(int)  distributedView: (UKDistributedView*)distributedView itemIndexForString: (NSString*)matchString
                options:(unsigned)opts
{
	// An ok default matching algorithm.  You can probably get better performance if you
	//  implement this yourself, that way the NSCell doesn't have to get setup everytime,
	//  may matter, may not.
	
	id dataSource = [distributedView dataSource];
	id prototype = [distributedView prototype];
	int n = [dataSource numberOfItemsInDistributedView:distributedView];
	int i = 0;
	BOOL	layerBased = [distributedView.dataSource respondsToSelector: @selector(distributedView:titleAtItemIndex:)];
	
	// Find the closest match:
	while (i < n)
	{
		NSString* title = nil;
		if( layerBased )
			title = [dataSource distributedView: distributedView titleAtItemIndex: i];
		else
		{
			(void)[dataSource distributedView:distributedView positionForCell:prototype atItemIndex:i];
			title = [prototype stringValue];
		}
		if ([title length] >= [matchString length])
		{
			NSComparisonResult cr = [title compare:matchString options: opts
											 range:NSMakeRange(0, [matchString length])];
			
			if (NSOrderedSame == cr || NSOrderedDescending == cr)
				return i;
		}
		i += 1;
	}

	return -1;
}

@end

