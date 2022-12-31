
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

@end
