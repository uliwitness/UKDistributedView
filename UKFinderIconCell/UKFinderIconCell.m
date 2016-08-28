//
//  UKFinderIconCell.h
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
//  Headers:
// -----------------------------------------------------------------------------

#import "UKFinderIconCell.h"
#import "NSBezierPathCappedBoxes.h"
#import "NSImage+NiceScaling.h"


// -----------------------------------------------------------------------------
//  Private Methods:
// -----------------------------------------------------------------------------

@interface UKFinderIconCell (UKPrivateMethods)

-(void) setFlipped: (BOOL)a;    // Is reset each time cell is drawn in a view.

-(void) makeAlignmentConformImagePosition;

-(NSFont*)	fontAtBestSize;

@end


@implementation UKFinderIconCell

// -----------------------------------------------------------------------------
//  Designated initializer:
// -----------------------------------------------------------------------------

-(id)   initTextCell: (NSString*)txt
{
	if(( self = [super initTextCell: txt] ))
	{
		flags.bits.selected = NO;
		image = [[NSImage imageNamed: @"NSApplicationIcon"] retain];
		nameColor = [[NSColor controlBackgroundColor] retain];
		boxColor = [[NSColor secondarySelectedControlColor] retain];
		selectionColor = [[NSColor alternateSelectedControlColor] retain];
		imagePosition = NSImageAbove;
        truncateMode = NSLineBreakByTruncatingMiddle;
        alpha = 1.0;
		[self makeAlignmentConformImagePosition];
	}
	
	return self;
}

-(id)   initImageCell: (NSImage*)img
{
	if(( self = [self initTextCell: @"UKDVUKDT"] ))
	{
		[self setImage: img];
	}
	return self;
}


/* -----------------------------------------------------------------------------
	initWithCoder:
		Persistence constructor needed for IB palette.
	
	REVISIONS:
        2004-12-03	UK	Created.
   -------------------------------------------------------------------------- */

-(id)   initWithCoder:(NSCoder *)decoder
{
    if(( self = [super initWithCoder: decoder] ))
	{
		// Set up a few defaults:
		flags.bits.selected = NO;
		imagePosition = NSImageAbove;
        truncateMode = NSLineBreakByTruncatingMiddle;
        alpha = 1.0;
		
		if( [decoder allowsKeyedCoding] )
		{
			image = [[decoder decodeObjectForKey: @"UKFICimage"] retain];
			nameColor = [[decoder decodeObjectForKey: @"UKFICnameColor"] retain];
			boxColor = [[decoder decodeObjectForKey: @"UKFICboxColor"] retain];
			selectionColor = [[decoder decodeObjectForKey: @"UKFICselectionColor"] retain];
			bgColor = [[decoder decodeObjectForKey: @"UKFICbgColor"] retain];
			if( [decoder containsValueForKey: @"UKFICimagePosition"] )
				imagePosition = [decoder decodeIntForKey: @"UKFICimagePosition"];
			if( [decoder containsValueForKey: @"UKFICtruncateMode"] )
				truncateMode = [decoder decodeIntForKey: @"UKFICtruncateMode"];
			if( [decoder containsValueForKey: @"UKFICalpha"] )
				alpha = [decoder decodeFloatForKey: @"UKFICalpha"];
		}
		else
		{
			image = [[decoder decodeObject] retain];
			nameColor = [[decoder decodeObject] retain];
			boxColor = [[decoder decodeObject] retain];
			selectionColor = [[decoder decodeObject] retain];
			bgColor = [[decoder decodeObject] retain];
			[decoder decodeValueOfObjCType:@encode(int) at: &imagePosition];
			[decoder decodeValueOfObjCType:@encode(int) at: &truncateMode];
			[decoder decodeValueOfObjCType:@encode(float) at: &alpha];
		}

		if( !image )
			image = [[NSImage imageNamed: @"NSApplicationIcon"] retain];
		if( !nameColor )
			nameColor = [[NSColor controlBackgroundColor] retain];
		if( !boxColor )
			boxColor = [[NSColor secondarySelectedControlColor] retain];
		if( !selectionColor )
			selectionColor = [[NSColor alternateSelectedControlColor] retain];
		[self makeAlignmentConformImagePosition];
	}
    
    return self;
}


