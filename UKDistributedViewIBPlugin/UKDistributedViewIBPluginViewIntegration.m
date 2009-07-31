//
//  UKDistributedViewIBPluginView.m
//  UKDistributedViewIBPlugin
//
//  Created by Uli Kusterer on 05.07.09.
//  Copyright 2009 The Void Software. All rights reserved.
//

#import <InterfaceBuilderKit/InterfaceBuilderKit.h>
#import <UKDistributedViewIBPlugin/UKDistributedView.h>
#import "UKDistributedViewIBPluginInspector.h"
#import "UKDistributedViewDummyDataSource.h"


@implementation UKDistributedView ( UKDistributedViewIntegration )

- (void)ibPopulateKeyPaths: (NSMutableDictionary *)keyPaths
{
    [super ibPopulateKeyPaths: keyPaths];
	
	// Remove the comments and replace "MyFirstProperty" and "MySecondProperty" 
	// in the following line with a list of your view's KVC-compliant properties.
    [[keyPaths objectForKey: IBAttributeKeyPaths] addObjectsFromArray: [NSArray arrayWithObjects: @"gridColor", /*@"MySecondProperty",*/ nil]];
}

- (void)ibPopulateAttributeInspectorClasses:(NSMutableArray *)classes
{
    [super ibPopulateAttributeInspectorClasses: classes];
    [classes addObject: [UKDistributedViewIBPluginInspector class]];
}

-(id)   dataSource	// Override data source with our default dummy source.
{
    return [UKDistributedViewDummyDataSource sharedDummyDataSource];
}

@end
