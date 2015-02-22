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

#import <Cocoa/Cocoa.h>


// -----------------------------------------------------------------------------
//  Constants:
// -----------------------------------------------------------------------------

#define UKFIC_TEXT_VERTMARGIN		1		// How many pixels is selection supposed to extend above and below the title?
#define UKFIC_TEXT_HORZMARGIN		1		// How many pixels is selection supposed to extend to the left and right of the title?
#define UKFIC_SELBOX_VERTMARGIN		1		// How much distance do you want between top of cell/title and icon's highlight box?
#define UKFIC_SELBOX_HORZMARGIN		1		// How much distance do you want between right/left edges of cell and icon's highlight box?
#define UKFIC_SELBOX_OUTLINE_WIDTH  1		// Width of outline of selection box around icon.
#define UKFIC_IMAGE_VERTMARGIN		2		// Distance between maximum top/bottom edges of image and highlight box.
#define UKFIC_IMAGE_HORZMARGIN		2		// Distance between maximum left/right edges of image and highlight box.


// -----------------------------------------------------------------------------
//  Data Structures:
// -----------------------------------------------------------------------------

typedef union UKFICFlags
{
    struct {
        unsigned int    selected:1;         // Is this cell currently selected?
        unsigned int    flipped:1;          // Cached isFlipped from the view we're drawn in.
        unsigned int    currentlyEditing:1; // Currently being inline-edited?
        unsigned int    drawSeparator:1;    // Draw a separator line at the top of this cell?
        unsigned int    unusedFlags:28;
    } bits;
    int     allFlags;
} UKFICFlags;


// -----------------------------------------------------------------------------
//  Class declaration:
// -----------------------------------------------------------------------------

@interface UKFinderIconCell : NSTextFieldCell
{
	NSString*			info;			// Description text to display under image. (NYI)
	NSImage*			image;			// Icon to display for this item.
	NSColor*			nameColor;		// Color to use for name. Defaults to white.
	NSColor*			boxColor;		// Color to use for the box around the icon (when highlighted). Defaults to grey.
	NSColor*			selectionColor; // Color to use for background of the highlighted name. Defaults to blue.
	NSColor*			bgColor;        // Color to use for background of the cell. Defaults to none.
	NSCellImagePosition imagePosition;  // Image position relative to title.
    NSLineBreakMode     truncateMode;   // Truncate string left, middle or right if it's wider than cell?
    float               alpha;          // Opacity.
	UKFICFlags          flags;          // Boolean flags and properties of this cell.
	NSRect				lastUsedCellRect;	// Rect last used to draw this cell. Needed because when we set up font size, we don't know our rect.
    id                  reserved1;
    id                  reserved2;
    id                  reserved3;
    id                  reserved4;
}

-(id)		init;
-(id)		initTextCell: (NSString*)img;
//-(id)		initImageCell: (NSImage*)img;	// Designated initializer.

-(void)		setHighlighted: (BOOL)isSelected;
-(BOOL)     isHighlighted;

-(void)		drawInteriorWithFrame: (NSRect)box inView: (NSView*)aView;

-(void)		setNameColor: (NSColor*)col;
-(NSColor*) nameColor;

-(void)		setBoxColor: (NSColor*)col;
-(NSColor*) boxColor;

-(void)		setSelectionColor: (NSColor*)col;
-(NSColor*) selectionColor;

-(void)		setBgColor: (NSColor*)col;
-(NSColor*) bgColor;

-(void)		resetColors;

-(void)             setTruncateMode: (NSLineBreakMode)m;
-(NSLineBreakMode)  truncateMode;

-(void)             setAlpha: (float)a;
-(float)            alpha;

-(BOOL)             isFlipped;

-(void)             setDrawSeparator: (BOOL)isSelected;
-(BOOL)             drawSeparator;


// Accessing image:
//setImage: and image are inherited from NSCell.
-(NSCellImagePosition)  imagePosition;
-(void)					setImagePosition: (NSCellImagePosition)newImagePosition;	// Currently, only "above" and "below" work.

@end


// -----------------------------------------------------------------------------
//  Functions:
// -----------------------------------------------------------------------------

// Truncate a string by inserting an ellipsis ("..."). truncateMode can be NSLineBreakByTruncatingHead, NSLineBreakByTruncatingMiddle or NSLineBreakByTruncatingTail.
NSString*   UKStringByTruncatingStringWithAttributesForWidth( NSString* s,
                                                                NSDictionary* attrs,
                                                                float wid,
                                                                NSLineBreakMode truncateMode );
