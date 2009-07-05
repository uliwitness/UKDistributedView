//
//  UKDistributedViewIBPluginView.m
//  UKDistributedViewIBPlugin
//
//  Created by Uli Kusterer on 05.07.09.
//  Copyright 2009 The Void Software. All rights reserved.
//

#import <InterfaceBuilderKit/InterfaceBuilderKit.h>
#import <UKDistributedViewIBPluginFramework/UKDistributedView.h>
#import "UKDistributedViewIBPluginInspector.h"


@implementation UKDistributedView ( UKDistributedViewIntegration )

- (void)ibPopulateKeyPaths: (NSMutableDictionary *)keyPaths
{
    [super ibPopulateKeyPaths: keyPaths];
	
	// Remove the comments and replace "MyFirstProperty" and "MySecondProperty" 
	// in the following line with a list of your view's KVC-compliant properties.
    [[keyPaths objectForKey: IBAttributeKeyPaths] addObjectsFromArray: [NSArray arrayWithObjects:/* @"MyFirstProperty", @"MySecondProperty",*/ nil]];
}

- (void)ibPopulateAttributeInspectorClasses:(NSMutableArray *)classes
{
    [super ibPopulateAttributeInspectorClasses: classes];
    [classes addObject: [UKDistributedViewIBPluginInspector class]];
}

@end
