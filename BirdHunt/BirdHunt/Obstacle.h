//
//  HelloWorldLayer.h
//  BirdHunt
//
//  Created by Johan Rensenbrink on 26/08/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

// Importing Chipmunk headers
#import "chipmunk.h"

#import <Foundation/NSObject.h>
#include "GameLayer.h"

// HelloWorldLayer
@interface Obstacle : NSObject
{
@public
	cpBody* body;
    cpShape* shape;
    CCSprite* sprite;
    float scale;
    NSDictionary* plistData;
    int obstacleChance;
    CCTexture2D* animImage;
    NSMutableArray* animFrames;
    bool playerDead;
    GameLayer* localLayer;
    float localDelta;
}

-(id) init:(GameLayer*)layer type:(int)type X:(float)x Y:(float)y;
-(void) addNewSpriteX: (float)x y:(float)y verts:(CGPoint[])verts;
-(void) Update:(float)speed delta:(CGFloat)delta;
-(void) Clear;
-(void) Impact;

@end
