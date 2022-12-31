#import <XCTest/XCTest.h>
#import "CSWTableau.h"
#import "CSWVariable.h"
#import "CSWLinearExpression.h"

@interface CSWTableauTests : XCTestCase

@end

@implementation CSWTableauTests

-(void)assertTableMapping:(CSWTableau*)table  fromExpressionVariable: (CSWVariable*)expressionVariable toRowVariable: (CSWVariable*)rowVariable
{
    NSSet *columns = [table columnForVariable:expressionVariable];
    XCTAssertNotNil(columns);
    XCTAssertTrue([columns containsObject:rowVariable]);
}

-(void)testCanAddRow
{
    CSWTableau *tableau = [[CSWTableau alloc] init];
    CSWVariable *variable = [CSWVariable variableWithValue:0 name:@"var"];
    CSWVariable *anotherVariable = [CSWVariable variableWithValue:0 name:@"y"];
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    [expression addVariable:anotherVariable coefficient:1.0];
    [tableau addRowForVariable: variable equalsExpression: expression];
    
    XCTAssertTrue([tableau hasRowForVariable:variable]);
    
    [self assertTableMapping:tableau fromExpressionVariable:anotherVariable toRowVariable:variable];
}

-(void)testRemoveRowThrowsExceptionIfNoExpressionExistsForVariable
{
    CSWTableau *tableau = [[CSWTableau alloc] init];
    CSWVariable *missingVariable = [CSWVariable variableWithValue:0 name:@"missingVar"];
    XCTAssertThrowsSpecificNamed([tableau removeRowForVariable: missingVariable], NSException, NSInvalidArgumentException);
}

-(void)testCanRemoveRow
{
    CSWTableau *tableau = [[CSWTableau alloc] init];
    CSWVariable *variable = [CSWVariable variableWithValue:0 name:@"var"];
    CSWVariable *anotherVariable = [CSWVariable variableWithValue:0 name:@"y"];
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    [expression addVariable:anotherVariable coefficient:1.0];
    [tableau addRowForVariable: variable equalsExpression: expression];
    
    [tableau removeRowForVariable:variable];
    
    XCTAssertNil([tableau rowExpressionForVariable:variable]);
    
    NSSet *columns = [tableau columnForVariable:anotherVariable];
    XCTAssertNotNil(columns);
    XCTAssertFalse([columns containsObject:variable]);
}

-(void)testSubstituteOutRemovesVarFromColumns
{
    CSWTableau *tableau = [[CSWTableau alloc] init];
    
    CSWVariable *yVariable = [CSWVariable variableWithValue:2 name:@"y"];
    CSWVariable *xVariable = [CSWVariable variableWithValue:4 name:@"x"];
    CSWVariable *zVariable = [CSWVariable variableWithValue:6 name:@"z"];

    CSWLinearExpression *yExpression = [[CSWLinearExpression alloc] init];
    [yExpression addVariable:xVariable coefficient:1.0];
    CSWLinearExpression *zExpression = [[CSWLinearExpression alloc] init];
    [zExpression addVariable:zVariable coefficient:1.0];
    
    [tableau addRowForVariable: yVariable equalsExpression: yExpression];
    
    [tableau substituteOutVariable: xVariable forExpression: zExpression];
    
    [self assertTableMapping:tableau fromExpressionVariable:zVariable toRowVariable:yVariable];
    
    XCTAssertNil([tableau columnForVariable:xVariable]);
}

-(void)testSubstituteOutRemovesExpressionTermFromColumns
{
    CSWTableau *tableau = [[CSWTableau alloc] init];
    
    CSWVariable *yVariable = [CSWVariable variableWithValue:2 name:@"y"];
    CSWVariable *xVariable = [CSWVariable variableWithValue:4 name:@"x"];
    CSWVariable *zVariable = [CSWVariable variableWithValue:-2 name:@"z"];

    CSWLinearExpression *yExpression = [[CSWLinearExpression alloc] init];
    [yExpression addVariable:xVariable coefficient:1.0];
    [yExpression addVariable:zVariable coefficient:1.0];
    CSWLinearExpression *zExpression = [[CSWLinearExpression alloc] init];
    [zExpression addVariable:zVariable coefficient:-1.0];
    
    [tableau addRowForVariable: yVariable equalsExpression: yExpression];
    
    [tableau substituteOutVariable: xVariable forExpression: zExpression];
    
    NSSet *columns = [tableau columnForVariable:zVariable];
    XCTAssertFalse([yExpression isTermForVariable:zVariable]);
    XCTAssertFalse([columns containsObject: yVariable]);
}

-(void)testSubstituteOutRemovesExpressionTermFromColumns1
{
    CSWTableau *tableau = [[CSWTableau alloc] init];
    
    CSWVariable *yVariable = [CSWVariable variableWithValue:0 name:@"y"];
    CSWVariable *xVariable = [CSWVariable variableWithValue:0 name:@"x"];
    CSWVariable *zVariable = [CSWVariable variableWithValue:0 name:@"z"];

    CSWLinearExpression *yExpression = [[CSWLinearExpression alloc] init];
    [yExpression addVariable:xVariable coefficient:1.0];
    [yExpression addVariable:zVariable coefficient:1.0];
    CSWLinearExpression *zExpression = [[CSWLinearExpression alloc] init];
    [zExpression addVariable:zVariable coefficient:-0.99];
    
    [tableau addRowForVariable: yVariable equalsExpression: yExpression];
    
    [tableau substituteOutVariable: xVariable forExpression: zExpression];
    
    NSSet *columns = [tableau columnForVariable:zVariable];
    CSWDouble coefficient = [yExpression coefficientForTerm:zVariable];
    XCTAssertEqualWithAccuracy(coefficient, 0.01, 0.00001);
    XCTAssertTrue([columns containsObject: yVariable]);
}

