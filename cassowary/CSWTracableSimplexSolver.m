#import "CSWTracableSimplexSolver.h"

@implementation CSWTracableSimplexSolver

- (void)pivotWithEntryVariable:(CSWAbstractVariable *)entryVariable exitVariable:(CSWAbstractVariable *)exitVariable
{    
    NSLog(@"pivotWithEntryVariable: %@ exitVariable: %@", entryVariable, exitVariable);
    [super pivotWithEntryVariable:entryVariable exitVariable:exitVariable];
}

-(void)optimize: (CSWAbstractVariable*)zVariable
{
    NSLog(@"optimize: %@", zVariable);
    [super optimize: zVariable];
}

-(void)deltaEditConstant: (CSWDouble)delta plusErrorVariable: (CSWAbstractVariable*)plusErrorVariable minusErrorVariable: (CSWAbstractVariable*)minusErrorVariable
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
