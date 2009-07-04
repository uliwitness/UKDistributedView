//
//  UKDVIBPalette.h
//  UKDVIBPalette
//
//  Created by Uli Kusterer on 28.11.04.
//  Copyright M. Uli Kusterer 2004 . All rights reserved.
//

#import <InterfaceBuilder/InterfaceBuilder.h>
#import "UKDistributedView.h"

@interface UKDVIBPalette : IBPalette <IBViewResourceDraggingDelegates>
{
    IBOutlet NSImageView*       scrollableProxy;
    IBOutlet NSImageView*       pureProxy;
    IBOutlet NSImageView*       iconCellProxy;
}

@end

@interface UKDistributedView (UKDVIBPaletteInspector)

- (NSString *)inspectorClassName;

@end
