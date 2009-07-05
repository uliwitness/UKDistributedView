//
//  UKDistributedViewIBPluginInspector.m
//  UKDistributedViewIBPlugin
//
//  Created by Uli Kusterer on 05.07.09.
//  Copyright 2009 The Void Software. All rights reserved.
//

#import "UKDistributedViewIBPluginInspector.h"

@implementation UKDistributedViewIBPluginInspector

- (NSString *)viewNibName
{
	return @"UKDistributedViewIBPluginInspector";
}

- (void)refresh
{
	// Synchronize your inspector's content view with the currently selected objects.
	[super refresh];
}

@end
