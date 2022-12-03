#import <XCTest/XCTest.h>
#import "CSWLinearExpression.h"
#import "CSWVariable.h"
#import "CSWSlackVariable.h"

@interface ClLinearExpressionTests : XCTestCase

@end

@implementation ClLinearExpressionTests

- (void)testInit {
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    XCTAssertEqual([[expression terms] count], 0);
    XCTAssertEqual([expression constant], 0);
}

-(void)testInitWithVariableCoefficientAndConstant
{
    CSWVariable *variable = [[CSWVariable alloc] init];
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] initWithVariable:variable coefficient:5 constant:10];
    
    XCTAssertTrue([expression isKindOfClass:[CSWLinearExpression class]]);
    XCTAssertEqual([expression coefficientForTerm:variable], 5);
    XCTAssertEqual(expression.constant, 10);
}

- (void)testAddVariableUpdatesTermsWithCoefficent
{
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    CSWVariable *variable = [[CSWVariable alloc] initWithValue:5.0];
    
    [expression addVariable: variable coefficient: 1.0];
}

-(void)testMultiplyConstantAndTermsBy
{
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    [expression setConstant:5.0];
    CSWVariable *x = [[CSWVariable alloc] initWithValue:1.0];
    CSWVariable *y = [[CSWVariable alloc] initWithValue:1.0];
    [expression addVariable:x coefficient:1];
    [expression addVariable:y coefficient:5];
    
    [expression multiplyConstantAndTermsBy:2.0];
    XCTAssertEqual(expression.constant, 10);
}

-(void)testNewSubjectModifiesExpressionToSetNewSubjectEqualToExpression
{
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    [expression setConstant:2.0];
    CSWVariable *subject = [[CSWVariable alloc] init];
    CSWVariable *x = [[CSWVariable alloc] init];
    CSWVariable *y = [[CSWVariable alloc] init];
    
    [expression addVariable:x coefficient:1.0];
    [expression addVariable:y coefficient:5.0];
    [expression addVariable:subject coefficient:2.0];
    
    [expression newSubject:subject];
    
    // Drops new subject term
    XCTAssertFalse([expression isTermForVariable:subject]);
    
    // Multiplies by reciprocal of coefficent of subject
    XCTAssertEqual([[expression multiplierForTerm:y] floatValue], -2.5);
    XCTAssertEqual([[expression multiplierForTerm:x] floatValue], -0.5);
    XCTAssertEqual(expression.constant, -1.0);
}

-(void)testIsConstantWithNoTerms
{
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    XCTAssertTrue([expression isConstant]);
}

-(void)testIsNotConstantWhenExpressionHasTerms
{
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    CSWVariable *term = [[CSWVariable alloc] init];
    [expression addVariable:term coefficient:5];
    
    XCTAssertFalse([expression isConstant]);
}

-(void)testAnyPivotableVariableThrowsExceptionWhenIsConstant
{
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    [expression setConstant:10];
    
    XCTAssertThrowsSpecificNamed([expression anyPivotableVariable], NSException, NSInternalInconsistencyException);
}

-(void)testAnyPivotableVariableReturnsNothingWhenNoPivotableVariables
{
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    [expression setConstant:2];
    
    CSWVariable *a = [[CSWVariable alloc] initWithValue:10];
    [expression addVariable:a coefficient:10];
    XCTAssertNil([expression anyPivotableVariable]);
}

-(void)testAnyPivotableVariableReturnsPivotableVariableInExpression
{
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    [expression setConstant:2];
    
    CSWVariable *a = [[CSWVariable alloc] initWithValue:10];
    CSWSlackVariable *pivotableVariable = [[CSWSlackVariable alloc] init];
    
    [expression addVariable:a coefficient:10];
    [expression addVariable:pivotableVariable coefficient:2];
    
    XCTAssertEqual([expression anyPivotableVariable], pivotableVariable);
}

-(void)testAddExpressionAppendsConstantAndTerms
{
    CSWLinearExpression *existingExpression = [[CSWLinearExpression alloc] init];
    existingExpression.constant = 10;
    
    CSWVariable *a = [[CSWVariable alloc] init];
    CSWVariable *b = [[CSWVariable alloc] init];
    [existingExpression addVariable:a];
    [existingExpression addVariable:b];
    
    CSWVariable *c = [[CSWVariable alloc] init];
    CSWVariable *d = [[CSWVariable alloc] init];
    CSWLinearExpression *newExpressiopn = [[CSWLinearExpression alloc] initWithConstant:15];
    [newExpressiopn addVariable:c coefficient:3];
    [newExpressiopn addVariable:d coefficient:4];

    
    [existingExpression addExpression:newExpressiopn];
    XCTAssertEqual(existingExpression.constant, 25);
    
    // Keeps existing terms
    XCTAssertEqual([existingExpression coefficientForTerm:a], 1);
    XCTAssertEqual([existingExpression coefficientForTerm:b], 1);

    XCTAssertEqual([existingExpression coefficientForTerm:c], 3);
    XCTAssertEqual([existingExpression coefficientForTerm:d], 4);
}

@end