//
//  UKDVIBPaletteInspector.h
//  UKDVIBPalette
//
//  Created by Uli Kusterer on 28.11.04.
//  Copyright __MyCompanyName__ 2004. All rights reserved.
//

#import <InterfaceBuilder/InterfaceBuilder.h>

@interface UKDVIBPaletteInspector : IBInspector
{
    IBOutlet NSTextField*   cellWidthField;
    IBOutlet NSTextField*   cellHeightField;
    IBOutlet NSTextField*   gridWidthField;
    IBOutlet NSTextField*   gridHeightField;
    IBOutlet NSTextField*   contentInsetField;
    IBOutlet NSButton*      snapToGridSwitch;
    IBOutlet NSButton*      forceToGridSwitch;
    IBOutlet NSButton*      multipleSelectionSwitch;
    IBOutlet NSButton*      emptySelectionSwitch;
    IBOutlet NSButton*      selectionRectSwitch;
    IBOutlet NSButton*      fitContentsSwitch;
    IBOutlet NSButton*      showSnapGuidesSwitch;
    IBOutlet NSButton*      drawGridSwitch;
    IBOutlet NSButton*      dragMovesItemsSwitch;
    IBOutlet NSColorWell*   gridColorWell;
}

-(IBAction) cellSizeChanged: (id)sender;
-(IBAction) gridSizeChanged: (id)sender;
-(IBAction) contentInsetChanged: (id)sender;
-(IBAction) gridColorChanged: (id)sender;
-(IBAction) optionsChanged: (id)sender;

#if WORKSAGAIN
-(IBAction) editCellPrototype: (id)sender;
#endif

@end
