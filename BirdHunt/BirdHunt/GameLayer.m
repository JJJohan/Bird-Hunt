//
//  HelloWorldLayer.m
//  BirdHunt
//
//  Created by Johan Rensenbrink on 26/08/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// Import the interfaces
#import "GameLayer.h"
#import "PlayerBird.h"
//#import "Tree.h"
#import "Obstacle.h"

static void
eachShape(void *ptr, void* unused)
{
	cpShape *shape = (cpShape*) ptr;
	CCSprite *sprite = shape->data;
	if( sprite ) {
		cpBody *body = shape->body;
		
		// TIP: cocos2d and chipmunk uses the same struct to store it's position
		// chipmunk uses: cpVect, and cocos2d uses CGPoint but in reality the are the same
		// since v0.7.1 you can mix them if you want.		
		[sprite setPosition: body->p];
		
		[sprite setRotation: (float) CC_RADIANS_TO_DEGREES( -body->a )];
	}
}

// HelloWorldLayer implementation
@implementation GameLayer

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
		self.isTouchEnabled = YES;
		self.isAccelerometerEnabled = YES;
        
		wins = [[CCDirector sharedDirector] winSize];
		cpInitChipmunk();
        
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSString *finalPath = [path stringByAppendingPathComponent:@"Config.plist"];
        plistData = [[NSDictionary dictionaryWithContentsOfFile:finalPath] retain];
        birdData = [[plistData objectForKey:@"Bird"] retain];
        
        cloudSpeed = [[NSNumber numberWithFloat:[[plistData objectForKey:@"cloudSpeed"] floatValue]] floatValue];
        backgroundSpeed = [[NSNumber numberWithFloat:[[plistData objectForKey:@"backgroundSpeed"] floatValue]] floatValue];
        groundSpeed = [[NSNumber numberWithFloat:[[plistData objectForKey:@"groundSpeed"] floatValue]] floatValue];
        wingInterval = [[NSNumber numberWithFloat:[[birdData objectForKey:@"wingInterval"] floatValue]] floatValue];
        stopOnImpact = [[NSNumber numberWithBool:[[plistData objectForKey:@"stopOnImpact"] boolValue]] boolValue];
        stopSpeed = [[NSNumber numberWithFloat:[[plistData objectForKey:@"stopSpeed"] floatValue]] floatValue];
        theme = [[NSNumber numberWithInteger:[[plistData objectForKey:@"theme"] integerValue]] integerValue];
        if (theme < 1 || theme > 2) theme = 2;
        if (wingInterval < 0) wingInterval = 0;
        
		space = cpSpaceNew();
		cpSpaceResizeStaticHash(space, 400.0f, 40);
		cpSpaceResizeActiveHash(space, 100, 600);		
		space->gravity = ccp(0, 0);
		space->elasticIterations = space->iterations;
        
        cpSpaceAddCollisionHandler(space, 1, 2, BirdCollision, NULL, NULL, NULL, self);
        
        cloudList = [[NSMutableArray alloc] initWithCapacity:2];
        backgroundList = [[NSMutableArray alloc] initWithCapacity:2];
        groundList = [[NSMutableArray alloc] initWithCapacity:2];
        
        for (int i=0;i<2;i++) {
            CCSprite* cloud = [CCSprite spriteWithFile:@"cloud.png"];
            cloud.anchorPoint = ccp(0.5f,0.5f);
            [self addChild:cloud z:1];
            [cloudList addObject:[NSValue valueWithPointer:cloud]];
            
            NSString* stageBackground = [NSString stringWithFormat:@"background%i.png", theme];
            CCSprite* background = [CCSprite spriteWithFile:stageBackground];
            background.anchorPoint = ccp(0.5f,0.5f);
            [background.texture setAliasTexParameters];
            [self addChild:background z:0];
            [backgroundList addObject:[NSValue valueWithPointer:background]];
            
            NSString* stageGround = [NSString stringWithFormat:@"ground%i.png", theme];
            CCSprite* ground = [CCSprite spriteWithFile:stageGround];
            ground.anchorPoint = ccp(0.5f,0.5f);
            [self addChild:ground z:2];
            [groundList addObject:[NSValue valueWithPointer:ground]];       
        }
        
        [self Reset];
			
		[self schedule: @selector(step:)];
	}
	return self;
}

