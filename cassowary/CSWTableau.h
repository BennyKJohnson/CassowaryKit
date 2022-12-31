#import <Foundation/Foundation.h>
#import "CSWVariable.h"
#import "CSWLinearExpression.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWTableau : NSObject
{
    NSMutableSet *externalParametricVariables;

    NSMapTable *rows;

    NSMapTable *columns;
}

@property (nonatomic, strong) NSMutableSet *updatedExternals;

@property (nonatomic, strong) NSMapTable *externalRows;

@property (nonatomic, strong) NSMutableArray *infeasibleRows;

-(void) addRowForVariable: (CSWVariable*)variable equalsExpression:(CSWLinearExpression*)expression;

-(void) removeRowForVariable: (CSWVariable*)variable;

-(BOOL) hasRowForVariable: (CSWVariable*)variable;

-(void) substituteOutVariable: (CSWVariable*)variable forExpression:(CSWLinearExpression*)expression;

-(void) substituteOutTerm: (CSWVariable*)term withExpression:(CSWLinearExpression*)newExpression inExpression: (CSWLinearExpression*)expression subject: (CSWVariable*)subject;

-(BOOL) isBasicVariable: (CSWVariable*)variable;

-(void)addVariable: (CSWVariable*)variable toExpression: (CSWLinearExpression*)expression;

-(void)addVariable: (CSWVariable*)variable toExpression: (CSWLinearExpression*)expression withCoefficient: (CSWDouble)coefficient;

-(void)addVariable: (CSWVariable*)variable toExpression: (CSWLinearExpression*)expression withCoefficient: (CSWDouble)coefficient subject: (CSWVariable* _Nullable)subject;

-(void)setVariable: (CSWVariable*)variable onExpression: (CSWLinearExpression*)expression withCoefficient: (CSWDouble)coefficient;

-(void)addNewExpression: (CSWLinearExpression*)newExpression toExpression: (CSWLinearExpression*)existingExpression n: (CSWDouble)n subject: (nullable CSWVariable*)subject;

-(void)addNewExpression: (CSWLinearExpression*)newExpression toExpression: (CSWLinearExpression*)existingExpression;

-(void)addMappingFromExpressionVariable: (CSWVariable*)columnVariable toRowVariable: (CSWVariable*)rowVariable;

-(void)removeColumn: (CSWVariable*)variable;

-(BOOL)hasColumnForVariable: (CSWVariable*)variable;

-(NSSet*)columnForVariable: (CSWVariable*)variable;

-(CSWLinearExpression*)rowExpressionForVariable: (CSWVariable*)variable;

-(void)changeSubjectOnExpression: (CSWLinearExpression*)expression existingSubject:(CSWVariable*)existingSubject newSubject: (CSWVariable*)newSubject;

-(void)pivotWithEntryVariable: (CSWVariable*)entryVariable exitVariable: (CSWVariable*)exitVariable;

-(BOOL)hasInfeasibleRows;

- (BOOL)containsExternalParametricVariableForEveryExternalTerm;

- (BOOL)containsExternalRowForEachExternalRowVariable;

-(NSArray*)substitedOutNonBasicPivotableVariables: (CSWVariable*)objective;

- (CSWVariable*)findPivotableExitVariable:(CSWVariable *)entryVariable;

- (CSWVariable*)findExitVariableForEquationWhichMinimizesRatioOfRestrictedVariables:(CSWVariable *)constraintMarkerVariable;

@end

NS_ASSUME_NONNULL_END