/* -----------------------------------------------------------------------------
	encodeWithCoder:
		Save this cell to a file. Used by IB.
	
	REVISIONS:
        2004-12-03	UK	Created.
   -------------------------------------------------------------------------- */

-(void) encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
	
    if( [coder allowsKeyedCoding] )
    {
        [coder encodeObject: image forKey: @"UKFICimage"];
        [coder encodeObject: nameColor forKey: @"UKFICnameColor"];
        [coder encodeObject: boxColor forKey: @"UKFICboxColor"];
        [coder encodeInt: imagePosition forKey: @"UKFICimagePosition"];
        [coder encodeObject: selectionColor forKey: @"UKFICselectionColor"];
        [coder encodeObject: bgColor forKey: @"UKFICbgColor"];
        [coder encodeInt: truncateMode forKey: @"UKFICtruncateMode"];
        [coder encodeFloat: alpha forKey: @"UKFICalpha"];
    }
    else
    {
        [coder encodeObject: image];
        [coder encodeObject: nameColor];
        [coder encodeObject: boxColor];
        [coder encodeObject: selectionColor];
        [coder encodeObject: bgColor];
        [coder encodeValueOfObjCType:@encode(int) at: &imagePosition];
        [coder encodeValueOfObjCType:@encode(int) at: &truncateMode];
        [coder encodeValueOfObjCType:@encode(float) at: &alpha];
    }
}


// -----------------------------------------------------------------------------
//  Initializer for us lazy ones:
// -----------------------------------------------------------------------------

-(id)   init
{
	return [self initTextCell: @"UKDVUliDaniel"];
}


// -----------------------------------------------------------------------------
//  Destructor:
// -----------------------------------------------------------------------------

-(void) dealloc
{
	[image release];
	image = nil;
	[nameColor release];
	nameColor = nil;
	[boxColor release];
	boxColor = nil;
	[selectionColor release];
	selectionColor = nil;
	[bgColor release];
	bgColor = nil;
	
	[super dealloc];
}


/* -----------------------------------------------------------------------------
	copyWithZone:
		Implement the NSCopying protocol (IB requires this, and some cell-based
        classes may, as well).
	
	REVISIONS:
        2004-12-23	UK	Documented.
   -------------------------------------------------------------------------- */

-(id)   copyWithZone: (NSZone*)zone
{
    UKFinderIconCell	*cell = (UKFinderIconCell*) [super copyWithZone: zone];

    cell->image = [image retain];
	cell->nameColor = [nameColor retain];
	cell->boxColor = [boxColor retain];
	cell->selectionColor = [selectionColor retain];
	cell->bgColor = [bgColor retain];

    return cell;
}


// -----------------------------------------------------------------------------
//  Reset boxColor, nameColor and selectionColor to the defaults:
// -----------------------------------------------------------------------------

-(void) resetColors
{
	[self setNameColor: [NSColor controlBackgroundColor]];
	[self setBoxColor: [NSColor secondarySelectedControlColor]];
	[self setSelectionColor: [NSColor alternateSelectedControlColor]];
	[self setBgColor: nil];
}


// -----------------------------------------------------------------------------
//  Mutator for cell selection state:
// -----------------------------------------------------------------------------

-(void)	setHighlighted: (BOOL)isSelected
{
	flags.bits.selected = isSelected;
}


-(BOOL)	isHighlighted
{
    return flags.bits.selected;
}



// -----------------------------------------------------------------------------
//  Accessor for cell flipped state (cached from last drawing):
//      Mutator is in private methods.
// -----------------------------------------------------------------------------

-(BOOL)	isFlipped
{
    return flags.bits.flipped;
}



// -----------------------------------------------------------------------------
//  Mutator for separator at top of cell:
// -----------------------------------------------------------------------------

-(void)	setDrawSeparator: (BOOL)isSelected
{
	flags.bits.drawSeparator = isSelected;
}


-(BOOL)	drawSeparator
{
    return flags.bits.drawSeparator;
}


/*-(void) drawWithFrame: (NSRect)box inView: (NSView*)aView
{
    [self drawInteriorWithFrame: box inView: aView];
}*/


