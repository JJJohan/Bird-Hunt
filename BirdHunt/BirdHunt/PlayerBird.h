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
@interface PlayerBird : NSObject
{
@public
	cpBody* body;
    cpShape* shape;
    CCSprite* sprite;
    CCTexture2D* text1;
    CCTexture2D* text2;
    CCTexture2D* animImage;
    GameLayer* localLayer;
    float bob;
    float scale;
    bool animCycle;
    bool died;
    NSMutableArray* animFrames;
    NSDictionary* plistData;
    NSDictionary* birdData;
    CGPoint lastPos;
    float bobSpeed;
    float bobAmount;
    float maxRot;
    float rotSpeed;
    int backDistance;
    float upDownSpeed;
    float localDelta;
    bool canHitGround;
}

-(id) init:(GameLayer*)layer X:(float)x Y:(float)y;
-(void) addNewSpriteX: (float)x y:(float)y;
-(void) Bob;
-(void) Update:(bool)Up delta:(CGFloat)delta;
-(void) Animate;
-(void) Die:(float)speed animType:(int)type;
-(void) Clear;

@end
