
#import "CSWTableauConstraintConverter.h"
#import "CSWVariable+PrivateMethods.h"

@implementation CSWTableauConstraintConverter

- (instancetype)init
{
    self = [super init];
    if (self) {
        _slackCounter = 0;
        _dummyCounter = 0;
        _variableCounter = 0;
        _constraintAuxiliaryVariables = [NSMapTable weakToStrongObjectsMapTable];
    }
    return self;
}

/** Make a new linear expression representing the constraint c,
 ** replacing any basic variables with their defining expressions.
 * Normalize if necessary so that the constant is non-negative.  If
 * the constraint is non-required, give its error variables an
 * appropriate weight in the objective function. */
-(CSWLinearExpression*)createExpression: (CSWConstraint *)constraint expressionResult: (ExpressionResult*)expressionResult tableau: (CSWTableau*)tableau objective: (CSWVariable*)_objective
{
    CSWLinearExpression *constraintExpression = [constraint expression];
    
    CSWLinearExpression *newExpression = [[CSWLinearExpression alloc] init];
    [newExpression setConstant:[constraintExpression constant]];
    
    for (CSWVariable *term in constraintExpression.termVariables) {
        CSWDouble termCoefficient = [[constraintExpression multiplierForTerm: term] doubleValue];
        CSWLinearExpression *rowExpression = [tableau rowExpressionForVariable:term];
        if ([tableau isBasicVariable:term]) {
            [tableau addNewExpression:rowExpression toExpression:newExpression n:termCoefficient subject:nil];
        } else {
            [tableau addVariable:term toExpression:newExpression withCoefficient:termCoefficient subject:nil];
        }
    }
    
    ExpressionResult *result = expressionResult;
    result->expression = nil;
    result->minus = nil;
    result->plus = nil;
    result->marker = nil;

    if ([_constraintAuxiliaryVariables objectForKey:constraint] == nil) {
        [_constraintAuxiliaryVariables setObject:[NSMutableDictionary dictionary] forKey:constraint];
    }
    
    if ([constraint isInequality]) {
        [self applyInequityConstraint:constraint newExpression:newExpression tableau:tableau result: &result objective: _objective];
    } else {
        [self applyConstraint:constraint newExpression:newExpression result:&result tableau:tableau _objective:_objective];
    }
    
    // the Constant in the Expression should be non-negative. If necessary
    // normalize the Expression by multiplying by -1
    if (newExpression.constant < 0) {
        [newExpression normalize];
    }
    
    return newExpression;
}

- (void)applyConstraint:(CSWConstraint *)constraint newExpression:(CSWLinearExpression *)newExpression result:(ExpressionResult **)result tableau: (CSWTableau*)tableau _objective: (CSWVariable*)_objective {
    CSWLinearExpression *constraintExpression = [constraint expression];
    NSMutableDictionary *constraintAuxiliaryVariables = [_constraintAuxiliaryVariables objectForKey:constraint];

    if ([constraint isRequired]) {
        CSWVariable *dummyVariable;
        if (constraintAuxiliaryVariables[@"d"] != nil) {
            dummyVariable = constraintAuxiliaryVariables[@"d"];
        } else {
            dummyVariable = [self dummyVariableForConstraint: constraint];
            constraintAuxiliaryVariables[@"d"] = dummyVariable;
        }

        (*result)->plus = dummyVariable;
        (*result)->minus = dummyVariable;
        (*result)->previousConstant = constraintExpression.constant;
        [tableau setVariable:dummyVariable onExpression:newExpression withCoefficient:1];
        (*result)->marker = dummyVariable;
    } else {
        // cn is a non-required equality. Add a positive and a negative error
        // variable, making the resulting constraint
        //       expr = eplus - eminus
        // in other words:
        //       expr - eplus + eminus = 0
        
        _slackCounter++;
        CSWVariable *eplusVariable = [self slackVariableForConstraint:constraint prefix:@"ep"];
        CSWVariable *eminusVariable = [self slackVariableForConstraint:constraint prefix:@"em"];
                
        [tableau setVariable:eplusVariable onExpression:newExpression withCoefficient:-1];
        [tableau setVariable:eminusVariable onExpression:newExpression withCoefficient:1];
        
        CSWLinearExpression *zRow = [tableau rowExpressionForVariable: _objective];
        CSWDouble swCoefficient = [constraint.strength value];
        
        [tableau setVariable:eplusVariable onExpression:zRow withCoefficient:swCoefficient];
        [tableau addMappingFromExpressionVariable:eplusVariable toRowVariable:_objective];
        
        [tableau setVariable:eminusVariable onExpression:zRow withCoefficient:swCoefficient];
        [tableau addMappingFromExpressionVariable:eminusVariable toRowVariable:_objective];
        
        (*result)->marker = eplusVariable;
        (*result)->plus = eplusVariable;
        (*result)->minus = eminusVariable;
        (*result)->previousConstant = constraintExpression.constant;
    }
}

