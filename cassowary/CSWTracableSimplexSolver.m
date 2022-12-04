#import "CSWTracableSimplexSolver.h"

@implementation CSWTracableSimplexSolver

- (void)pivotWithEntryVariable:(CSWVariable *)entryVariable exitVariable:(CSWVariable *)exitVariable
{    
    NSLog(@"pivotWithEntryVariable: %@ exitVariable: %@", entryVariable, exitVariable);
    [super pivotWithEntryVariable:entryVariable exitVariable:exitVariable];
}

-(void)optimize: (CSWVariable*)zVariable
{
    NSLog(@"optimize: %@", zVariable);
    [super optimize: zVariable];
}

-(void)deltaEditConstant: (CSWDouble)delta plusErrorVariable: (CSWVariable*)plusErrorVariable minusErrorVariable: (CSWVariable*)minusErrorVariable
{
    NSLog(@"deltaEditConstant: %f plusErrorVariable: %@ minusErrorVariable: %@", delta, plusErrorVariable, minusErrorVariable);
    [super deltaEditConstant:delta plusErrorVariable:plusErrorVariable minusErrorVariable:minusErrorVariable];
}

-(void)dualOptimize
{
    NSLog(@"dualOptimize");
    [super dualOptimize];
}

@end
