//
//  PlayerBird.m
//  BirdHunt
//
//  Created by Johan Rensenbrink on 26/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PlayerBird.h"

@implementation PlayerBird

- (id)init:(GameLayer*)layer X:(float)x Y:(float)y
{
    self = [super init];
    if (self) {
        body = nil;
        shape = nil;
        text1 = [[CCTextureCache sharedTextureCache] addImage:@"bird1.png"];
        text2 = [[CCTextureCache sharedTextureCache] addImage:@"bird2.png"];
        sprite = [CCSprite spriteWithTexture:text1];
        bob = 0.0f;
        scale = 1.0f;
        animCycle = false;
        died = false;
        lastPos = CGPointMake(0,0);
        localDelta = 0.0f;
        localLayer = layer;      
        
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSString *finalPath = [path stringByAppendingPathComponent:@"Config.plist"];
        plistData = [[NSDictionary dictionaryWithContentsOfFile:finalPath] retain];
        birdData = [[plistData objectForKey:@"Bird"] retain];
        
        bobAmount = [[NSNumber numberWithFloat:[[birdData objectForKey:@"bobAmount"] floatValue]] floatValue];
        bobSpeed = [[NSNumber numberWithFloat:[[birdData objectForKey:@"bobSpeed"] floatValue]] floatValue];
        rotSpeed = [[NSNumber numberWithFloat:[[birdData objectForKey:@"rotSpeed"] floatValue]] floatValue];
        maxRot = [[NSNumber numberWithFloat:[[birdData objectForKey:@"maxRotRadians"] floatValue]] floatValue];
        backDistance = [[NSNumber numberWithInteger:[[birdData objectForKey:@"backDistance"] integerValue]] integerValue];
        upDownSpeed = [[NSNumber numberWithFloat:[[birdData objectForKey:@"upDownSpeed"] floatValue]] floatValue];
        canHitGround = [[NSNumber numberWithBool:[[birdData objectForKey:@"canHitGround"] boolValue]] boolValue];
        
        [self addNewSpriteX:x y:y];
    }
    
    return self;
}

-(void) addNewSpriteX: (float)x y:(float)y
{
    sprite = (CCSprite*)[CCSprite spriteWithFile:@"bird1.png"];
    sprite.anchorPoint = ccp(0.5f,0.5f);
    [localLayer addChild:sprite z:4];
	sprite.position = ccp(x,y);
	
	int num = 4;
	CGPoint verts[] = {
		ccp(-13,-17),
		ccp(-13,16),
		ccp(11,15),
		ccp(11,-18),
	};
	
	body = cpBodyNew(1.0f, cpMomentForPoly(1.0f, num, verts, CGPointZero));
	body->p = ccp(x, y);
	cpSpaceAddBody(localLayer->space, body);
	
	shape = cpPolyShapeNew(body, num, verts, CGPointZero);
	shape->e = 0.5f; shape->u = 0.5f;
	shape->data = sprite;
    shape->collision_type = 1;
	cpSpaceAddShape(localLayer->space, shape);
}

-(void) Die:(float)speed animType:(int)type
{
    NSString *imageFile;
    int xSize,ySize,xFrames,yFrames;
    switch (type) {
        case 0: // ground impact
        case 1: // tree impact
            xSize = 90;
            ySize = 73;
            xFrames = 2;
            yFrames = 3;
            imageFile = @"animCloud.png";
            break;
        case 2:
            break;
    }
    animFrames = [[NSMutableArray alloc] initWithCapacity:xFrames*yFrames];
    animImage = [[CCTextureCache sharedTextureCache] addImage:imageFile];
    for (int x=0;x<xFrames;x++) {
        for (int y=0;y<yFrames;y++) {
            CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:animImage rect:CGRectMake(xSize*x, ySize*y, xSize, ySize)];
            [animFrames addObject:frame];
        }
    }
    
    if (!died) {        
        CCAnimation *animation = [CCAnimation animationWithFrames:animFrames delay:0.1f];		
		[sprite runAction:[CCAnimate actionWithAnimation:animation restoreOriginalFrame:NO]];
        
        died = true;
    } else {      
        body->p = cpv(body->p.x-(speed * localDelta * 100),body->p.y);
    }
}

-(void) Clear
{
    shape->data = nil;
    [sprite removeFromParentAndCleanup:YES];
    [animFrames release];
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
    
    cpSpaceRemoveBody(localLayer->space, body);
    cpSpaceRemoveShape(localLayer->space, shape);       
    cpBodyDestroy(body);
    cpShapeDestroy(shape);
    
    [birdData release];
    [plistData release];
}

-(void) Animate
{
    if (animCycle) {
        [sprite setTexture:text1];
        animCycle = false;
    } else {
        [sprite setTexture:text2];
        animCycle = true;
    }
}

-(void) Bob
{
    sprite.position = cpv(sprite.position.x,sprite.position.y+cos(bob)*bobAmount);
    bob+=(bobSpeed * localDelta * 100);
}

-(void) Update:(bool)Up delta:(CGFloat)delta
{
    localDelta = delta;
    lastPos = body->p;
    if (body->p.x > backDistance) body->p = cpv(body->p.x-1.0f,body->p.y);
    if (Up) {
        if(body->p.y < 270) body->p = cpv(body->p.x,body->p.y+(upDownSpeed * localDelta * 100));
        if (scale > 0.5f) {
            [sprite setScale:scale];
            scale-=0.0025f;
        }
    } else {
        if (!canHitGround) {
            if (body->p.y > 80) body->p = cpv(body->p.x,body->p.y-(upDownSpeed * localDelta * 100));
        } else {
            if (localLayer->cloudScale > 0.0f) {
                if (body->p.y > 80) body->p = cpv(body->p.x,body->p.y-(upDownSpeed * localDelta * 100));
            } else {
                body->p = cpv(body->p.x,body->p.y-(upDownSpeed * localDelta * 100));
                if (body->p.y < 50) localLayer->playerAlive = false;
            }
        }
        if (scale > 0.5f) {
            [sprite setScale:scale];
            scale-=0.0025f;
        }
    }
    
    if (lastPos.y < body->p.y && body->a < maxRot) body->a += (rotSpeed * localDelta * 100);
    else if (lastPos.y > body->p.y && body->a > -maxRot) body->a -= (rotSpeed * localDelta * 100);
    else if (lastPos.y == body->p.y && body->a < 0.0f) body->a += (rotSpeed * localDelta * 100);
    else if (lastPos.y == body->p.y && body->a > 0.0f) body->a -= (rotSpeed * localDelta * 100);
}

@end
