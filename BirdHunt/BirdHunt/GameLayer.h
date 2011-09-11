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

@class PlayerBird;
@class Obstacle;

// HelloWorldLayer
@interface GameLayer : CCLayer
{
@public
 	cpSpace *space;
    bool playerAlive;
    float cloudScale;  
    
@private
    PlayerBird* playerBird;
    Obstacle* tree;
    NSMutableArray *cloudList;
    NSMutableArray *groundList;
    NSMutableArray *backgroundList;
    NSDictionary *plistData;
    NSDictionary *birdData;
    bool touching;
    bool started;
    bool died;
    bool gameOver;
    CCLabelTTF* label;
    CGSize wins;
    float animRate;
    bool groundFlipped;
    bool backgroundFlipped;
    float speed;
    float cloudSpeed;
    float groundSpeed;
    float backgroundSpeed;
    float wingInterval;
    bool stopOnImpact;
    float stopSpeed;
    int theme;
    int impactType;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
-(void) step: (ccTime) dt;
-(void) gameOver: (ccTime) dt;
-(void) Reset;
static int BirdCollision(cpArbiter *arb, cpSpace *space, void *unused);

@end