-(void)	highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [self setHighlighted: flag];
    if( controlView )
        [controlView setNeedsDisplay: YES];
    else
        [self drawWithFrame: cellFrame inView: controlView];
}


-(float)	textSizeForBox: (NSRect)box
{
    float   sz = 10;
    
    switch( imagePosition )
    {
        case NSImageAbove:
        case NSImageBelow:
            sz = truncf(box.size.height / 8);
            break;

        case NSImageLeft:
        case NSImageRight:
        case NSImageLeading:
        case NSImageTrailing:
            sz = truncf(box.size.height / 8);
            break;
        
        case NSNoImage:		// Just to shut up compiler warnings.
        case NSImageOnly:
        case NSImageOverlaps:
            break;
    }
    
    if( sz < 10 )
        return 10;
    else
        return sz;
}


// -----------------------------------------------------------------------------
//  Draws everything you see of the cell:
// -----------------------------------------------------------------------------

-(void)	drawInteriorWithFrame:(NSRect)box inView:(NSView *)aView
{
	NSRect				imgBox = box,
						textBox = box,
						textBgBox = box;
	NSDictionary*		attrs = nil;
	NSColor*			txBgColor = nil;
	NSString*			displayTitle = [self title];
	NSCellImagePosition imagePos = imagePosition;
    flags.bits.flipped = [aView isFlipped];
	
	NSImageRep*	rep = [[image representations] objectAtIndex: 0];
	[image setSize: NSMakeSize( [rep pixelsWide], [rep pixelsHigh])];
	
	lastUsedCellRect = box;		// Remember so font size setup code can base the size on this rect.
	
	//NSLog(@"drawing %@", UKDebugNameFor(self));
	
    /*
    attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSFont systemFontOfSize: 12], NSFontAttributeName,
                    [[NSColor alternateSelectedControlTextColor] colorWithAlphaComponent: alpha], NSForegroundColorAttributeName,
                    nil];*/
    
    if( bgColor )
    {
        [bgColor set];
        [NSBezierPath fillRect: box];
    }
    if( flags.bits.drawSeparator )
    {
        [NSBezierPath setDefaultLineWidth: 2];
        [NSBezierPath setDefaultLineCapStyle: NSRoundLineCapStyle];
        [[NSColor lightGrayColor] set];
        [NSBezierPath strokeLineFromPoint: NSMakePoint(box.origin.x, box.origin.y +box.size.height -1)
                        toPoint: NSMakePoint(box.origin.x +box.size.width, box.origin.y +box.size.height -1)];
        [NSBezierPath setDefaultLineWidth: 1];
        [NSBezierPath setDefaultLineCapStyle: NSSquareLineCapStyle];
    }
    
	if( flags.bits.flipped )
	{
		switch( imagePosition )
		{
			case NSImageAbove:
				imagePos = NSImageBelow;
				break;
			
			case NSImageBelow:
				imagePos = NSImageAbove;
				break;
			
			case NSNoImage:		// Just to shut up compiler warnings.
			case NSImageOnly:
			case NSImageLeft:
			case NSImageRight:
			case NSImageLeading:
			case NSImageTrailing:
			case NSImageOverlaps:
				break;
		}
	}
	
	[NSGraphicsContext saveGraphicsState];
	[NSBezierPath clipRect: box];   // Make sure we don't draw outside our cell.
	
	// Set up text attributes for title:
	if( flags.bits.selected )
	{
		attrs = [NSDictionary dictionaryWithObjectsAndKeys:
						[self fontAtBestSize], NSFontAttributeName,
						[[NSColor alternateSelectedControlTextColor] colorWithAlphaComponent: alpha], NSForegroundColorAttributeName,
						nil];
		txBgColor = [selectionColor colorWithAlphaComponent: alpha];
	}
	else
	{
		attrs = [NSDictionary dictionaryWithObjectsAndKeys:
						[self fontAtBestSize], NSFontAttributeName,
						[[NSColor controlTextColor] colorWithAlphaComponent: alpha], NSForegroundColorAttributeName,
						nil];
		txBgColor = [nameColor colorWithAlphaComponent: alpha];
	}
	
    // Calculate area left for title beside image:
	NSSize			txSize = [displayTitle sizeWithAttributes: attrs];
    int             titleHReduce = 0;   // How much to make title narrower to allow for icon next to it.
	NSSize          imgSize = { 0,0 };
    
    imgSize = [NSImage scaledSize: [image size] toFitSize: box.size];
    
    if( imagePos == NSImageLeft || imagePos == NSImageRight || imagePos == NSImageLeading || imagePos == NSImageTrailing )
        titleHReduce = imgSize.width +(UKFIC_SELBOX_HORZMARGIN +UKFIC_SELBOX_OUTLINE_WIDTH) *2;
    
	// Truncate string if needed:
	displayTitle = UKStringByTruncatingStringWithAttributesForWidth( displayTitle, attrs,
							(box.size.width -titleHReduce -txSize.height -(2* UKFIC_TEXT_HORZMARGIN)), truncateMode );  // Removed - - here.

	// Calculate rectangle for text:
	txSize = [displayTitle sizeWithAttributes: attrs];
	
	NSCellImagePosition	actualPos = imagePos;
	NSUserInterfaceLayoutDirection	layoutDir = [[NSApplication sharedApplication] userInterfaceLayoutDirection];
	if( imagePos == NSImageLeading && layoutDir == NSUserInterfaceLayoutDirectionLeftToRight )
		actualPos = NSImageLeft;
	else if( imagePos == NSImageLeading && layoutDir == NSUserInterfaceLayoutDirectionRightToLeft )
		actualPos = NSImageRight;
	else if( imagePos == NSImageTrailing && layoutDir == NSUserInterfaceLayoutDirectionLeftToRight )
		actualPos = NSImageRight;
	else if( imagePos == NSImageTrailing && layoutDir == NSUserInterfaceLayoutDirectionRightToLeft )
		actualPos = NSImageLeft;

	if( imagePos == NSImageAbove		// Finder icon view (big, title below image).
		|| imagePos == NSImageBelow )  // Title *above* image.
	{
		textBox.size = txSize;
		textBox.origin.x += truncf((box.size.width -txSize.width) / 2);  // Center our text at cell's bottom.
		if( imagePos == NSImageAbove )
			textBox.origin.y += UKFIC_TEXT_VERTMARGIN;
		else
			textBox.origin.y = box.origin.y +box.size.height -txSize.height -UKFIC_TEXT_VERTMARGIN;
		textBgBox = NSInsetRect( textBox, -UKFIC_TEXT_HORZMARGIN -truncf(txSize.height /2),
									-UKFIC_TEXT_VERTMARGIN );		// Give us some room around our text.
	}
	else if( imagePos == NSImageLeft
			|| imagePos == NSImageRight
			|| imagePos == NSImageLeading
			|| imagePos == NSImageTrailing )
	{
		textBox.size = txSize;
		textBox.origin.y += truncf((box.size.height -txSize.height) / 2);  // Center our text vertically in cell.
		if( imagePos == NSImageLeft )
			textBox.origin.x += UKFIC_TEXT_HORZMARGIN;
		else
			textBox.origin.x = box.origin.x +box.size.width -txSize.width -UKFIC_TEXT_HORZMARGIN;
		textBgBox = NSInsetRect( textBox, -UKFIC_TEXT_HORZMARGIN *2, -UKFIC_TEXT_VERTMARGIN /*-truncf(txSize.height /2)*/ );		// Give us some room around our text.
	}
		
	// Prepare image and image highlight rect:
	switch( imagePos )
	{
		case NSImageAbove:
			imgBox.origin.y += textBgBox.size.height;
			imgBox.size.height -= textBgBox.size.height;
			break;
			
		case NSImageBelow:
			imgBox.size.height -= textBgBox.size.height;
			break;
		
		case NSImageLeft:
			imgBox.size.width -= textBgBox.size.width;
			break;
			
		case NSImageRight:
			imgBox.size.width -= textBgBox.size.width;
			break;
		
		case NSImageLeading:
			imgBox.size.width -= textBgBox.size.width;
			break;
			
		case NSImageTrailing:
			imgBox.size.width -= textBgBox.size.width;
			break;
		
		case NSNoImage:
		case NSImageOnly:
		case NSImageOverlaps:
			NSLog(@"UKFinderIconCell - Unsupported image position mode.");
			break;
	}
	
	if( imagePos == NSImageRight
		|| imagePos == NSImageLeft
		|| imagePos == NSImageLeading
		|| imagePos == NSImageTrailing )
		imgBox = NSInsetRect( imgBox, UKFIC_SELBOX_VERTMARGIN +UKFIC_SELBOX_OUTLINE_WIDTH,
										UKFIC_SELBOX_HORZMARGIN +UKFIC_SELBOX_OUTLINE_WIDTH );
	else
		imgBox = NSInsetRect( imgBox, UKFIC_SELBOX_HORZMARGIN +UKFIC_SELBOX_OUTLINE_WIDTH,
										UKFIC_SELBOX_VERTMARGIN +UKFIC_SELBOX_OUTLINE_WIDTH );
	
	// Make sure icon box is pretty and square:
	if( imgBox.size.height < imgBox.size.width )
	{
		float   diff = imgBox.size.width -imgBox.size.height;
		
		imgBox.size.width = imgBox.size.height; // Force width to be same as height.
		if( imagePos == NSImageAbove
			|| imagePos == NSImageBelow )
			imgBox.origin.x += truncf(diff/2);		// Center narrower box in cell.
	}
	
	if( actualPos == NSImageLeft )
	{
		textBox.origin.x += imgBox.size.width +truncf(textBox.size.height /2) +(UKFIC_TEXT_VERTMARGIN *3);
		textBgBox.origin.x += imgBox.size.width +truncf(textBox.size.height /2) +(UKFIC_TEXT_VERTMARGIN *3);
	}
	else if( actualPos == NSImageRight )
	{
		imgBox.origin.x = box.origin.x +box.size.width -imgBox.size.width -UKFIC_SELBOX_HORZMARGIN;
		textBox.origin.x -= imgBox.size.width +(UKFIC_TEXT_VERTMARGIN *3);
		textBgBox.origin.x -= imgBox.size.width +(UKFIC_TEXT_VERTMARGIN *3);
	}
	
	// Draw text background either with white, or with "selected" color:
	[txBgColor set];
	[[NSBezierPath bezierPathWithRoundedRect: textBgBox xRadius: truncf(textBgBox.size.height /4) yRadius: truncf(textBgBox.size.height /4)] fill];   // draw text bg.
	
	// Draw actual text:
	if( !flags.bits.currentlyEditing )
		[displayTitle drawInRect: textBox withAttributes: attrs];
	
	// If selected, draw image highlight rect:
	if( flags.bits.selected && boxColor )
	{
		// Set up line for selection outline:
		NSLineJoinStyle svLjs = [NSBezierPath defaultLineJoinStyle];
		[NSBezierPath setDefaultLineJoinStyle: NSRoundLineJoinStyle];
		float			svLwd = [NSBezierPath defaultLineWidth];
		[NSBezierPath setDefaultLineWidth: UKFIC_SELBOX_OUTLINE_WIDTH];
		
		// Draw selection outline:
		NSColor*	scc = [boxColor colorWithAlphaComponent: alpha];
		[[scc colorWithAlphaComponent: 0.5] set];			// Slightly transparent body first.
		[[NSBezierPath bezierPathWithRoundedRect: imgBox xRadius: 4 yRadius: 4] fill];
		[[scc colorWithAlphaComponent: 0.4] set];											// Opaque rounded boundaries next.
		NSRect	imageLineBox = imgBox;
		imageLineBox.origin.x += 0.5;
		imageLineBox.origin.y += 0.5;
		imageLineBox.size.width -= 1;
		imageLineBox.size.height -= 1;
		[[NSBezierPath bezierPathWithRoundedRect: imageLineBox xRadius: 4 yRadius: 4] stroke];
		
		// Clean up:
		[NSBezierPath setDefaultLineJoinStyle: svLjs];
		[NSBezierPath setDefaultLineWidth: svLwd];
		[[NSColor blackColor] set];
	}
	
	// Calculate box for icon:
	NSSize		actualSize = [image size];
	imgBox = NSInsetRect( imgBox, UKFIC_IMAGE_HORZMARGIN, UKFIC_IMAGE_VERTMARGIN );

        // Make sure we're drawing on whole pixels, not between them:
    imgBox.origin.x = truncf(imgBox.origin.x);
    imgBox.origin.y = truncf(imgBox.origin.y);
    imgBox.size = [NSImage scaledSize: actualSize toFitSize: imgBox.size];

	// Draw it!
    NSRect  imgRect = { { 0,0 }, { 0,0 } };
    imgRect.size = actualSize;
	if( [aView inLiveResize] )
		[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationNone];
	else
		[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
	
    BOOL    drawUpsideDown = flags.bits.flipped;
	if( drawUpsideDown )
    {
		NSAffineTransform	*	trans = [NSAffineTransform transform];
		[trans scaleXBy: 1.0 yBy: -1.0];
		[trans translateXBy: 0 yBy: -imgBox.origin.y *2];
		[trans concat];
		imgBox.origin.y -= imgBox.size.height;
    }
	
	[image drawInRect: imgBox fromRect: imgRect operation: NSCompositeSourceOver fraction: alpha];

	/*if( flags.bits.flipped )
		[image compositeToPoint: NSMakePoint(imgBox.origin.x,imgBox.origin.y +actualSize.height) operation: NSCompositeSourceOver fraction: alpha];
	else
		[image compositeToPoint: imgBox.origin operation: NSCompositeSourceOver fraction: alpha];*/
	
	[NSGraphicsContext restoreGraphicsState];
}


// -----------------------------------------------------------------------------
//  Accessor for cell icon:
// -----------------------------------------------------------------------------

-(NSImage*)	image
{
	return image;
}


// -----------------------------------------------------------------------------
//  Mutator for cell icon:
// -----------------------------------------------------------------------------

-(void)			setImage: (NSImage*)tle
{
	if( tle != image )
	{
		[image release];
		image = [tle retain];
	}
}


// -----------------------------------------------------------------------------
//  Mutator for name background color:
// -----------------------------------------------------------------------------

-(void)		setNameColor: (NSColor*)col
{
	[col retain];
	[nameColor release];
	nameColor = col;
}


// -----------------------------------------------------------------------------
//  Accessor for name background color:
// -----------------------------------------------------------------------------

-(NSColor*) nameColor
{
	return nameColor;
}


// -----------------------------------------------------------------------------
//  Mutator for icon highlight box color:
// -----------------------------------------------------------------------------

-(void)		setBoxColor: (NSColor*)col
{
	[col retain];
	[boxColor release];
	boxColor = col;
}


// -----------------------------------------------------------------------------
//  Accessor for icon highlight box color:
// -----------------------------------------------------------------------------

-(NSColor*) boxColor
{
	return boxColor;
}


// -----------------------------------------------------------------------------
//  Mutator for cell background color:
// -----------------------------------------------------------------------------

-(void)		setBgColor: (NSColor*)col
{
	[col retain];
	[bgColor release];
	bgColor = col;
}


// -----------------------------------------------------------------------------
//  Accessor for cell background color:
// -----------------------------------------------------------------------------

-(NSColor*) bgColor
{
	return bgColor;
}


// -----------------------------------------------------------------------------
//  Mutator for name highlight color:
// -----------------------------------------------------------------------------

-(void)		setSelectionColor: (NSColor*)col;
{
	[col retain];
	[selectionColor release];
	selectionColor = col;
}


// -----------------------------------------------------------------------------
//  Accessor for name highlight color:
// -----------------------------------------------------------------------------

-(NSColor*) selectionColor;
{
	return selectionColor;
}


// -----------------------------------------------------------------------------
//  Accessors/Mutators for image positioning relative to title:
// -----------------------------------------------------------------------------

-(NSCellImagePosition)  imagePosition
{
    return imagePosition;
}

-(void) setImagePosition: (NSCellImagePosition)newImagePosition
{
   imagePosition = newImagePosition;
   [self makeAlignmentConformImagePosition];
}


// -----------------------------------------------------------------------------
//  Size we'd want for cell:
// -----------------------------------------------------------------------------

-(NSSize)   cellSize
{
	NSSize		theSize = [super cellSize];
	
	theSize.height += (image) ? ([image size].height +(UKFIC_SELBOX_VERTMARGIN *2) +(UKFIC_IMAGE_VERTMARGIN *2)) : 0;
	
	return theSize;
}


// -----------------------------------------------------------------------------
//	editWithFrame:inView:editor:delegate:event:
//		Start inline-editing.
//	
//	REVISIONS:
//        2004-12-23	UK	Documented.
// -----------------------------------------------------------------------------

-(void) editWithFrame:(NSRect)aRect inView:(NSView *)aView editor:(NSText *)textObj
            delegate:(id)anObject event:(NSEvent *)theEvent
{
    NSRect textFrame, imageFrame;
	
	lastUsedCellRect = aRect;	// Remember so font size setup code can know our size, too.
	
	NSDictionary*   attrs = [NSDictionary dictionaryWithObjectsAndKeys:
						[self fontAtBestSize], NSFontAttributeName,
						[NSColor controlTextColor], NSForegroundColorAttributeName,
						nil];
	NSSize			txSize = [[self title] sizeWithAttributes: attrs];
	
	flags.bits.flipped = [aView isFlipped];
    NSDivideRect (aRect, &textFrame, &imageFrame, (UKFIC_TEXT_VERTMARGIN *2) + txSize.height, flags.bits.flipped ? NSMaxYEdge : NSMinYEdge);
	
    flags.bits.currentlyEditing = YES;
	[super editWithFrame: textFrame inView: aView editor:textObj delegate:anObject event: theEvent];
}


// -----------------------------------------------------------------------------
//	endEditing:
//		Finish inline-editing.
//	
//	REVISIONS:
//        2004-12-23	UK	Documented.
// -----------------------------------------------------------------------------

-(void) endEditing:(NSText *)textObj
{
    flags.bits.currentlyEditing = NO;
    [super endEditing: textObj];
}


// -----------------------------------------------------------------------------
//	selectWithFrame:inView:editor:delegate:start:length:
//		Alternate way to start inline-editing.
//	
//	REVISIONS:
//        2004-12-23	UK	Documented.
// -----------------------------------------------------------------------------

-(void) selectWithFrame:(NSRect)aRect inView:(NSView *)aView editor:(NSText *)textObj
            delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
    NSRect textFrame, imageFrame;
	
	lastUsedCellRect = aRect;	// Remember so font size setup code can know our size, too.
	
	NSDictionary*   attrs = [NSDictionary dictionaryWithObjectsAndKeys:
						[self fontAtBestSize], NSFontAttributeName,
						[NSColor controlTextColor], NSForegroundColorAttributeName,
						nil];
	
	NSSize			txSize = [[self title] sizeWithAttributes: attrs];
	
	flags.bits.flipped = [aView isFlipped];
    NSDivideRect (aRect, &textFrame, &imageFrame, (UKFIC_TEXT_VERTMARGIN *2) + txSize.height, flags.bits.flipped ? NSMaxYEdge : NSMinYEdge);
   
    flags.bits.currentlyEditing = YES;
	[super selectWithFrame: textFrame inView: aView editor:textObj delegate:anObject start:selStart length:selLength];
}


