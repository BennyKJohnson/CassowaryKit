#import "CSWSimplexSolver.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWSimplexSolver (PrivateMethods)

-(void)dualOptimize;

-(void)deltaEditConstant: (CSWDouble)delta plusErrorVariable: (CSWAbstractVariable*)plusErrorVariable minusErrorVariable: (CSWAbstractVariable*)minusErrorVariable;

-(void)optimize: (CSWAbstractVariable*)zVariable;

-(void)pivotWithEntryVariable: (CSWAbstractVariable*)entryVariable exitVariable: (CSWAbstractVariable*)exitVariable;

-(CSWAbstractVariable*)choseSubject: (CSWLinearExpression*)expression;

@end

NS_ASSUME_NONNULL_END
