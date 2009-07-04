//
//  UKDVDummyDataSource.m
//  UKDVIBPalette
//
//  Created by Uli Kusterer on 04.12.04.
//  Copyright 2004 M. Uli Kusterer. All rights reserved.
//

#import "UKDVDummyDataSource.h"
#import "UKDistributedView.h"


@implementation UKDVDummyDataSource

-(id)   initWithPalette: (IBPalette*)pal
{
    if( (self = [super init]) )
    {
        palette = pal;
    }
    
    return self;
}


// UKDV delegate methods that we provide so we can use UKDV as the data source for
//  our distributed view once it's shown in a window by IB:
-(int)			numberOfItemsInDistributedView: (UKDistributedView*)distributedView
{
    return 8;
}

-(NSPoint)		distributedView: (UKDistributedView*)distributedView
						positionForCell:(NSCell*)cell /* may be nil if the view only wants the item position. */
						atItemIndex: (int)row
{
    NSArray*    names = [NSArray arrayWithObjects: @"Augsburg", @"Basel",
                                                    @"Gaiberg", @"Gatineau",
                                                    @"Heidelberg", @"Luzern",
                                                    @"Sempach", @"Sursee",
                                                    nil];
    NSArray*    images = [NSArray arrayWithObjects: @"sampleicon1", @"sampleicon2",
                                                    @"sampleicon3", @"sampleicon4",
                                                    @"sampleicon5", @"sampleicon6",
                                                    @"sampleicon7", @"sampleicon8",
                                                    nil];
    if( cell )
    {
        if( [cell type] != NSImageCellType )
            [cell setTitle: [names objectAtIndex: row]];
        [cell setImage: [palette imageNamed: [images objectAtIndex: row]]];
    }
    
    return [distributedView itemPositionBasedOnItemIndex: row];
}

@end
