//
//  NSBezierPathCappedBoxes.h
//  UKDistributedView
//
//  Created by Uli Kusterer on 2003-12-19.
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

// -----------------------------------------------------------------------------
//	Headers:
// -----------------------------------------------------------------------------

#import "NSBezierPathCappedBoxes.h"


@implementation NSBezierPath (CappedBoxes)

// -----------------------------------------------------------------------------
//	bezierPathWithCappedBoxInRect:
//		This creates a bezier path for the specified rectangle where the left
//		and right sides of the box are halves of a circle.
//	
//	REVISIONS:
//      2004-11-20  UK  Changed to use arcs instead of bezier paths as per a
//                      submission from Christoffer Lerno.
//		2004-01-17  UK  Documented.
// -----------------------------------------------------------------------------

+(NSBezierPath*) bezierPathWithCappedBoxInRect: (NSRect)rect
{
    NSBezierPath* bezierPath = [NSBezierPath bezierPath];
    float cornerSize = rect.size.height / 2;
    
    // Corners:
    NSPoint leftTop = NSMakePoint(NSMinX(rect) + cornerSize, NSMaxY(rect));
    NSPoint rightTop = NSMakePoint(NSMaxX(rect) - cornerSize, NSMaxY(rect));
    NSPoint rightBottom = NSMakePoint(NSMaxX(rect) - cornerSize, NSMinY(rect));
    NSPoint leftBottom = NSMakePoint(NSMinX(rect) + cornerSize, NSMinY(rect));
    
    // Create our capped box:
    // Top edge:
    [bezierPath moveToPoint:leftTop]; 
    [bezierPath lineToPoint:rightTop];
    // Right cap:
    [bezierPath appendBezierPathWithArcWithCenter:NSMakePoint(rightTop.x,(NSMaxY(rect)+NSMinY(rect))/2)  
					   radius:cornerSize startAngle:90 endAngle:-90 clockwise:YES];
    // Bottom edge:
    [bezierPath lineToPoint: rightBottom];
    [bezierPath lineToPoint: leftBottom];
    // Left cap:
    [bezierPath appendBezierPathWithArcWithCenter:NSMakePoint(leftTop.x,(NSMaxY(rect)+NSMinY(rect))/2)  
					   radius:cornerSize startAngle:-90 endAngle:90 clockwise:YES];
    
    [bezierPath closePath]; // Just to be safe.
    
    return bezierPath;
}


@end
