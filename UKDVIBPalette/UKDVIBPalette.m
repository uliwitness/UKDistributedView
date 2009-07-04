//
//  UKDVIBPalette.m
//  UKDVIBPalette
//
//  Created by Uli Kusterer on 28.11.04.
//  Copyright M. Uli Kusterer 2004 . All rights reserved.
//

#import "UKDVIBPalette.h"
#import "UKFinderIconCell.h"
#import "IBObjectContainer.h"   // Fake IB header.
#import "UKDVDummyDataSource.h"


static UKDVDummyDataSource*     gDummyDataSource = nil;


@implementation UKDVIBPalette

-(id)   init
{
    self = [super init];
    if( self )
    {
        // Set up a shared "dummy" data source for our views, so users have something to look at:
        if( !gDummyDataSource )
            gDummyDataSource = [[UKDVDummyDataSource alloc] initWithPalette: self];
    }
    
    return self;
}

-(void) finishInstantiate
{
    // *** Associate our proxy image views with the actual objects: ***
    // UKFinderIconCell:
    UKFinderIconCell* cel = [[[UKFinderIconCell alloc] initImageCell: [NSImage imageNamed: @"NSApplicationIcon"]] autorelease];
    [cel setTitle: @"UKFinderIconCell"];
    [self associateObject: cel ofType: IBTableColumnPboardType withView: iconCellProxy];

    // pure UKDV:
    UKDistributedView* obj = [[[UKDistributedView alloc] initWithFrame: [pureProxy frame]] autorelease];
    [obj setSizeToFit: NO];
    [obj setPrototype: cel];
    [self associateObject: obj ofType: IBViewPboardType withView: pureProxy];
    
    // UKDV embedded in scroller:
    NSScrollView*   scroller = [[[NSScrollView alloc] initWithFrame: [scrollableProxy frame]] autorelease];
    obj = [[[UKDistributedView alloc] initWithFrame: [scrollableProxy frame]] autorelease];
    [[self paletteDocument] attachObject: obj toParent: scroller];
    [scroller setBackgroundColor: [NSColor whiteColor]];
    [scroller setDrawsBackground: YES];
    [scroller setHasVerticalScroller: YES];
    [scroller setHasHorizontalScroller: YES];
    [scroller setBorderType: NSBezelBorder];
    [scroller setDocumentView: obj];
    [obj setPrototype: cel];
    [[self paletteDocument] attachObject: cel toParent: obj];
    
    [self associateObject: scroller ofType: IBViewPboardType withView: scrollableProxy];
    
    // Note: IB archives and unarchives objects in the palette when you drag them off,
    //  so anything that doesn't persist during archiving/unarchiving is lost.
    
    // Now make sure UKDistributedView can take cells dragged on it:
    [UKDistributedView registerViewResourceDraggingDelegate: self];
}


// Tell IB what tool tips to display:
//  The default is the name of the class, but for the UKDV inside a scroll view,
//  that shows "NSScrollView", so we override that here.
-(NSString*)    toolTipForObject:(id)object
{
    if( [object isKindOfClass: [NSScrollView class]] )
        return @"UKDistributedView";
    else
        return NSStringFromClass( [object class] );
}


// Now some more stuff to allow a UKDistributedView to accept dropped cells:
-(NSArray*) viewResourcePasteboardTypes
{
    return [NSArray arrayWithObjects: IBTableColumnPboardType, nil];
}

-(BOOL) acceptsViewResourceFromPasteboard:(NSPasteboard *)pasteboard forObject:(id)object atPoint:(NSPoint)point
{
    return YES;
}


-(void) depositViewResourceFromPasteboard:(NSPasteboard *)pasteboard onObject:(id)object atPoint:(NSPoint)point
{
    NSData*                 deepFrozenCell = [pasteboard dataForType: IBTableColumnPboardType];
    IBObjectContainer*      container = [NSKeyedUnarchiver unarchiveObjectWithData: deepFrozenCell];
    NSCell*                 theCell = [[container rootObjects] objectAtIndex:0];
    id<IBDocuments>         doc = [(id<IB>)NSApp documentForObject: object];
    
    if( [doc parentOfObject: [object prototype]] != object )
        [doc attachObject: theCell toParent: object];
    else
        [doc replaceObject: [object prototype] withObject: theCell];
    [object setPrototype: theCell];
    
    [doc touch];
}

-(BOOL) shouldDrawConnectionFrame
{
    return YES;
}

@end


@implementation UKDistributedView (UKDVIBPaletteInspector)

// Tell IB what inspector to use for our class:
-(NSString*)    inspectorClassName
{
    return @"UKDVIBPaletteInspector";
}


// Install our own "dummy" data source so it looks nice:
-(id)   dataSource
{
    return gDummyDataSource;
}

@end

@implementation UKFinderIconCell (UKFICIBPaletteInspector)

// Tell IB what inspector to use for our class:
-(NSString*)    inspectorClassName
{
    return @"UKFICIBPaletteInspector";
}


// Cell-related stuff you might want to implement:
/* Used when dragging colors to cells. */
- (BOOL)acceptsColor:(NSColor *)color   { return YES; }
- (void)depositColor:(NSColor *)color   { [self setNameColor: color]; }

// Call super and then matches this cell with the prototype. Call in NSMatrix inspector
- (void)ibMatchPrototype:(NSCell*)proto
{
    [super ibMatchPrototype: proto];

    UKFinderIconCell*   prototype = (UKFinderIconCell*) proto;
    
    [self setNameColor: [prototype nameColor]];
    [self setBoxColor: [prototype boxColor]];
    [self setSelectionColor: [prototype selectionColor]];
    [self setTruncateMode: [prototype truncateMode]];
    [self setAlpha: [prototype alpha]];
    [self setImagePosition: [prototype imagePosition]];
    [self setTitle: [prototype title]];
    [self setImage: [prototype image]];
}


@end