- (void) Reset
{
    touching = false;
    started = false;
    animRate = 0.0f;
    playerAlive = true;
    cloudScale = 0.5f;
    gameOver = false;
    died = false;
    backgroundFlipped = false;
    groundFlipped = false;
    speed = 0.0f;
    impactType = 0;
    
    playerBird = [[PlayerBird alloc] init:self X:240 Y:160];
    tree = [[Obstacle alloc] init:self type:1 X:-200 Y:100];
    
    for (int i=0;i<2;i++) {
        CCSprite* cloud = (CCSprite*)[[cloudList objectAtIndex:i] pointerValue];
        float cloudx = arc4random_uniform(480);
        float cloudy = arc4random_uniform(220);
        float scale = (arc4random_uniform(50));
        scale = scale / 100;
        cloud.scale = 0.5+scale+cloudScale;
        cloud.position = cpv(cloudx,100+cloudy);
        
        CCSprite* background = (CCSprite*)[[backgroundList objectAtIndex:i] pointerValue];
        background.position = cpv(-230*1.5,100);
        [background setScale:1.5f];
        
        CCSprite* ground = (CCSprite*)[[groundList objectAtIndex:i] pointerValue];
        ground.position = cpv(0,-70);
    }
    
    label = (CCLabelTTF*)[CCLabelTTF labelWithString:@"Tap to Begin" fontName:@"Marker Felt" fontSize:64];
    label.color = ccc3(0,0,0);
    
    // position the label on the center of the screen
    label.position = ccp( wins.width /2 , wins.height/2-75 );
    
    // add the label as a child to this Layer
    [self addChild: label z:4];		
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
    [tree Clear];
    [tree release];
    [playerBird Clear];
    [playerBird release];
    for (int i=0;i<2;i++) {
        CCSprite* cloud = (CCSprite*)[[cloudList objectAtIndex:i] pointerValue];
        [cloud removeFromParentAndCleanup:YES];
        CCSprite* background = (CCSprite*)[[backgroundList objectAtIndex:i] pointerValue];
        [background removeFromParentAndCleanup:YES];
        CCSprite* ground = (CCSprite*)[[groundList objectAtIndex:i] pointerValue];
        [ground removeFromParentAndCleanup:YES];       
    }
    [groundList removeAllObjects];
    [backgroundList removeAllObjects];
    [cloudList removeAllObjects];
    [groundList release];
    [backgroundList release];
    [cloudList release];
    [birdData release];
    [plistData release];
    
	// in case you have something to dealloc, do it in this method
	cpSpaceFree(space);
	space = NULL;
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

-(void) onEnter
{
	[super onEnter];
	
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / 60)];
}

