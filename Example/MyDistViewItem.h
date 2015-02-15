//
//  MyDistViewItem.h
//  UKDistributedView
//
//  Created by Uli Kusterer on Wed Jun 25 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//
//	This software is provided 'as-is', without any express or implied
//	warranty. In no event will the authors be held liable for any damages
//	arising from the use of this software.
//
//	Permission is granted to anyone to use this software for any purpose,
//	including commercial applications, and to alter it and redistribute it
//	freely, subject to the following restrictions:
//
//	   1. The origin of this software must not be misrepresented; you must not
//	   claim that you wrote the original software. If you use this software
//	   in a product, an acknowledgment in the product documentation would be
//	   appreciated but is not required.
//
//	   2. Altered source versions must be plainly marked as such, and must not be
//	   misrepresented as being the original software.
//
//	   3. This notice may not be removed or altered from any source
//	   distribution.
//

#import <Foundation/Foundation.h>


// Class for storing list items used by MyDataSource:

@interface MyDistViewItem : NSObject
{
	NSString*		title;
	NSImage*		image;
	NSPoint			position;
}

-(id)	initWithTitle: (NSString*)theTitle andImage: (NSImage*)img;

-(NSString*)	title;
-(void)			setTitle: (NSString*)theTitle;

-(NSImage*)		image;
-(void)			setImage: (NSImage*)img;

-(NSPoint)		position;
-(void)			setPosition: (NSPoint)pos;

@end