/*
// Add a slack variable. The original constraint
// is expr>=0, so that the resulting equality is expr-slackVar=0. If cn is
// also non-required Add a negative error variable, giving:
//
//    expr - slackVar = -errorVar
//
// in other words:
//
//    expr - slackVar + errorVar = 0
//
// Since both of these variables are newly created we can just Add
// them to the Expression (they can't be basic).
*/
- (void)applyInequityConstraint:(CSWConstraint *)constraint newExpression:(CSWLinearExpression *)newExpression tableau: (CSWTableau*)tableau result:(ExpressionResult **)result objective: (CSWVariable*)_objective {
  _slackCounter++;
  CSWVariable *slackVariable = [self createSlackVariableWithPrefix:@"s"];
  [tableau setVariable:slackVariable onExpression:newExpression withCoefficient:-1];
  
  (*result)->marker = slackVariable;
  
  if (![constraint isRequired]) {
      CSWVariable *eminusSlackVariable = [self createSlackVariableWithPrefix:@"em"];
      [newExpression addVariable:eminusSlackVariable coefficient:1];
      
      CSWDouble eminusCoefficient = [constraint.strength value];
      CSWLinearExpression *zRow = [tableau rowExpressionForVariable: _objective];
      [tableau setVariable:eminusSlackVariable onExpression:zRow withCoefficient: eminusCoefficient];
      // TODO check this no test hits this code
      (*result)->minus = eminusSlackVariable;
      [tableau addMappingFromExpressionVariable:eminusSlackVariable toRowVariable: _objective];
  }
}

-(CSWVariable*)slackVariableForConstraint: (CSWConstraint*)constraint prefix: (NSString*)prefix
{
    NSMutableDictionary *constraintAuxiliaryVariables = [_constraintAuxiliaryVariables objectForKey:constraint];

    if (constraintAuxiliaryVariables[prefix] != nil) {
        return constraintAuxiliaryVariables[prefix];
    } else {
        CSWVariable *slackVariable = [self createSlackVariableWithPrefix:prefix];
        constraintAuxiliaryVariables[prefix] = slackVariable;
        return slackVariable;
    }
}

-(CSWVariable*)createSlackVariableWithPrefix: (NSString*)prefix
{
    CSWVariable *slackVariable = [CSWVariable slackVariableWithName:[NSString stringWithFormat:@"%@%d", prefix, _slackCounter]];
    // [[CSWSlackVariable alloc] initWithName:[NSString stringWithFormat:@"%@%d", prefix, _slackCounter]];
    slackVariable.id = [self getNextVariableId];
    _variableCounter++;
    return slackVariable;
}

-(CSWVariable*)dummyVariableForConstraint: (CSWConstraint*)constraint
{
    NSMutableDictionary *constraintAuxiliaryVariables = [_constraintAuxiliaryVariables objectForKey:constraint];
    if (constraintAuxiliaryVariables[@"d"] != nil) {
        return constraintAuxiliaryVariables[@"d"];
    }
    
    _dummyCounter++;
    CSWVariable *dummyVariable = [CSWVariable dummyVariableWithName:[NSString stringWithFormat:@"d%d", _dummyCounter]];
    constraintAuxiliaryVariables[@"d"] = dummyVariable;
    
    return dummyVariable;
}

-(NSUInteger)getNextVariableId
{
    return ++_variableCounter;
}

@end
