//
// Menu Demo
// a cocos2d example
// http://www.cocos2d-iphone.org
//


#import "MenuLayer.h"

enum {
	kTagMenu = 1,
	kTagMenu0 = 0,
	kTagMenu1 = 1,
};

#pragma mark -
#pragma mark MainMenu

@implementation MenuLayer
-(id) init
{
	if( (self=[super init])) {
        
		[CCMenuItemFont setFontSize:30];
		[CCMenuItemFont setFontName: @"Courier New"];
        
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
        self.isTouchEnabled = YES;
#endif
		// Label Item (CCLabelBMFont)
		CCLabelBMFont *playLabel = [CCLabelBMFont labelWithString:@"Play" fntFile:@"bitmapFontTest3.fnt"];
		CCMenuItemLabel *play = [CCMenuItemLabel itemWithLabel:playLabel target:self selector:@selector(menuCallback:)];
		
		// Testing issue #500
		play.scale = 0.8f;
        
		CCMenu *menu = [CCMenu menuWithItems: play, nil];
		[menu alignItemsVertically];
		
		
		// elastic effect
		CGSize s = [[CCDirector sharedDirector] winSize];
		int i=0;
		for( CCNode *child in [menu children] ) {
			CGPoint dstPoint = child.position;
			int offset = s.width/2 + 50;
			if( i % 2 == 0)
				offset = -offset;
			child.position = ccp( dstPoint.x + offset, dstPoint.y);
			[child runAction: 
			 [CCEaseElasticOut actionWithAction:
			  [CCMoveBy actionWithDuration:2 position:ccp(dstPoint.x - offset,0)]
										 period: 0.35f]
             ];
			i++;
		}
        
		[self addChild: menu];
	}
    
	return self;
}

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
-(void) registerWithTouchDispatcher
{
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:kCCMenuTouchPriority+1 swallowsTouches:YES];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	return YES;
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
}

-(void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
}

#endif
-(void) dealloc
{
	[disabledItem release];
	[super dealloc];
}

-(void) menuCallback: (id) sender
{
	[(CCLayerMultiplex*)parent_ switchTo:1];
}

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
-(void) allowTouches
{
    [[CCTouchDispatcher sharedDispatcher] setPriority:kCCMenuTouchPriority+1 forDelegate:self];
    [self unscheduleAllSelectors];
	NSLog(@"TOUCHES ALLOWED AGAIN");
    
}
#endif

@end