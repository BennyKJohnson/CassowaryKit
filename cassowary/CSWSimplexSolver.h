//
//  CSWSimplexSolver.h
//  cassowary
//
//  Created by Benjamin Johnson on 10/11/22.
//  Copyright © 2022 Benjamin Johnson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSWTableau.h"
#import "CSWConstraint.h"
#import "CSWObjectiveVariable.h"
#import "CSWEditVariableManager.h"
#import "CSWSuggestion.h"

NS_ASSUME_NONNULL_BEGIN

struct ExpressionResult {
    CSWLinearExpression *expression;
    CSWAbstractVariable *minus;
    CSWAbstractVariable *plus;
    double previousConstant;
};
typedef struct ExpressionResult ExpressionResult;

extern NSString *const CSWErrorDomain;

enum CSWErrorCode {
    CSWErrorCodeRequired = 1
};

@interface CSWSimplexSolver : CSWTableau
{
    CSWObjectiveVariable *_objective;
    int _slackCounter;
    int _dummyCounter;
    int _artificialCounter;
    int _optimizeCount;
    int _variableCounter;
    NSMapTable *_markerVariables;
    NSMapTable *_errorVariables;
    NSMutableArray *_stayMinusErrorVariables;
    NSMutableArray *_stayPlusErrorVariables;
    BOOL _needsSolving;
}

-(void)addConstraint: (CSWConstraint*)constraint;

-(void)addConstraints: (NSArray*)constraints;

-(void)removeConstraint: (CSWConstraint*)constraint;

-(void)removeConstraints: (NSArray*)constraints;

-(void)beginEdit;

-(void)endEdit;

-(void)suggestVariable: (CSWAbstractVariable*)varible equals: (CSWDouble)value;

-(void)suggestEditVariable: (CSWAbstractVariable*)variable equals: (CSWDouble)value;

-(void)suggestEditVariables: (NSArray*)suggestions;

-(void)suggestEditConstraint: (CSWConstraint*)constraint equals: (CSWDouble)value;

- (void)removeEditVariable: (CSWAbstractVariable*)variable;

-(CSWAbstractVariable*)choseSubject: (CSWLinearExpression*)expression;

-(void)pivotWithEntryVariable: (CSWAbstractVariable*)entryVariable exitVariable: (CSWAbstractVariable*)exitVariable;

-(void)optimize: (CSWAbstractVariable*)zVariable;

-(void)solve;

-(void)resolve;

-(BOOL)isValid;

-(void)updateConstraint: (CSWConstraint*)constraint strength: (CSWStrength*)strength weight: (CSWDouble)weight;

-(void)updateConstraint: (CSWConstraint*)constraint strength: (CSWStrength*)strength;

-(BOOL)containsConstraint: (CSWConstraint*)constraint;

-(void)updateConstraint: (CSWConstraint*)constraint weight: (CSWDouble)weight;

-(void)deltaEditConstant: (CSWDouble)delta plusErrorVariable: (CSWAbstractVariable*)plusErrorVariable minusErrorVariable: (CSWAbstractVariable*)minusErrorVariable;

@property BOOL autoSolve;

@property (nonatomic, strong) CSWEditVariableManager *editVariableManager;

-(void)dualOptimize;

@end

NS_ASSUME_NONNULL_END