-(void)testIsBasicVariableIsTrueWhenVariableHasRow
{
    CSWTableau *tableau = [[CSWTableau alloc] init];
    CSWVariable *variable = [[CSWVariable alloc] init];
    [tableau addRowForVariable:variable equalsExpression:[[CSWLinearExpression alloc] init]];
    
    XCTAssertTrue([tableau isBasicVariable: variable]);
}

-(void)testIsNotBasicVariableWhenVariableIsNotARow
{
    CSWTableau *tableau = [[CSWTableau alloc] init];
    CSWVariable *variable = [[CSWVariable alloc] init];
    XCTAssertFalse([tableau isBasicVariable:variable]);
}


-(void)testAddVariableWithoutCoefficientHasImplicitCoefficientOf1
{
    CSWTableau *tableau = [[CSWTableau alloc] init];
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    CSWVariable *expressionVariable = [[CSWVariable alloc] init];
    [tableau addRowForVariable:expressionVariable equalsExpression:expression];
    
    CSWVariable *variable = [CSWVariable variableWithValue:20];
    [tableau addVariable:variable toExpression:expression];

    NSNumber *coefficient = [expression multiplierForTerm:variable];
    XCTAssertEqual([coefficient floatValue], 1);
}

-(void)testAddingSameVariableTwiceWithCoefficient
{
    CSWTableau *tableau = [[CSWTableau alloc] init];
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    CSWVariable *expressionVariable = [[CSWVariable alloc] init];
    [tableau addRowForVariable:expressionVariable equalsExpression:expression];
    
    CSWVariable *variable = [CSWVariable variableWithValue:20];
    [tableau addVariable:variable toExpression:expression];
    [tableau addVariable:variable toExpression:expression withCoefficient: 2];
    
    NSNumber *coefficient = [expression multiplierForTerm:variable];
    XCTAssertEqual([coefficient floatValue], 3);
}

-(void)testAddingSameVariableWithACoefficientWhichZerosOutPreviousCoefficientRemovesVariableFromExpression
{
    CSWTableau *tableau = [[CSWTableau alloc] init];
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    CSWVariable *expressionVariable = [[CSWVariable alloc] init];
    [tableau addRowForVariable:expressionVariable equalsExpression:expression];
    
    CSWVariable *variable = [CSWVariable variableWithValue:20];
    [tableau addVariable:variable toExpression:expression withCoefficient:4];
    [tableau addVariable:variable toExpression:expression withCoefficient: -4];
    
    NSNumber *coefficient = [expression multiplierForTerm:variable];
    XCTAssertNil(coefficient);
}

-(void)testAddingVariableWithZeroCoefficientToExpressionDoesNotAddVariableToExpression
{
    CSWTableau *tableau = [[CSWTableau alloc] init];
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    CSWVariable *expressionVariable = [[CSWVariable alloc] init];
    [tableau addRowForVariable:expressionVariable equalsExpression:expression];
    CSWVariable *variable = [[CSWVariable alloc] init];
    [tableau addVariable:variable toExpression:expression withCoefficient:0];
    XCTAssertNil([expression multiplierForTerm:variable]);
}

-(void)testSetVariableWithNewVariable
{
    CSWTableau *tableau = [[CSWTableau alloc] init];
    CSWVariable *b = [CSWVariable variableWithValue:20];
    
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    [expression setConstant:2];
    [tableau setVariable:b onExpression:expression withCoefficient:2];
    XCTAssertEqual([expression coefficientForTerm:b], 2);
}

-(void)testSetVariableWithExistingVariable
{
    CSWTableau *tableau = [[CSWTableau alloc] init];
    CSWVariable *a = [CSWVariable variableWithValue:10];
    
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] initWithVariable:a];
    [tableau setVariable:a onExpression:expression withCoefficient:10];
    [tableau setVariable:a onExpression:expression withCoefficient:5];
    XCTAssertEqual([expression coefficientForTerm:a], 5);
}

-(void)testRemoveColumn
{
    CSWTableau *tableau = [[CSWTableau alloc] init];
    
    CSWVariable *rowVariable = [[CSWVariable alloc] init];
    CSWVariable *columnVariable = [[CSWVariable alloc] init];
    
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    [expression addVariable:columnVariable coefficient:1];
    [tableau addRowForVariable:rowVariable equalsExpression:expression];
                                       
    [tableau removeColumn:columnVariable];
    
    // Should remove column mapping
    XCTAssertNil([tableau columnForVariable:columnVariable]);
    
    // Should remove column variable from expression terms
    XCTAssertFalse([expression isTermForVariable:columnVariable]);
}

@end
