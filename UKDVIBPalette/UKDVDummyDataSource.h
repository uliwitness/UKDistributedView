//
//  UKDVDummyDataSource.h
//  UKDVIBPalette
//
//  Created by Uli Kusterer on 04.12.04.
//  Copyright 2004 M. Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface UKDVDummyDataSource : NSObject
{
    IBPalette*       palette;
}

-(id)   initWithPalette: (IBPalette*)pal;

@end