// -----------------------------------------------------------------------------
//	Accessor/Mutator for how to truncate title string:
// -----------------------------------------------------------------------------

-(void)             setTruncateMode: (NSLineBreakMode)m
{
    truncateMode = m;
}


-(NSLineBreakMode)  truncateMode
{
    return truncateMode;
}


// -----------------------------------------------------------------------------
//	Accessor/Mutator for opacity of cell drawing:
// -----------------------------------------------------------------------------

-(void)             setAlpha: (float)a
{
    alpha = a;
}


-(float)            alpha
{
    return alpha;
}


// -----------------------------------------------------------------------------
//	Making sure we get the right font in the field editor:
// -----------------------------------------------------------------------------

/*-(NSText *)	setUpFieldEditorAttributes: (NSText *)textObj	// Doesn't work.
{
	textObj = [super setUpFieldEditorAttributes: textObj];
	
	NSRect		box = [self titleRectForBounds: lastUsedCellRect];
	float		sz = [self textSizeForBox: box];
	NSFont*	editFieldFont = [NSFont systemFontOfSize: sz];
	[textObj setRichText: NO];
	[textObj setFont: editFieldFont];
	[textObj setFont: editFieldFont range: NSMakeRange(0,[[textObj string] length])];
	
	return textObj;	// Must return this object and no other!
}*/


