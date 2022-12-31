#import <Foundation/Foundation.h>
#import "CSWTableau.h"
#import "CSWConstraint.h"
#import "CSWEditVariableManager.h"
#import "CSWSuggestion.h"

NS_ASSUME_NONNULL_BEGIN

struct ExpressionResult {
    CSWLinearExpression *expression;
    CSWVariable *minus;
    CSWVariable *plus;
    double previousConstant;
};
typedef struct ExpressionResult ExpressionResult;

extern NSString *const CSWErrorDomain;

enum CSWErrorCode {
    CSWErrorCodeRequired = 1
};

@interface CSWSimplexSolver : NSObject
{
    CSWVariable *_objective;
    int _slackCounter;
    int _dummyCounter;
    int _artificialCounter;
    int _optimizeCount;
    int _variableCounter;
    NSMapTable *_markerVariables;
    NSMapTable *_errorVariables;
    NSMutableArray *_stayMinusErrorVariables;
    NSMutableArray *_stayPlusErrorVariables;
    NSMutableArray *_addedConstraints;
    BOOL _needsSolving;
    CSWTableau *_tableau;
}

@property (nonatomic, strong) NSMapTable* _constraintAuxiliaryVariables;

@property BOOL autoSolve;

@property (nonatomic, strong) CSWEditVariableManager *editVariableManager;

-(void)addConstraint: (CSWConstraint*)constraint;

-(void)addConstraints: (NSArray*)constraints;

-(void)removeConstraint: (CSWConstraint*)constraint;

-(void)removeConstraints: (NSArray*)constraints;

-(void)suggestVariable: (CSWVariable*)varible equals: (CSWDouble)value;

-(void)suggestEditVariable: (CSWVariable*)variable equals: (CSWDouble)value;

-(void)suggestEditVariables: (NSArray*)suggestions;

-(void)suggestEditConstraint: (CSWConstraint*)constraint equals: (CSWDouble)value;

- (void)removeEditVariable: (CSWVariable*)variable;

-(void)beginEdit;

-(void)endEdit;

-(void)solve;

// If the solver is underconstrained, this method will return the primary solution and alternative solutions
-(NSArray*)solveAll;

-(void)resolve;

-(BOOL)isValid;

-(void)updateConstraint: (CSWConstraint*)constraint strength: (CSWStrength*)strength;

-(BOOL)containsConstraint: (CSWConstraint*)constraint;

-(BOOL)isMultipleSolutions;

@end

NS_ASSUME_NONNULL_END
