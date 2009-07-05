//
//  UKDistributedViewIBPlugin.m
//  UKDistributedViewIBPlugin
//
//  Created by Uli Kusterer on 05.07.09.
//  Copyright 2009 The Void Software. All rights reserved.
//

#import "UKDistributedViewIBPlugin.h"

@implementation UKDistributedViewIBPlugin

- (NSArray *)libraryNibNames
{
    return [NSArray arrayWithObject:@"UKDistributedViewIBPluginLibrary"];
}

- (NSArray *)requiredFrameworks
{
    return [NSArray arrayWithObjects:[NSBundle bundleWithIdentifier:@"com.thevoidsoftware.UKDistributedViewIBPlugin"], nil];
}

@end