// -----------------------------------------------------------------------------
//	Querying where the title is displayed:
// -----------------------------------------------------------------------------

-(NSRect)   titleRectForBounds: (NSRect)aRect
{
    NSRect textFrame, imageFrame;
	
	lastUsedCellRect = aRect;
	
	NSDictionary*   attrs = [NSDictionary dictionaryWithObjectsAndKeys:
						[self fontAtBestSize], NSFontAttributeName,
						[NSColor controlTextColor], NSForegroundColorAttributeName,
						nil];
	
	NSSize			txSize = [[self title] sizeWithAttributes: attrs];
	
    NSDivideRect( aRect, &textFrame, &imageFrame, (UKFIC_TEXT_VERTMARGIN *2) + txSize.height,
						flags.bits.flipped ? NSMaxYEdge : NSMinYEdge);
    
    return textFrame;
}

@end

@implementation UKFinderIconCell (UKPrivateMethods)

// -----------------------------------------------------------------------------
//	Adjust text alignment for drawing so it goes nicely with the image display
//      position:
// -----------------------------------------------------------------------------

-(void) makeAlignmentConformImagePosition
{
   if( imagePosition == NSImageAbove
		|| imagePosition == NSImageBelow )
		[self setAlignment: NSCenterTextAlignment];
}


