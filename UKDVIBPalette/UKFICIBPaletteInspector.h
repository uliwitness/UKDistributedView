//
//  UKFICIBPaletteInspector.h
//  UKDVIBPalette
//
//  Created by Uli Kusterer on 28.11.04.
//  Copyright M. Uli Kusterer 2004. All rights reserved.
//

#import <InterfaceBuilder/InterfaceBuilder.h>

@interface UKFICIBPaletteInspector : IBInspector
{
    IBOutlet NSTextField*   imageNameField;
    IBOutlet NSColorWell*   nameBgColorWell;
    IBOutlet NSColorWell*   boxBgColorWell;
    IBOutlet NSColorWell*   selectionColorWell;
    IBOutlet NSPopUpButton* imagePosPopup;
    IBOutlet NSPopUpButton* truncateTitlePopup;
    IBOutlet NSSlider*      opacitySlider;
}

-(IBAction) imageNameChanged: (id)sender;
-(IBAction) nameBgColorChanged: (id)sender;
-(IBAction) boxBgColorChanged: (id)sender;
-(IBAction) selectionColorChanged: (id)sender;
-(IBAction) imagePosChanged: (id)sender;
-(IBAction) truncateTitleChanged: (id)sender;
-(IBAction) opacityChanged: (id)sender;

@end
