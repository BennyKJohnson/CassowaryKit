
#import <Foundation/Foundation.h>
#import "CSWVariable.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWSimplexSolverSolution : NSObject

-(void)setResult: (CGFloat)result forVariable: (CSWVariable*)variable;

-(NSNumber*)resultForVariable: (CSWVariable*)variable;

- (NSArray*)variables;

-(BOOL)isEqualToSimplexSolverSolution: (CSWSimplexSolverSolution*)solution;

@end

NS_ASSUME_NONNULL_END
