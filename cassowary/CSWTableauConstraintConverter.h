
#import <Foundation/Foundation.h>
#import "CSWConstraint.h"
#import "CSWVariable.h"
#import "CSWTableau.h"

NS_ASSUME_NONNULL_BEGIN

struct ExpressionResult {
    CSWLinearExpression *expression;
    CSWVariable *minus;
    CSWVariable *plus;
    CSWVariable *marker;
    double previousConstant;
};
typedef struct ExpressionResult ExpressionResult;

@interface CSWTableauConstraintConverter : NSObject
{
    int _slackCounter;
    int _dummyCounter;
    int _variableCounter;
    NSMapTable* _constraintAuxiliaryVariables;
}

-(CSWLinearExpression*)createExpression: (CSWConstraint *)constraint expressionResult: (ExpressionResult*)expressionResult tableau: (CSWTableau*)tableau objective: (CSWVariable*)_objective;

@end

NS_ASSUME_NONNULL_END
