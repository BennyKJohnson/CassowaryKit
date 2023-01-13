
#import "CSWSimplexSolverSolution.h"
#import "CSWFloatComparator.h"

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

- (NSArray*)variables
{
    NSMutableArray *variables = [NSMutableArray array];
    for (CSWVariable *variable in [resultsByVariable keyEnumerator]) {
        [variables addObject:variable];
    }
    
    return variables;
}

-(BOOL)isEqualToSimplexSolverSolution: (CSWSimplexSolverSolution*)solution
{
    if ([[self variables] count] != [[solution variables] count]) {
        return NO;
    }
    
    for (CSWVariable *variable in [self variables]) {
        if (![self solution:solution hasEqualResultForVariable:variable]) {
            return NO;
        }
    }
    
    return YES;
}

-(BOOL)solution:(CSWSimplexSolverSolution*)solution hasEqualResultForVariable: (CSWVariable*)variable
{
    NSNumber *lhsResult = [self resultForVariable:variable];
    NSNumber *rhsResult = [solution resultForVariable:variable];
    
    BOOL hasResultForBoth = lhsResult != nil && rhsResult != nil;
    BOOL hasTheSameResultForBoth = [CSWFloatComparator isApproxiatelyEqual:[lhsResult floatValue] b:[rhsResult floatValue]];
    return hasResultForBoth && hasTheSameResultForBoth;
}

@end