// -----------------------------------------------------------------------------
//	Mutator for flipped drawing:
// -----------------------------------------------------------------------------

-(void)             setFlipped: (BOOL)a // Is reset every time you draw this into a view.
{
    flags.bits.flipped = a;
}


-(NSFont*)	fontAtBestSize
{
	float		sz = [self textSizeForBox: lastUsedCellRect];
	return [NSFont systemFontOfSize: sz];
}

@end


// -----------------------------------------------------------------------------
//  Returns a truncated version of the specified string that fits a width:
//		Appends/Inserts three periods as an "ellipsis" to/in the string to
//      indicate when and where it was truncated.
// -----------------------------------------------------------------------------

NSString*   UKStringByTruncatingStringWithAttributesForWidth( NSString* s, NSDictionary* attrs,
                                                                float wid, NSLineBreakMode truncateMode )
{
	NSSize				txSize = [s sizeWithAttributes: attrs];
    
    if( txSize.width <= wid )   // Don't do anything if it fits.
        return s;
    
	NSMutableString*	currString = [NSMutableString string];
	NSRange             rangeToCut = { 0, 0 };
    
    if( truncateMode == NSLineBreakByTruncatingTail )
    {
        rangeToCut.location = [s length] -1;
        rangeToCut.length = 1;
    }
    else if( truncateMode == NSLineBreakByTruncatingHead )
    {
        rangeToCut.location = 0;
        rangeToCut.length = 1;
    }
    else    // NSLineBreakByTruncatingMiddle
    {
        rangeToCut.location = [s length] / 2;
        rangeToCut.length = 1;
    }
    
	while( txSize.width > wid )
	{
		if( truncateMode != NSLineBreakByTruncatingHead && rangeToCut.location <= 1 )
			return @"...";
        
        [currString setString: s];
        [currString replaceCharactersInRange: rangeToCut withString: @"..."];
		txSize = [currString sizeWithAttributes: attrs];
        rangeToCut.length++;
        if( truncateMode == NSLineBreakByTruncatingHead )
            ;   // No need to fix location, stays at start.
        else if( truncateMode == NSLineBreakByTruncatingTail )
            rangeToCut.location--;  // Fix location so range that's one longer still lies inside our string at end.
        else if( (rangeToCut.length & 1) != 1 )     // even? NSLineBreakByTruncatingMiddle
            rangeToCut.location--;  // Move location left every other time, so it grows to right and left and stays centered.
        
        if( rangeToCut.location == NSNotFound || (rangeToCut.location +rangeToCut.length) > [s length] )
            return @"...";
	}
	
	return currString;
}
