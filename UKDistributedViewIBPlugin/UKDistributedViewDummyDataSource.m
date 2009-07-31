//
//  UKDistributedViewDummyDataSource.m
//  UKDVIBPalette
//
//  Created by Uli Kusterer on 04.12.04.
//  Copyright 2004 M. Uli Kusterer. All rights reserved.
//

#import "UKDistributedViewDummyDataSource.h"
#import "UKDistributedView.h"


@implementation UKDistributedViewDummyDataSource

+(UKDistributedViewDummyDataSource*)	sharedDummyDataSource
{
	static UKDistributedViewDummyDataSource*	sDummyDataSource = nil;
	// Set up a shared "dummy" data source for our views, so users have something to look at:
	if( !sDummyDataSource )
		sDummyDataSource = [[UKDistributedViewDummyDataSource alloc] init];
	
	return sDummyDataSource;
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
		NSString*	imagePath = [[NSBundle bundleForClass: [self class]] pathForImageResource: [images objectAtIndex: row]];
        [cell setImage: [[[NSImage alloc] initWithContentsOfFile: imagePath] autorelease]];
    }
    
    return [distributedView itemPositionBasedOnItemIndex: row];
}

@end
