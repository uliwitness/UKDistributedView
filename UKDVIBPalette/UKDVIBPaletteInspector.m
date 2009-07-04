//
//  UKDVIBPaletteInspector.m
//  UKDVIBPalette
//
//  Created by Uli Kusterer on 28.11.04.
//  Copyright M. Uli Kusterer 2004. All rights reserved.
//

#import "UKDVIBPaletteInspector.h"
#import "UKDVIBPalette.h"

@implementation UKDVIBPaletteInspector

- (id)init
{
    self = [super init];
    [NSBundle loadNibNamed:@"UKDVIBPaletteInspector" owner:self];
    
    return self;
}

- (void)ok:(id)sender
{
    [self optionsChanged: nil];
    [self gridColorChanged: nil];
    [self cellSizeChanged: nil];
    [self gridSizeChanged: nil];
    [self contentInsetChanged: nil];
    
    [super ok:sender];
}

// Make inspector display whatever attributes the current view has:
- (void)revert:(id)sender
{
    [super revert: sender];     // Makes sure dirty flag is cleared as needed.
    
	UKDistributedView*  obj = [self object];
    NSSize              cellSz = [obj cellSize];
    
    [cellWidthField setFloatValue: cellSz.width];
    [cellHeightField setFloatValue: cellSz.height];

    cellSz = [obj gridSize];
    [gridWidthField setFloatValue: cellSz.width];
    [gridHeightField setFloatValue: cellSz.height];

    [contentInsetField setFloatValue: [obj contentInset]];

    [snapToGridSwitch setState: [obj snapToGrid]];
    [forceToGridSwitch setState: [obj forceToGrid]];
    [dragMovesItemsSwitch setState: [obj dragMovesItems]];
    [multipleSelectionSwitch setState: [obj allowsMultipleSelection]];
    [emptySelectionSwitch setState: [obj allowsEmptySelection]];
    [selectionRectSwitch setState: [obj useSelectionRect]];
    [fitContentsSwitch setState: [obj sizeToFit]];
    [showSnapGuidesSwitch setState: [obj showSnapGuides]];
    [drawGridSwitch setState: [obj drawsGrid]];

    [gridColorWell setColor: [obj gridColor]];
}

-(IBAction) cellSizeChanged: (id)sender
{
	UKDistributedView*  obj = [self object];
    
    NSSize  cellSz;
    cellSz.width = [cellWidthField floatValue];
    cellSz.height = [cellHeightField floatValue];
    [obj setCellSize: cellSz];
    
    [[self inspectedDocument] touch];
}


-(IBAction) gridSizeChanged: (id)sender
{
	UKDistributedView*  obj = [self object];
    
    NSSize  cellSz;
    cellSz.width = [gridWidthField floatValue];
    cellSz.height = [gridHeightField floatValue];
    [obj setGridSize: cellSz];
    
    [[self inspectedDocument] touch];
}


-(IBAction) contentInsetChanged: (id)sender
{
	UKDistributedView*  obj = [self object];
    
    [obj setContentInset: [contentInsetField floatValue]];

    [[self inspectedDocument] touch];
}


-(IBAction) gridColorChanged: (id)sender
{
	UKDistributedView*  obj = [self object];
    
    [obj setGridColor: [gridColorWell color]];

    [[self inspectedDocument] touch];
}


-(IBAction) optionsChanged: (id)sender
{
	UKDistributedView*  obj = [self object];
    
    [obj setSnapToGrid: [snapToGridSwitch state]];
    [obj setForceToGrid: [forceToGridSwitch state]];
    [obj setDragMovesItems: [dragMovesItemsSwitch state]];
    [obj setAllowsMultipleSelection: [multipleSelectionSwitch state]];
    [obj setAllowsEmptySelection: [emptySelectionSwitch state]];
    [obj setUseSelectionRect: [selectionRectSwitch state]];
    [obj setSizeToFit: [fitContentsSwitch state]];
    [obj setShowSnapGuides: [showSnapGuidesSwitch state]];
    [obj setDrawsGrid: [drawGridSwitch state]];

    [[self inspectedDocument] touch];
}


-(IBAction) editCellPrototype: (id)sender
{
	UKDistributedView*  obj = [self object];
    
    id<IBEditors> eddie = [[self inspectedDocument] openEditorForObject: [obj prototype]];
    [eddie selectObjects: [NSArray arrayWithObject: [obj prototype]]];
}


@end
