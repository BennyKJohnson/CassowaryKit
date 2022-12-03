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

-(void)suggestVariable: (CSWAbstractVariable*)varible equals: (CSWDouble)value;

-(void)suggestEditVariable: (CSWAbstractVariable*)variable equals: (CSWDouble)value;

-(void)suggestEditVariables: (NSArray*)suggestions;

-(void)suggestEditConstraint: (CSWConstraint*)constraint equals: (CSWDouble)value;

- (void)removeEditVariable: (CSWAbstractVariable*)variable;

-(void)beginEdit;

-(void)endEdit;

-(void)solve;

-(void)resolve;

-(BOOL)isValid;

-(void)updateConstraint: (CSWConstraint*)constraint strength: (CSWStrength*)strength weight: (CSWDouble)weight;

-(void)updateConstraint: (CSWConstraint*)constraint strength: (CSWStrength*)strength;

-(void)updateConstraint: (CSWConstraint*)constraint weight: (CSWDouble)weight;

-(BOOL)containsConstraint: (CSWConstraint*)constraint;

@property BOOL autoSolve;

@property (nonatomic, strong) CSWEditVariableManager *editVariableManager;

@end

NS_ASSUME_NONNULL_END
