
#import "CSWSimplexSolverSolution.h"

@implementation CSWSimplexSolverSolution
{
    NSMapTable *resultsByVariable;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        resultsByVariable = [NSMapTable strongToStrongObjectsMapTable];
    }
    return self;
}

-(void)setResult: (CGFloat)result forVariable: (CSWVariable*)variable
{
    NSNumber *encodedResult = [NSNumber numberWithFloat:result];
    [resultsByVariable setObject:encodedResult forKey:variable];
}

-(NSNumber*)resultForVariable: (CSWVariable*)variable;
{
    return [resultsByVariable objectForKey:variable];
}

@end