-(void) step: (ccTime) delta
{
	int steps = 2;
	CGFloat dt = delta/(CGFloat)steps;
	
	for(int i=0; i<steps; i++) cpSpaceStep(space, dt);
	cpSpaceHashEach(space->activeShapes, &eachShape, nil);
	cpSpaceHashEach(space->staticShapes, &eachShape, nil);
    
    if (playerAlive) speed = (3.0f-cloudScale*3.0f)/5;
    
    if (!gameOver) {
        for (int i=0;i<[cloudList count];i++) {
            CCSprite* cloud = (CCSprite*)[[cloudList objectAtIndex:i] pointerValue];
            cloud.position = cpv(cloud.position.x-speed*cloudSpeed*dt*100,cloud.position.y);

            if (cloud.position.x < -478) {
                bool others = false;
                for (int i=0;i<[cloudList count];i++) {
                    CCSprite* cloud2 = (CCSprite*)[[cloudList objectAtIndex:i] pointerValue];
                    if (cloud2.position.x > 22) others = true;
                }
                if (!others) {
                    int x = (arc4random_uniform(40));
                    int y = (arc4random_uniform(220)); 
                    float scale = (arc4random_uniform(50));
                    scale = scale / 100;
                    cloud.position = cpv(608+x,100+y);
                    cloud.scale = 0.5+scale+cloudScale;
                }
            }
        
            if (started && cloudScale > 0.0f) {
                cloud.scale-=0.00125f;
                cloudScale-=0.00125f;
            } else if (cloudScale < 0.0f) cloudScale = 0.0f;
        }
        
        CCSprite* background1 = (CCSprite*)[[backgroundList objectAtIndex:0] pointerValue];
        CCSprite* background2 = (CCSprite*)[[backgroundList objectAtIndex:1] pointerValue]; 
        CCSprite* ground1 = (CCSprite*)[[groundList objectAtIndex:0] pointerValue];
        CCSprite* ground2 = (CCSprite*)[[groundList objectAtIndex:1] pointerValue]; 
        
        for (int i=0;i<[backgroundList count];i++) {
            CCSprite* background = (CCSprite*)[[backgroundList objectAtIndex:i] pointerValue];
            if (background.position.x < -480 * background.scale) backgroundFlipped = !backgroundFlipped;
        }
        for (int i=0;i<[groundList count];i++) {
            CCSprite* ground = (CCSprite*)[[groundList objectAtIndex:i] pointerValue];
            if (ground.position.x < -480 * ground.scale) groundFlipped = !groundFlipped;
        }

        if (!backgroundFlipped) {
            background1.position = cpv(background1.position.x-speed*backgroundSpeed*dt*100,background1.position.y);
            background2.position = ccp(background1.position.x+[background1 boundingBox].size.width-5,background2.position.y);
        } else {
            background2.position = cpv(background2.position.x-speed*backgroundSpeed*dt*100,background2.position.y);
            background1.position = ccp(background2.position.x+[background2 boundingBox].size.width-5,background1.position.y);        
        }

        if (!groundFlipped) {
            ground1.position = cpv(ground1.position.x-speed*groundSpeed*dt*100,ground1.position.y);
            ground2.position = ccp(ground1.position.x+[ground1 boundingBox].size.width-5,ground2.position.y);
        } else {
            ground2.position = cpv(ground2.position.x-speed*groundSpeed*dt*100,ground2.position.y);
            ground1.position = ccp(ground2.position.x+[ground2 boundingBox].size.width-5,ground1.position.y);        
        }

        if (started) {
            
            for (int i=0;i<[backgroundList count];i++) {
                CCSprite* background = (CCSprite*)[[backgroundList objectAtIndex:i] pointerValue];
                if (background.scale > 1.0f) [background setScale:background.scale-0.0025f];
                if (background.position.y < 160) background.position = ccp(background.position.x,background.position.y+0.7f*dt*100);
            }
            for (int i=0;i<[groundList count];i++) {
                CCSprite* ground = (CCSprite*)[[groundList objectAtIndex:i] pointerValue];
                if (ground.position.y < 35) ground.position = ccp(ground.position.x,ground.position.y+0.7f*dt*100);
            }
    
            if (cloudScale <= 0.0f) [tree Update:speed*groundSpeed delta:dt];
    
            if (!playerAlive) {
                if (stopOnImpact) {
                    if (stopSpeed != 0.0f && speed > 0.0f) {
                        speed -= stopSpeed/10;
                    } else {
                        speed = 0.0f;
                    }
                }
                if (!died) {
                    died = true;
                    [self schedule: @selector(gameOver:) interval:2.0f];
                }
                switch (impactType) {
                    case 0: // hit ground
                        [playerBird Die:speed*groundSpeed animType:impactType];
                        break;
                    case 1: // hit tree
                        [tree Impact];
                        [playerBird Die:speed*groundSpeed animType:impactType];
                        break;
                    case 2:
                        break;
                }
            } else {
                animRate+=dt;
                if (animRate > wingInterval) {
                    [playerBird Animate];
                    animRate = 0.0f;
                }
                [playerBird Bob];
                if (started) {
                    [playerBird Update:touching delta:dt];
                }
            }
        }
    }
}

- (void) gameOver: (ccTime) dt
{
    [self unschedule:_cmd];
    gameOver = true;
    [tree Clear];
    [tree release];
    [playerBird Clear];
    [playerBird release];
    [self Reset];
}

static int BirdCollision(cpArbiter *arb, cpSpace *space, void *unused)
{
    cpShape *a, *b; cpArbiterGetShapes(arb, &a, &b);
    
    GameLayer* layer = (GameLayer*)unused;
    layer->playerAlive = false;
    layer->impactType = 1;
    
    return 0;
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!started) {
        started = true;
        [self removeChild:label cleanup:YES];
    }
    touching = true;
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	/*for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];
		
		location = [[CCDirector sharedDirector] convertToGL: location];
		
		[self addNewSpriteX: location.x y:location.y];
	}*/
    
    touching = false;
}

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{	
	static float prevX=0, prevY=0;
	
#define kFilterFactor 0.05f
	
	float accelX = (float) acceleration.x * kFilterFactor + (1- kFilterFactor)*prevX;
	float accelY = (float) acceleration.y * kFilterFactor + (1- kFilterFactor)*prevY;
	
	prevX = accelX;
	prevY = accelY;
	
	CGPoint v = ccp( accelX, accelY);
	
	space->gravity = ccpMult(v, 200);
}
@end
