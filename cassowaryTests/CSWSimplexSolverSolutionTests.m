
#import <XCTest/XCTest.h>
#import "CSWSimplexSolverSolution.h"
#import "CSWVariable.h"

@interface CSWSimplexSolverSolutionTests : XCTestCase

@end

@implementation CSWSimplexSolverSolutionTests

-(void)testCanAddAndRetrieveVariableResultToResult {
    CSWSimplexSolverSolution *result = [[CSWSimplexSolverSolution alloc] init];
    CSWVariable *var = [CSWVariable variable];
    [result setResult:10 forVariable: var];
    
    NSNumber *varResult = [result resultForVariable: var];
    XCTAssertNotNil(varResult);
    XCTAssertEqual([varResult floatValue], 10);
}

-(void)testisEqualToSimplexSolverSolutionWhenNotEqual {
    CSWVariable *variable = [CSWVariable variable];

    CSWSimplexSolverSolution *lhs = [[CSWSimplexSolverSolution alloc] init];
    [lhs setResult:10 forVariable:variable];
    
    CSWSimplexSolverSolution *rhs = [[CSWSimplexSolverSolution alloc] init];
    [rhs setResult:20 forVariable:variable];
    
    XCTAssertFalse([lhs isEqualToSimplexSolverSolution: rhs]);
}

-(void)testIsEqualWhenComparingEmptySolutions
{
    CSWSimplexSolverSolution *lhs = [[CSWSimplexSolverSolution alloc] init];
    CSWSimplexSolverSolution *rhs = [[CSWSimplexSolverSolution alloc] init];
    XCTAssertTrue([lhs isEqualToSimplexSolverSolution: rhs]);
}

-(void)testIsEqualWhenComparingEqualVariable
{
    CSWVariable *variable = [CSWVariable variable];

    CSWSimplexSolverSolution *lhs = [[CSWSimplexSolverSolution alloc] init];
    [lhs setResult:10 forVariable:variable];

    CSWSimplexSolverSolution *rhs = [[CSWSimplexSolverSolution alloc] init];
    [rhs setResult:10 forVariable:variable];

    XCTAssertTrue([lhs isEqualToSimplexSolverSolution: rhs]);
}

-(void)testIsNotEqualWithVariableWithDifferentResult
{
    CSWVariable *x = [CSWVariable variable];
    CSWVariable *y = [CSWVariable variable];

    CSWSimplexSolverSolution *lhs = [[CSWSimplexSolverSolution alloc] init];
    [lhs setResult:10 forVariable: x];
    [lhs setResult:5 forVariable: y];

    
    CSWSimplexSolverSolution *rhs = [[CSWSimplexSolverSolution alloc] init];
    [rhs setResult:10 forVariable: x];
    [rhs setResult:6 forVariable: y];
    
    XCTAssertFalse([lhs isEqualToSimplexSolverSolution: rhs]);
}

-(void)testIsEqualWithMultipleVariablesWithTheSameResult
{
    CSWVariable *x = [CSWVariable variable];
    CSWVariable *y = [CSWVariable variable];

    CSWSimplexSolverSolution *lhs = [[CSWSimplexSolverSolution alloc] init];
    [lhs setResult:10 forVariable: x];
    [lhs setResult:5 forVariable: y];

    
    CSWSimplexSolverSolution *rhs = [[CSWSimplexSolverSolution alloc] init];
    [rhs setResult:10 forVariable: x];
    [rhs setResult:5 forVariable: y];
    
    XCTAssertTrue([lhs isEqualToSimplexSolverSolution: rhs]);
}

-(void)testIsNotEqualWithDifferentVariables
{
    CSWVariable *x = [CSWVariable variable];
    CSWVariable *y = [CSWVariable variable];
    CSWVariable *z = [CSWVariable variable];
    
    CSWSimplexSolverSolution *lhs = [[CSWSimplexSolverSolution alloc] init];
    [lhs setResult:10 forVariable: x];
    [lhs setResult:5 forVariable: y];
    
    CSWSimplexSolverSolution *rhs = [[CSWSimplexSolverSolution alloc] init];
    [rhs setResult:10 forVariable: x];
    [rhs setResult:5 forVariable: y];
    [rhs setResult:1 forVariable:z];
    
    XCTAssertFalse([lhs isEqualToSimplexSolverSolution: rhs]);
}

@end
