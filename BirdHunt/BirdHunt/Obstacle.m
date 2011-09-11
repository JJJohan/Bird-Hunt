//
//  PlayerBird.m
//  BirdHunt
//
//  Created by Johan Rensenbrink on 26/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Obstacle.h"

@implementation Obstacle

- (id)init:(GameLayer*)layer type:(int)type X:(float)x Y:(float)y
{
    self = [super init];
    if (self) {
        body = nil;
        shape = nil;
        sprite = nil;
        scale = 1.0f;       
        playerDead = false;
        localDelta = 0.0f;
        localLayer = layer;
        
        NSString *imageFile;
        int xSize,ySize;
        CGPoint verts[4];
        
        switch (type) {
            case 1: // tree
                xSize = 180;
                ySize = 190;
                imageFile = @"treeAnim.png";
                verts[0] = ccp(16.0f,-60.5f);
                verts[1] = ccp(-42.0f,43.5f);
                verts[2] = ccp(52.0f,46.5f);
                verts[3] = ccp(86.0f,-59.5f);
                break;
            case 2:
                break;
        }
        
        animImage = [[CCTextureCache sharedTextureCache] addImage:imageFile];
        animFrames = [[NSMutableArray alloc] initWithCapacity:6];
        
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSString *finalPath = [path stringByAppendingPathComponent:@"Config.plist"];
        plistData = [[NSDictionary dictionaryWithContentsOfFile:finalPath] retain];
        obstacleChance = [[NSNumber numberWithInteger:[[plistData objectForKey:@"obstacleChance"] integerValue]] integerValue];
        if (obstacleChance < 1) obstacleChance = 1;
        
        for (int x=0;x<3;x++) {
            for (int y=0;y<2;y++) {
                CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:animImage rect:CGRectMake(xSize*x, ySize*y, xSize, ySize)];
                [animFrames addObject:frame];
            }
        }
        
        sprite = (CCSprite*)[CCSprite spriteWithSpriteFrame:(CCSpriteFrame*)[animFrames objectAtIndex:0]];
        [sprite retain];
        
        [self addNewSpriteX:x y:y verts:verts];
    }
    
    return self;
}

-(void) addNewSpriteX: (float)x y:(float)y verts:(CGPoint[])verts
{
    sprite.anchorPoint = ccp(0.5f,0.5f);
    [localLayer addChild: sprite z:3];
	sprite.position = ccp(x,y);
    
	int num = 4;
	body = cpBodyNew(INFINITY, cpMomentForPoly(INFINITY, num, verts, CGPointZero));
	body->p = ccp(x, y);
	cpSpaceAddBody(localLayer->space, body);
	
	shape = cpPolyShapeNew(body, num, verts, CGPointZero);
	shape->e = 0.5f; shape->u = 0.5f;
	shape->data = sprite;
    shape->collision_type = 2;
	cpSpaceAddShape(localLayer->space, shape);
}

-(void) Update:(float)speed delta:(CGFloat)delta
{
    localDelta = delta;
    if (body->p.x > -[sprite boundingBox].size.width/2*scale) {
        body->p = cpv(body->p.x-(speed * localDelta * 100),body->p.y);
    } else {
        int chance = arc4random_uniform(obstacleChance);
        if (chance == 0) {
            body->p = cpv(480+[sprite boundingBox].size.width/2*scale,body->p.y);
        }
    }
}

-(void) Impact
{
    if (!playerDead) {
        CCAnimation *animation = [CCAnimation animationWithFrames:animFrames delay:0.1f];		
        [sprite runAction:[CCAnimate actionWithAnimation:animation restoreOriginalFrame:YES]];
        playerDead = true;
    }
}

-(void) Clear
{
    [sprite removeFromParentAndCleanup:YES];
    cpSpaceRemoveBody(localLayer->space, body);
    cpSpaceRemoveShape(localLayer->space, shape);    
    cpShapeDestroy(shape);   
    cpBodyDestroy(body);
}

@end
