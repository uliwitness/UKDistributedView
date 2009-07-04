//
//  UKFICIBPaletteInspector.m
//  UKDVIBPalette
//
//  Created by Uli Kusterer on 28.11.04.
//  Copyright M. Uli Kusterer 2004 . All rights reserved.
//

#import "UKFICIBPaletteInspector.h"
#import "UKFinderIconCell.h"

@implementation UKFICIBPaletteInspector

- (id)init
{
    self = [super init];
    [NSBundle loadNibNamed:@"UKFICIBPaletteInspector" owner:self];
    return self;
}

- (void)ok:(id)sender
{
    [self imageNameChanged: nil];
    [self nameBgColorChanged: nil];
    [self boxBgColorChanged: nil];
    [self selectionColorChanged: nil];
    [self imagePosChanged: nil];
    [self truncateTitleChanged: nil];
    [self opacityChanged: nil];
    
    [super ok:sender];
}

// Make inspector display whatever attributes the current view has:
- (void)revert:(id)sender
{
    [super revert: sender];     // Makes sure dirty flag is cleared as needed.
    
	UKFinderIconCell*   obj = [self object];
    
    NSString*   nm = [[obj image] name];
    if( !nm )
        nm = @"";
    [imageNameField setStringValue: nm];

    [nameBgColorWell setColor: [obj nameColor]];
    [boxBgColorWell setColor: [obj boxColor]];
    [selectionColorWell setColor: [obj selectionColor]];
    
    [imagePosPopup setIntValue: [obj imagePosition] -NSImageLeft];
    [imagePosPopup setIntValue: [obj truncateMode] -NSLineBreakByTruncatingHead];

    [opacitySlider setFloatValue: [obj alpha]];
}

-(IBAction) imageNameChanged: (id)sender
{
	UKFinderIconCell*  obj = [self object];
    
    [obj setImage: [NSImage imageNamed: [imageNameField stringValue]]];
    
    [[self inspectedDocument] touch];
}


-(IBAction) nameBgColorChanged: (id)sender
{
	UKFinderIconCell*  obj = [self object];
    
    [obj setNameColor: [nameBgColorWell color]];

    [[self inspectedDocument] touch];
}


-(IBAction) boxBgColorChanged: (id)sender
{
	UKFinderIconCell*  obj = [self object];
    
    [obj setBoxColor: [boxBgColorWell color]];

    [[self inspectedDocument] touch];
}


-(IBAction) selectionColorChanged: (id)sender
{
	UKFinderIconCell*  obj = [self object];
    
    [obj setSelectionColor: [selectionColorWell color]];

    [[self inspectedDocument] touch];
}


-(IBAction) opacityChanged: (id)sender
{
	UKFinderIconCell*  obj = [self object];
    
    [obj setAlpha: [opacitySlider floatValue]];

    [[self inspectedDocument] touch];
}


-(IBAction) imagePosChanged: (id)sender
{
	UKFinderIconCell*  obj = [self object];
    
    [obj setImagePosition: [imagePosPopup intValue] +NSImageLeft];

    [[self inspectedDocument] touch];
}


-(IBAction) truncateTitleChanged: (id)sender
{
	UKFinderIconCell*  obj = [self object];
    
    [obj setTruncateMode: [truncateTitlePopup intValue] +NSLineBreakByTruncatingHead];

    [[self inspectedDocument] touch];
}


@end
