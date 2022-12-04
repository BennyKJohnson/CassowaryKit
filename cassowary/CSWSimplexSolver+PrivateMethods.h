#import "CSWSimplexSolver.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWSimplexSolver (PrivateMethods)

-(void)dualOptimize;

-(void)deltaEditConstant: (CSWDouble)delta plusErrorVariable: (CSWVariable*)plusErrorVariable minusErrorVariable: (CSWVariable*)minusErrorVariable;

-(void)optimize: (CSWVariable*)zVariable;

-(void)pivotWithEntryVariable: (CSWVariable*)entryVariable exitVariable: (CSWVariable*)exitVariable;

-(CSWVariable*)choseSubject: (CSWLinearExpression*)expression;

@end

NS_ASSUME_NONNULL_END
