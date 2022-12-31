#import <XCTest/XCTest.h>
#import "CSWSimplexSolver.h"
#import "CSWVariable.h"
#import "CSWVariable+PrivateMethods.h"
#import "CSWSimplexSolver+PrivateMethods.h"
#import "CSWConstraintFactory.h"
#import "CSWTierWeightedStrength.h"

@interface CSWSimplexSolverTests : XCTestCase

@end

@implementation CSWSimplexSolverTests
{
    CSWSimplexSolver *solver;
}

- (void)setUp
{
    [super setUp];
    solver = [[CSWSimplexSolver alloc] init];
}

-(NSArray*)createStayConstraintsForVariables: (NSArray*)variables
{
    NSMutableArray *stayConstraints = [NSMutableArray array];
    for (CSWVariable *variable in variables) {
        [stayConstraints addObject:[[CSWConstraint alloc] initStayConstraintWithVariable:variable strength:[CSWStrength strengthWeak]]];
    }
    
    return stayConstraints;
}

-(void)addStayConstraintsForVariables: (NSArray*)variables solver: (CSWSimplexSolver*)solver {
    NSArray *stayConstraints = [self createStayConstraintsForVariables:variables];
    for (CSWConstraint *stayConstraint in stayConstraints) {
        [solver addConstraint:stayConstraint];
    }
}

-(void)addEditConstraintsForVariables: (NSArray*)variables solver: (CSWSimplexSolver*)solver {
    for (CSWVariable *variable in variables) {
        CSWConstraint *editConstraint = [[CSWConstraint alloc] initEditConstraintWithVariable:variable stength:[CSWStrength strengthStrong]];
        [solver addConstraint:editConstraint];
    }
}

-(CSWSimplexSolver*)autoSolver
{
    solver.autoSolve = YES;
    return solver;
}

-(void) testCanAddConstraint
{
    CSWVariable *y = [CSWVariable variableWithValue:2];
    
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    [expression addVariable:y coefficient:1.0];
    
    CSWConstraint *equation = [[CSWConstraint alloc] initLinearConstraintWithExpression: [[CSWLinearExpression alloc] initWithVariable:y]];
    
    [solver addConstraint: equation];
}

-(void)testSolvesCorrectlyAfterAddingConstraint
{
    CSWVariable *x = [CSWVariable variableWithValue:0];
    
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] initWithVariable:x coefficient:-1 constant:10];
    [solver addConstraint:[[CSWConstraint alloc] initLinearConstraintWithExpression: expression]];
    
    [solver solve];
    XCTAssertEqual(x.value, 10);
}

-(void)testChooseSubjectReturnsNilIfNoVariablesInExpression
{
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    CSWVariable *variable = [solver choseSubject:expression];
    XCTAssertNil(variable);
}

-(void)testChooseSubjectReturnsFirstExternalUnrestrictedVariable
{
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] init];
    CSWVariable *dummyVariable = [CSWVariable dummyVariableWithName:@"dummy"];
    CSWVariable *externalVariable = [CSWVariable variableWithValue:1.0];
    [expression addVariable:dummyVariable coefficient:1.0];
    [expression addVariable:externalVariable coefficient:1.0];
    
    CSWVariable *variable = [solver choseSubject:expression];
    XCTAssertEqual(variable, externalVariable);
}

-(void)testSolvesSimple1TestCaseWithXTermAddedFirst
{
    CSWVariable *x = [CSWVariable variableWithValue: 167];
    CSWVariable *y = [CSWVariable variableWithValue:2];

    [self addStayConstraintsForVariables:@[x, y] solver:solver];
    CSWConstraint *eq =  [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightVariable:y];
    
    [solver addConstraint:eq];
    [solver solve];
    XCTAssertEqual(x.value, 2);
    XCTAssertEqual(y.value, 2);
}

-(void)testSolvesSimple1TestCaseWithYTermAddedFirst
{
    CSWVariable *x = [CSWVariable variableWithValue: 167];
    CSWVariable *y = [CSWVariable variableWithValue:2];

    [self addStayConstraintsForVariables:@[x, y] solver:solver];
    CSWConstraint *eq = [CSWConstraint constraintWithLeftVariable:y operator:CSWConstraintOperatorEqual rightVariable:x];

    [solver addConstraint:eq];
    [solver solve];
    XCTAssertEqual(x.value, 167);
    XCTAssertEqual(y.value, 167);
}

-(void)testAddStayConstraints
{
    CSWVariable *x = [CSWVariable variableWithValue:5];
    CSWVariable *y = [CSWVariable variableWithValue:10];
    
    CSWConstraint *stayConstraintX = [[CSWConstraint alloc] initStayConstraintWithVariable:x strength:[CSWStrength strengthWeak]];
    CSWConstraint *stayConstraintY = [[CSWConstraint alloc] initStayConstraintWithVariable:y strength:[CSWStrength strengthWeak]];
    
    [solver addConstraints:@[stayConstraintX, stayConstraintY]];
    [solver solve];
    XCTAssertEqualWithAccuracy(x.value, 5.0, 0.0001);
    XCTAssertEqualWithAccuracy(y.value, 10.0, 0.0001);
}

-(void)testSolvesNumberEqualsVar
{
    CSWVariable *x = [CSWVariable variableWithValue:10];
    CSWConstraint *equation = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:100];
    [solver addConstraint:equation];
    [solver solve];
    
    XCTAssertEqual(x.value, 100);
}

-(void)testSolvesVarIsGreaterThanOrEqualToValue
{
    CSWVariable *x = [CSWVariable variableWithValue:10];
    CSWConstraint *ieq = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:200];
    
    [solver addConstraint:ieq];
    [solver solve];
    XCTAssertEqual(x.value, 200);
}

-(void)testSolvesVarIsLessThanOrEqualToValue
{
    CSWVariable *x = [CSWVariable variableWithValue:10];
    CSWConstraint *ieq = [CSWConstraint constraintWithLeftConstant:100 operator:CSWConstraintOperatorLessThanOrEqual rightVariable:x];
    [solver addConstraint:ieq];
    [solver solve];
    
    XCTAssertEqual(x.value, 100);
}

-(void)testSolvesExpressionIsEqualToVariable
{
    CSWVariable *x = [CSWVariable variableWithValue:10];
    CSWVariable *width = [CSWVariable variableWithValue:10];
    CSWVariable *rightMin = [CSWVariable variableWithValue:100];
    
    CSWLinearExpression *right = [[CSWLinearExpression alloc] initWithVariable:x];
    [right addVariable:width];
    
    CSWConstraint *equation = [[CSWConstraint alloc] initLinearConstraintWithExpression:right];
    [equation.expression addVariable:rightMin coefficient:-1];
    
    CSWConstraint *stayConstraintWidth = [[CSWConstraint alloc] initStayConstraintWithVariable:width strength:[CSWStrength strengthWeak]];

    CSWConstraint *stayConstraintRightMin = [[CSWConstraint alloc] initStayConstraintWithVariable:rightMin strength:[CSWStrength strengthWeak]];
    
    [solver addConstraints:@[stayConstraintWidth, stayConstraintRightMin, equation]];
    [solver solve];
    
    XCTAssertEqual(width.value, 10);
    XCTAssertEqual(x.value, 90);
}

-(void)testSolvesExpressionIsGreaterThanOrEqualToVariable
{
    CSWVariable *x = [CSWVariable variableWithValue:10];
    CSWVariable *width = [CSWVariable variableWithValue:10];
    CSWVariable *rightMin = [CSWVariable variableWithValue:100];
    
    CSWLinearExpression *right = [[CSWLinearExpression alloc] initWithVariable:x];
    [right addVariable:width];
    
    CSWConstraint *ieq = [CSWConstraint constraintWithLeftExpression:right operator:CSWConstraintOperationGreaterThanOrEqual rightVariable:rightMin];
    CSWConstraint *stayConstraintWidth = [[CSWConstraint alloc] initStayConstraintWithVariable:width strength:[CSWStrength strengthWeak]];
     CSWConstraint *stayConstraintRightMin = [[CSWConstraint alloc] initStayConstraintWithVariable:rightMin strength:[CSWStrength strengthWeak]];
    
    [solver addConstraints:@[stayConstraintWidth, stayConstraintRightMin, ieq]];
    [solver solve];

    XCTAssertEqual(x.value, 90);
    XCTAssertEqual(width.value, 10);
}

-(void)testSolvesVariableIsLessThanOrEqualToExpression
{
    CSWSimplexSolver *solver = [self autoSolver];
    
     CSWVariable *x = [CSWVariable variableWithValue:10];
     CSWVariable *width = [CSWVariable variableWithValue:10];
     CSWVariable *rightMin = [CSWVariable variableWithValue:100];
     
     CSWLinearExpression *right = [[CSWLinearExpression alloc] initWithVariable:x];
     [right addVariable:width];
    
    CSWConstraint *ieq = [CSWConstraint constraintWithLeftVariable:rightMin operator:CSWConstraintOperatorLessThanOrEqual rightExpression:right];
    CSWConstraint *stayConstraintWidth = [[CSWConstraint alloc] initStayConstraintWithVariable:width strength:[CSWStrength strengthWeak]];
     CSWConstraint *stayConstraintRightMin = [[CSWConstraint alloc] initStayConstraintWithVariable:rightMin strength:[CSWStrength strengthWeak]];
        
    [solver addConstraints:@[stayConstraintWidth, stayConstraintRightMin, ieq]];

    XCTAssertEqual(x.value, 90);
    XCTAssertEqual(width.value, 10);
}

-(void)testSolvesExpressionIsEqualToExpression
{
    CSWSimplexSolver *solver = [self autoSolver];
    CSWVariable *x1 = [CSWVariable variableWithValue:10];
    CSWVariable *width1 = [CSWVariable variableWithValue:10];
    
    CSWLinearExpression *right1 = [[CSWLinearExpression alloc] initWithVariable:x1];
    [right1 addVariable:width1];
    
    CSWVariable *x2 = [CSWVariable variableWithValue:100];
    CSWVariable *width2 = [CSWVariable variableWithValue:10];
    CSWLinearExpression *right2 = [[CSWLinearExpression alloc] initWithVariable:x2];
    [right2 addVariable:width2];
    
    CSWConstraint *eq = [CSWConstraint constraintWithLeftExpression:right1 operator:CSWConstraintOperatorEqual rightExpression:right2];
    CSWConstraint *stayConstraintWidth1 = [[CSWConstraint alloc] initStayConstraintWithVariable:width1 strength:[CSWStrength strengthWeak]];
    CSWConstraint *stayConstraintWidth2 = [[CSWConstraint alloc] initStayConstraintWithVariable:width2 strength:[CSWStrength strengthWeak]];
    CSWConstraint *stayConstraintX2 = [[CSWConstraint alloc] initStayConstraintWithVariable:x2 strength:[CSWStrength strengthWeak]];

    [solver addConstraints:@[stayConstraintWidth1, stayConstraintWidth2, stayConstraintX2, eq]];
    
    XCTAssertEqual(x1.value, 100);
    XCTAssertEqual(x2.value, 100);
    XCTAssertEqual(width1.value, 10);
    XCTAssertEqual(width2.value, 10);
}

-(void)testSolvesExpressionIsLessThanOrEqualToExpression
{
    CSWVariable *x1 = [CSWVariable variableWithValue:10];
    CSWVariable *width1 = [CSWVariable variableWithValue:10];
      
    CSWLinearExpression *right1 = [[CSWLinearExpression alloc] initWithVariables: @[x1, width1]];

    CSWVariable *x2 = [CSWVariable variableWithValue:100];
    CSWVariable *width2 = [CSWVariable variableWithValue:10];
    CSWLinearExpression *right2 = [[CSWLinearExpression alloc] initWithVariables:@[x2, width2]];
      
    CSWConstraint *ieq = [CSWConstraint constraintWithLeftExpression:right2 operator:CSWConstraintOperatorLessThanOrEqual rightExpression:right1];
    
    [self addStayConstraintsForVariables:@[width1, width2, x2] solver:solver];
    [solver addConstraint:ieq];
    
    [solver solve];
    
    XCTAssertEqual(x1.value, 100);
}

-(void)testSolvesExpressionIsGreaterThanOrEqualToExpression
{
    CSWVariable *x1 = [CSWVariable variableWithValue:10];
    CSWVariable *width1 = [CSWVariable variableWithValue:10];
      
    CSWLinearExpression *right1 = [[CSWLinearExpression alloc] initWithVariables: @[x1, width1]];

    CSWVariable *x2 = [CSWVariable variableWithValue:100];
    CSWVariable *width2 = [CSWVariable variableWithValue:10];
    CSWLinearExpression *right2 = [[CSWLinearExpression alloc] initWithVariables:@[x2, width2]];
      
    CSWConstraint *ieq = [CSWConstraint constraintWithLeftExpression:right1 operator:CSWConstraintOperationGreaterThanOrEqual rightExpression:right2];
    
    [self addStayConstraintsForVariables:@[width1, width2, x2] solver:solver];
    [solver addConstraint:ieq];
    
    [solver solve];
    
    XCTAssertEqual(x1.value, 100);
}

-(void)testSolvesAfterRemovingConstraint
{
    CSWSimplexSolver *solver = [self autoSolver];
    CSWVariable *x = [CSWVariable variable];
    
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] initWithVariable: x coefficient:-1 constant:100];
    
    CSWConstraint *constraint = [[CSWConstraint alloc] initLinearConstraintWithExpression:expression strength:[CSWStrength strengthWeak] variable:nil];
    [solver addConstraint:constraint];
        
    CSWConstraint *c10 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorLessThanOrEqual rightConstant:10];
    [solver addConstraint:c10];
    
    CSWConstraint *c20 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorLessThanOrEqual rightConstant:20];
    [solver addConstraint:c20];
    
    XCTAssertEqual(x.value, 10);
    
    [solver removeConstraint: c10];
    XCTAssertEqual(x.value, 20);
}

-(void)testSolvesAfterRemovingMultipleConstraints
{
    CSWSimplexSolver *solver = [self autoSolver];
    CSWVariable *x = [CSWVariable variable];
    
    CSWLinearExpression *expression = [[CSWLinearExpression alloc] initWithVariable: x coefficient:-1 constant:100];
    
    CSWConstraint *constraint = [[CSWConstraint alloc] initLinearConstraintWithExpression:expression strength:[CSWStrength strengthWeak] variable:nil];
    [solver addConstraint:constraint];
        
    CSWConstraint *c10 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorLessThanOrEqual rightConstant:10];
    CSWConstraint *c20 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorLessThanOrEqual rightConstant:20];
    
    [solver addConstraints:@[c10, c20]];
    XCTAssertEqual(x.value, 10);
    
    [solver removeConstraints:@[c10, c20]];
    [solver solve];
    XCTAssertEqual(x.value, 100);
}

-(void)testSolvesAfterRemovingConstraint2
{
    CSWSimplexSolver *solver = [self autoSolver];
    CSWVariable *x = [CSWVariable variable];
    CSWVariable *y = [CSWVariable variable];
    
    CSWLinearExpression *xExpression = [[CSWLinearExpression alloc] initWithVariable:x coefficient:-1 constant:100];
    CSWConstraint *xConstraint = [[CSWConstraint alloc] initLinearConstraintWithExpression:xExpression strength:[CSWStrength strengthWeak] variable:nil];
    
    CSWLinearExpression *yExpression = [[CSWLinearExpression alloc] initWithVariable:y coefficient:-1 constant:120];
    CSWConstraint *yConstraint = [[CSWConstraint alloc] initLinearConstraintWithExpression:yExpression strength:[CSWStrength strengthStrong] variable:nil];
    
    [solver addConstraint:xConstraint];
    [solver addConstraint:yConstraint];
    [solver solve];
    
    XCTAssertEqual(x.value, 100);
    XCTAssertEqual(y.value, 120);
    
    CSWConstraint *c10 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorLessThanOrEqual rightConstant:10];
    CSWConstraint *c20 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorLessThanOrEqual rightConstant:20];
    [solver addConstraints:@[c10, c20]];
    
    XCTAssertEqual(x.value, 10);
    
    [solver removeConstraint:c10];
    XCTAssertEqual(x.value, 20);
    
    CSWLinearExpression *cxExpression = [[CSWLinearExpression alloc] initWithVariable:x coefficient:-2 constant:0];
    [cxExpression addVariable:y];
    CSWConstraint *cxy = [[CSWConstraint alloc] initLinearConstraintWithExpression:cxExpression];
    [solver addConstraint:cxy];
    
    XCTAssertEqual(x.value, 20);
    XCTAssertEqual(y.value, 40);
    
    [solver removeConstraint:c20];
    XCTAssertEqual(x.value, 60);
    XCTAssertEqual(y.value, 120);

    [solver removeConstraint:cxy];
    XCTAssertEqual(x.value, 100);
    XCTAssertEqual(y.value, 120);
}

-(void)testDelete3
{
    CSWVariable *x = [CSWVariable variableWithValue:0];
    CSWSimplexSolver *solver = [self autoSolver];
    CSWConstraint *cxConstraint = [[CSWConstraint alloc] initLinearConstraintWithExpression:[[CSWLinearExpression alloc] initWithVariable:x coefficient:1 constant:-100]];
    cxConstraint.strength = [CSWStrength strengthWeak];
    [solver addConstraint: cxConstraint];
    XCTAssertEqual(x.value, 100);
    
    CSWConstraint *c10 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorLessThanOrEqual rightConstant:10];
    CSWConstraint *c10b = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorLessThanOrEqual rightConstant:10];

    [solver addConstraints:@[c10, c10b]];
    XCTAssertEqual(x.value, 10);
    [solver removeConstraint:c10];
    XCTAssertEqual(x.value, 10);
    
    [solver removeConstraint:c10b];
    XCTAssertEqual(x.value, 100);
}

-(void)testMultiEdit
{
    CSWVariable *x = [CSWVariable variableWithValue:3];
    CSWVariable *y = [CSWVariable variableWithValue:-5];
    CSWVariable *w = [CSWVariable variableWithValue:0];
    CSWVariable *h = [CSWVariable variableWithValue:0];
    
    [self addStayConstraintsForVariables:@[x, y, w, h] solver:solver];
    [self addEditConstraintsForVariables:@[x, y] solver:solver];
    [solver suggestEditVariable:x equals:10];
    [solver suggestEditVariable:y equals:20];
    
    [solver resolve];
    
    XCTAssertEqual(x.value, 10);
    XCTAssertEqual(y.value, 20);
    XCTAssertEqual(w.value, 0);
    XCTAssertEqual(h.value, 0);
    
    // Open a second set of variables for editing
    [self addEditConstraintsForVariables:@[w, h] solver:solver];
    [solver suggestEditVariable:w equals:30];
    [solver suggestEditVariable:h equals:40];
    [solver resolve];
    
    XCTAssertEqual(x.value, 10);
    XCTAssertEqual(y.value, 20);
    XCTAssertEqual(w.value, 30);
    XCTAssertEqual(h.value, 40);
    
    [solver suggestEditVariable:x equals:50];
    [solver suggestEditVariable:y equals:60];
    [solver resolve];

    XCTAssertEqual(x.value, 50);
    XCTAssertEqual(y.value, 60);
    XCTAssertEqual(w.value, 30);
    XCTAssertEqual(h.value, 40);
}

-(void)testSolvesCorrectlyWhenAddingMultipleEditConstraintsForTheSameVariable
{
    CSWVariable *x = [CSWVariable variable];
    CSWVariable *y = [CSWVariable variable];
    CSWVariable *w = [CSWVariable variable];
    CSWVariable *h = [CSWVariable variable];
     
    [self addStayConstraintsForVariables:@[x, y, w, h] solver:solver];
    [self addEditConstraintsForVariables:@[x, y] solver:solver];
    
    [solver suggestEditVariable:x equals:10];
    [solver suggestEditVariable:y equals:20];
    [solver resolve];
        
    [self addEditConstraintsForVariables:@[w, h] solver:solver];
    [solver suggestEditVariable:w equals:30];
    [solver suggestEditVariable:h equals:40];
    [solver resolve];
    
    [self addEditConstraintsForVariables:@[x, y] solver:solver];
    [solver suggestEditVariable:x equals:50];
    [solver suggestEditVariable:y equals:60];
    [solver resolve];
    
    XCTAssertEqual(x.value, 50);
    XCTAssertEqual(y.value, 60);
    XCTAssertEqual(w.value, 30);
    XCTAssertEqual(h.value, 40);
}

-(void)testCanAddAndRemoveEditVariables
{
    CSWVariable *x = [CSWVariable variable];
    
    [self addStayConstraintsForVariables:@[x] solver:solver];
    [self addEditConstraintsForVariables:@[x] solver:solver];
    [self addEditConstraintsForVariables:@[x] solver:solver];
    [solver suggestEditVariable:x equals:10];
    [solver resolve];
    [solver removeEditVariable:x];
    XCTAssertEqual(x.value, 10);
    
    [solver suggestEditVariable:x equals:20];
    [solver resolve];
    XCTAssertEqual(x.value, 20);
    
    [self addEditConstraintsForVariables:@[x] solver:solver];
    [solver suggestEditVariable:x equals:30];
    [solver resolve];
    [solver removeEditVariable:x];
    
    XCTAssertEqual(x.value, 30);
}

-(void)testCanAddMultipleEditConstraintsForTheSameVariable
{
    CSWVariable *x = [CSWVariable variable];
    CSWConstraint *e1 = [CSWConstraint editConstraintWithVariable:x];
    CSWConstraint *e2 = [CSWConstraint editConstraintWithVariable:x];

    [self addStayConstraintsForVariables:@[x] solver:solver];

    [solver addConstraint:e1];
    [solver suggestEditVariable:x equals:1];
    [solver resolve];
    XCTAssertEqual(x.value, 1);

    [solver addConstraint:e2];
    [solver suggestEditVariable:x equals:2];
    [solver resolve];
    XCTAssertEqual(x.value, 2);

    [solver removeConstraint:e1];
    [solver suggestEditVariable:x equals:3];
    [solver resolve];
    XCTAssertEqual(x.value, 3);

    [solver removeConstraint:e2];
    [solver addConstraint:e1];
    [solver addConstraint:e2];
    [solver suggestEditVariable:x equals:5];
    [solver resolve];
    XCTAssertEqual(x.value, 5);

    [solver removeConstraint:e2];
    [solver suggestEditVariable:x equals:6];
    [solver resolve];
    XCTAssertEqual(x.value, 6);
    
    [solver removeConstraint:e1];
}

-(void)testQuad
{
    NSArray *corners = @[
        @{ @"x": [CSWVariable variableWithValue:50], @"y": [CSWVariable variableWithValue:50]},
        @{ @"x": [CSWVariable variableWithValue:50], @"y": [CSWVariable variableWithValue:250]},
        @{ @"x": [CSWVariable variableWithValue:250], @"y": [CSWVariable variableWithValue:250]},
        @{ @"x": [CSWVariable variableWithValue:250], @"y": [CSWVariable variableWithValue:50]},
    ];

    NSArray *midpoints = @[
    @{ @"x": [CSWVariable variable], @"y": [CSWVariable variable]},
    @{ @"x": [CSWVariable variable], @"y": [CSWVariable variable]},
    @{ @"x": [CSWVariable variable], @"y": [CSWVariable variable]},
    @{ @"x": [CSWVariable variable], @"y": [CSWVariable variable]},
    ];

    CSWSimplexSolver *solver = [[CSWSimplexSolver alloc] init];
    [solver setAutoSolve:YES];
    
    double factor = 1;
    
    for (NSDictionary *corner in corners) {
        CSWTierWeightedStrength *stayStrength = [CSWTierWeightedStrength strengthWeak];
        stayStrength.weight = factor;
        CSWConstraint *x = [[CSWConstraint alloc] initStayConstraintWithVariable:corner[@"x"] strength:stayStrength];
        [solver addConstraint:x];
        CSWTierWeightedStrength *yStrength = [CSWTierWeightedStrength strengthWeak];
        yStrength.weight = factor;
        CSWConstraint *y = [[CSWConstraint alloc] initStayConstraintWithVariable:corner[@"y"] strength: stayStrength];
        [solver addConstraint:y];
        factor *= 2;
    }

    // Set midpoints
    for(int i = 0; i < 4; i++) {
        int j = (i + 1) % 4;
        CSWLinearExpression *xMidPointExpression = [[CSWLinearExpression alloc] init];
        [xMidPointExpression addVariable:corners[i][@"x"]];
        [xMidPointExpression addVariable:corners[j][@"x"]];
        [xMidPointExpression divideConstantAndTermsBy:2];

        CSWConstraint *xMidpointConstraint = [CSWConstraint constraintWithLeftVariable:midpoints[i][@"x"] operator:CSWConstraintOperatorEqual rightExpression:xMidPointExpression];

        CSWLinearExpression *yMidPointExpression = [[CSWLinearExpression alloc] init];
        [yMidPointExpression addVariable:corners[i][@"y"]];
        [yMidPointExpression addVariable:corners[j][@"y"]];
        [yMidPointExpression divideConstantAndTermsBy:2];
        CSWConstraint *yMidpointConstraint = [CSWConstraint constraintWithLeftVariable:midpoints[i][@"y"] operator:CSWConstraintOperatorEqual rightExpression:yMidPointExpression];

        [solver addConstraints:@[xMidpointConstraint, yMidpointConstraint]];
    }

    // Add constraints to prevent turning inside out
    NSPoint xPairs[] = {
        NSMakePoint(0, 2),
        NSMakePoint(0, 3),
        NSMakePoint(1, 2),
        NSMakePoint(1, 3),
    };
    for (int i = 0; i < 4; i++) {
        NSPoint pair = xPairs[i];
        CSWLinearExpression *expression = [[CSWLinearExpression alloc] initWithVariable:corners[(int)pair.x][@"x"] coefficient:1 constant:1];
        CSWConstraint *ieq = [CSWConstraint constraintWithLeftExpression:expression operator:CSWConstraintOperatorLessThanOrEqual rightVariable:corners[(int)pair.y][@"x"]];

        [solver addConstraint:ieq];
    }

    NSPoint yPairs[] = {
        NSMakePoint(0, 1),
        NSMakePoint(0, 2),
        NSMakePoint(3, 1),
        NSMakePoint(3, 2),
    };

    for (int i = 0; i < 4; i++) {
        NSPoint pair = yPairs[i];
        CSWLinearExpression *expression = [[CSWLinearExpression alloc] initWithVariable:corners[(int)pair.x][@"y"] coefficient:1 constant:1];
        CSWConstraint *ieq = [CSWConstraint constraintWithLeftExpression:expression operator:CSWConstraintOperatorLessThanOrEqual rightVariable:corners[(int)pair.y][@"y"]];

        [solver addConstraint:ieq];
    }

    // Add limits
    for (NSDictionary *corner in corners) {
        // corner.x
        CSWConstraint *lowerBoundsXConstraint = [CSWConstraint constraintWithLeftVariable:corner[@"x"] operator:CSWConstraintOperationGreaterThanOrEqual rightConstant:0];
        CSWConstraint *upperBoundsXConstraint = [CSWConstraint constraintWithLeftVariable:corner[@"x"] operator:CSWConstraintOperatorLessThanOrEqual rightConstant:300];

        CSWConstraint *lowerBoundsYConstraint = [CSWConstraint constraintWithLeftVariable:corner[@"y"] operator:CSWConstraintOperationGreaterThanOrEqual rightConstant:0];
        CSWConstraint *upperBoundsYConstraint = [CSWConstraint constraintWithLeftVariable:corner[@"y"] operator:CSWConstraintOperatorLessThanOrEqual rightConstant:300];

        [solver addConstraints:@[lowerBoundsXConstraint, upperBoundsXConstraint, lowerBoundsYConstraint, upperBoundsYConstraint]];
    }

    NSPoint expectedCornerValues[] = {
        NSMakePoint(50, 50),
        NSMakePoint(50, 250),
        NSMakePoint(250, 250),
        NSMakePoint(250, 50)
    };

    for (int i = 0; i < 4; i++) {
        XCTAssertEqual([(CSWVariable*) corners[i][@"x"] value], expectedCornerValues[i].x);
        XCTAssertEqual([(CSWVariable*) corners[i][@"y"] value], expectedCornerValues[i].y);
    }

    NSPoint expectedMidpointValues[] = {
        NSMakePoint(50, 150),
        NSMakePoint(150, 250),
        NSMakePoint(250, 150),
    };

    for (int i = 0; i < 3; i++) {
        XCTAssertEqual([(CSWVariable*) midpoints[i][@"x"] value], expectedMidpointValues[i].x);
        XCTAssertEqual([(CSWVariable*) midpoints[i][@"y"] value], expectedMidpointValues[i].y);
    }

    [solver suggestVariable:corners[0][@"x"] equals:100];

    NSPoint expectedCornerValues2[] = {
        NSMakePoint(100, 50),
        NSMakePoint(50, 250),
        NSMakePoint(250, 250),
        NSMakePoint(250, 50)
    };

    for (int i = 0; i < 4; i++) {
        XCTAssertEqual([(CSWVariable*) corners[i][@"x"] value], expectedCornerValues2[i].x);
        XCTAssertEqual([(CSWVariable*) corners[i][@"y"] value], expectedCornerValues2[i].y);
    }

    NSPoint expectedMidpointValues2[] = {
        NSMakePoint(75, 150),
        NSMakePoint(150, 250),
        NSMakePoint(250, 150),
        NSMakePoint(175, 50)
    };
    for (int i = 0; i < 4; i++) {
        XCTAssertEqual([(CSWVariable*) midpoints[i][@"x"] value], expectedMidpointValues2[i].x);
        XCTAssertEqual([(CSWVariable*) midpoints[i][@"y"] value], expectedMidpointValues2[i].y);
    }
        
    [solver suggestEditVariables:@[
        [[CSWSuggestion alloc] initWithVariable: midpoints[0][@"x"] value: 50],
        [[CSWSuggestion alloc] initWithVariable: midpoints[0][@"y"] value: 150],
    ]];
    
    XCTAssertEqual([(CSWVariable*) midpoints[0][@"x"] value], 50);
    XCTAssertEqual([(CSWVariable*) midpoints[0][@"y"] value], 150);
    
    XCTAssertEqual([(CSWVariable*) midpoints[3][@"x"] value], 150);
    XCTAssertEqual([(CSWVariable*) midpoints[3][@"y"] value], 50);
    
    XCTAssertEqual([(CSWVariable*) corners[0][@"x"] value], 50);
    XCTAssertEqual([(CSWVariable*) corners[0][@"y"] value], 50);
}

-(void)testBeginEditThrowsErrorIfNoEditableVariables
{
    CSWSimplexSolver *solver = [[CSWSimplexSolver alloc] init];
    XCTAssertThrowsSpecificNamed([solver beginEdit], NSException, NSInternalInconsistencyException);
}

-(void)testRequiredStrengthEditVariable
{
    CSWVariable *v = [CSWVariable variableWithValue:0];
    CSWSimplexSolver *solver = [self autoSolver];
    
    CSWConstraint *stayConstraint = [[CSWConstraint alloc] initStayConstraintWithVariable:v strength:[CSWStrength strengthStrong]];
    [solver addConstraint:stayConstraint];
    XCTAssertEqual(v.value, 0);
    [solver addConstraint:[[CSWConstraint alloc] initEditConstraintWithVariable:v stength:[CSWStrength strengthRequired]]];
    [solver beginEdit];
    [solver suggestEditVariable:v equals:2];
    [solver endEdit];
    
    XCTAssertEqual(v.value, 2);
}

-(void)testRequiredStayConstraintDefeatsStrongEditConstraintWhenSuggestingEditVariable
{
    CSWVariable *v = [CSWVariable variableWithValue:0];
    CSWSimplexSolver *solver = [self autoSolver];
    CSWConstraint *stayConstraint = [[CSWConstraint alloc] initStayConstraintWithVariable:v strength:[CSWStrength strengthRequired]];
    
    CSWConstraint *editVariableConstraint = [[CSWConstraint alloc] initEditConstraintWithVariable:v stength:[CSWStrength strengthStrong]];
    [solver addConstraints: @[stayConstraint, editVariableConstraint]];
    
    [solver beginEdit];
    [solver suggestEditVariable:v equals:2];
    [solver endEdit];
    XCTAssertEqual(v.value, 0);
}

-(void)testBug16
{
        CSWVariable *a = [CSWVariable variableWithValue:1];
        CSWVariable *b = [CSWVariable variableWithValue:2];
        
        CSWConstraint *stayConstraint = [[CSWConstraint alloc] initStayConstraintWithVariable:a strength:[CSWStrength strengthWeak]];
        [solver addConstraint:stayConstraint];
        
        CSWLinearExpression *aEqualsBExp = [[CSWLinearExpression alloc] initWithVariable:a];
        [aEqualsBExp addVariable:b coefficient:-1];
        CSWConstraint *aEqualsB = [[CSWConstraint alloc] initLinearConstraintWithExpression:aEqualsBExp];
        
        CSWConstraint *editVariableConstraint = [[CSWConstraint alloc] initEditConstraintWithVariable:a stength:[CSWStrength strengthStrong]];
        [solver addConstraints:@[aEqualsB, editVariableConstraint]];
        
        [solver beginEdit];
        [solver suggestEditVariable:a equals:3];
        [solver endEdit];
        
        XCTAssertEqual(a.value, 3);
        XCTAssertEqual(b.value, 3);
    
}

-(void)testBug16B
{
    CSWVariable *a = [CSWVariable variable];
    CSWVariable *b = [CSWVariable variable];
    CSWVariable *c = [CSWVariable variable];
    
    [self addStayConstraintsForVariables:@[a, c] solver:solver];
    
    CSWConstraint *aEquals = [[CSWConstraint alloc] initLinearConstraintWithExpression:[[CSWLinearExpression alloc] initWithVariable:a coefficient:-1 constant:10]];
    CSWConstraint *bEqualsC = [CSWConstraint constraintWithLeftVariable:b operator:CSWConstraintOperatorEqual rightVariable:c];
    [solver addConstraints:@[aEquals, bEqualsC]];
    
    [solver suggestVariable:c equals:100];
    XCTAssertEqual(a.value, 10);
}

-(void)testSolvesCorrectlyAfterSuggestingValues
{
    CSWVariable *x = [CSWVariable variableWithValue:5];
    CSWVariable *y = [CSWVariable variableWithValue:10];

    [self addStayConstraintsForVariables:@[x, y] solver:solver];
    [solver suggestVariable: x equals: 6];
    [solver solve];

    XCTAssertEqual(x.value, 6);
}

-(NSDictionary*)createConstraintsForCasso1X: (CSWVariable*)x y:(CSWVariable*)y
{
    CSWConstraint *xLessThanOrEqualToY = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorLessThanOrEqual rightVariable:y];

    CSWLinearExpression *yx = [[CSWLinearExpression alloc] init];
    [yx addVariable:y coefficient:-1];
    [yx addVariable:x coefficient:1];
    [yx setConstant:3];
    CSWConstraint *yxConstraint = [[CSWConstraint alloc] initLinearConstraintWithExpression:yx];
    CSWConstraint *xConstraint = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:10];

    [xConstraint setStrength:[CSWStrength strengthWeak]];

    CSWConstraint *yConstraint = [CSWConstraint constraintWithLeftVariable:y operator:CSWConstraintOperatorEqual rightConstant:10];
    [yConstraint setStrength:[CSWStrength strengthWeak]];

    return @{
        @"yx": yxConstraint,
        @"y": yConstraint,
        @"x": xConstraint,
        @"x<=y": xLessThanOrEqualToY
    };
}

/**
 Prefers the latest constraint,
 */
// casso1_test
-(void)testCompetingWeakConstraintsWithYConstraintTakingPriorityOverX
{
    CSWVariable *x = [CSWVariable variableWithValue:0];
    CSWVariable *y = [CSWVariable variableWithValue:0];
    
    NSDictionary *constraints = [self createConstraintsForCasso1X:x y:y];
    [solver addConstraints:@[constraints[@"x<=y"], constraints[@"yx"], constraints[@"x"], constraints[@"y"]]];
    [solver solve];
    
    XCTAssertEqual(x.value, 7);
    XCTAssertEqual(y.value, 10);
}

-(void)testCompetingWeakConstraintsWithXConstraintTakingPriorityOverY
{
    CSWVariable *x = [CSWVariable variableWithValue:0];
    CSWVariable *y = [CSWVariable variableWithValue:0];
    
    NSDictionary *constraints = [self createConstraintsForCasso1X:x y:y];
    [solver addConstraints:@[constraints[@"x<=y"], constraints[@"yx"], constraints[@"y"], constraints[@"x"]]];
    [solver solve];
    
    XCTAssertEqual(x.value, 10);
    XCTAssertEqual(y.value, 13);
}

-(void)testCassowary2
{
    CSWVariable *x = [CSWVariable variableWithValue:0];
    CSWVariable *y = [CSWVariable variableWithValue:0];
    y.name = @"y";

    CSWLinearExpression *yx = [[CSWLinearExpression alloc] init];
    [yx addVariable:x coefficient:1];
    [yx setConstant:3];
    CSWConstraint *xLessThanOrEqualToY = [CSWConstraint constraintWithLeftExpression:yx operator:CSWConstraintOperatorLessThanOrEqual rightVariable:y];
    
    CSWConstraint *yEqualsX = [CSWConstraintFactory constraintWithLeftVariable:y operator:CSWConstraintOperatorEqual rightExpression:[[CSWLinearExpression alloc] initWithVariable:x coefficient:1 constant:3]];
    CSWConstraint *x10 = [CSWConstraintFactory constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:10];

    [solver addConstraints:@[yEqualsX, xLessThanOrEqualToY, x10]];
    [solver solve];

    XCTAssertEqual(x.value, 10);
    XCTAssertEqual(y.value, 13);
}

// inconsistent1
-(void)testThrowsErrorWhenAddingTwoConflictingConstraintsWhichSpecifyTheValueOfVariable
{
    CSWVariable *x = [CSWVariable variableWithValue:0];
    
    CSWConstraint *c1 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:10];
    CSWConstraint *c2 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:5];

    NSArray *constraints = @[c1, c2];
    XCTAssertThrowsSpecificNamed([solver addConstraints: constraints], NSException, NSInvalidArgumentException);
}

-(void)testThrowsErrorWhenAddingTwoConflictingConstraintsWithDifferentInequities
{
    CSWVariable *x = [CSWVariable variableWithValue:0];
    
    CSWConstraint *c1 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperationGreaterThanOrEqual rightConstant:10];
    CSWConstraint *c2 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorLessThanOrEqual rightConstant:5];

    NSArray *constraints = @[c1, c2];
    XCTAssertThrowsSpecificNamed([solver addConstraints: constraints], NSException, NSInvalidArgumentException);
}

-(void)testThrowsErrorWhenAddingTwoConflictingConstraints
{
    CSWVariable *v = [CSWVariable variableWithValue:0];
    v.name = @"v";
    CSWVariable *w = [CSWVariable variableWithValue:0];
    w.name = @"w";
    CSWVariable *x = [CSWVariable variableWithValue:0];
    CSWVariable *y = [CSWVariable variableWithValue:0];

    CSWSimplexSolver *solver = [[CSWSimplexSolver alloc] init];
    CSWConstraint *c1 = [CSWConstraint constraintWithLeftVariable:v operator:CSWConstraintOperationGreaterThanOrEqual rightConstant:10];
    CSWConstraint *c2 = [CSWConstraint constraintWithLeftVariable:w operator:CSWConstraintOperationGreaterThanOrEqual rightVariable:v];
    CSWConstraint *c3 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperationGreaterThanOrEqual rightVariable:w];
    CSWConstraint *c4 = [CSWConstraint constraintWithLeftVariable:y operator:CSWConstraintOperationGreaterThanOrEqual rightVariable:x];
    
    [solver addConstraint:c1];
    [solver addConstraint:c2];
    [solver addConstraint:c3];
    [solver addConstraint:c4];

    CSWConstraint *conflictingConstraint = [CSWConstraint constraintWithLeftVariable:y operator:CSWConstraintOperatorLessThanOrEqual rightConstant:5];
    XCTAssertThrowsSpecificNamed([solver addConstraint:conflictingConstraint], NSException, NSInvalidArgumentException);
}

-(void)testModifyingConstraintStrengthUpdatesSolver
{
    CSWVariable *x = [CSWVariable variable];
    CSWSimplexSolver *solver = [self autoSolver];
    
    CSWConstraint *c1 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:1];
    c1.strength = [CSWStrength strengthWeak];
    CSWConstraint *c2 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:2];
    c2.strength = [CSWStrength strengthMedium];
    
    [solver addConstraints:@[c1, c2]];
    XCTAssertEqual(x.value, 2);
    [solver updateConstraint: c1 strength: [CSWStrength strengthStrong]];
    XCTAssertEqual(x.value, 1);
}

-(void)testModifyingConstraintWeightUpdatesSolver
{
    CSWVariable *x = [CSWVariable variable];
    CSWSimplexSolver *solver = [self autoSolver];
    CSWConstraint *c1 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:1];
    c1.strength = [CSWStrength strengthStrong];
    CSWConstraint *c2 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:2];
    c2.strength = [CSWStrength strengthStrong];
    
    [solver addConstraints:@[c1, c2]];
    
    CSWTierWeightedStrength *newC1Strength = [CSWTierWeightedStrength strengthStrong];
    newC1Strength.weight = 3;
    
    [solver updateConstraint:c1 strength:newC1Strength];
    XCTAssertEqual(x.value, 1);
}

-(void)testDoesNotContainConstraintIfConstraintHasNotBeenAdded
{
    CSWConstraint *constraint = [CSWConstraint constraintWithLeftVariable:[CSWVariable variable] operator:CSWConstraintOperatorEqual rightConstant:42];
    XCTAssertFalse([solver containsConstraint: constraint]);
}

-(void)testDoesContainConstraintIfConstraintHasBeenAdded
{
    CSWConstraint *constraint = [CSWConstraint constraintWithLeftVariable:[CSWVariable variable] operator:CSWConstraintOperatorEqual rightConstant:42];
    CSWSimplexSolver *solver = [[CSWSimplexSolver alloc] init];
    [solver addConstraint:constraint];
    
    XCTAssertTrue([solver containsConstraint:constraint]);
}

-(void)testDoesNotContainConstraintAfterRemovingConstraint
{
    CSWConstraint *constraint = [CSWConstraint constraintWithLeftVariable:[CSWVariable variable] operator:CSWConstraintOperatorEqual rightConstant:42];
    [solver addConstraint:constraint];
    [solver removeConstraint:constraint];
    
    XCTAssertFalse([solver containsConstraint:constraint]);
}

-(void)testEditUnconstrainedVariable
{
    CSWVariable *variable = [CSWVariable variableWithValue:0];
    
    CSWConstraint *constraint = [[CSWConstraint alloc] initEditConstraintWithVariable:variable stength:[CSWStrength strengthStrong]];
    [solver addConstraint:constraint];
    XCTAssertEqual(variable.value, 0);
    XCTAssertTrue([solver isValid]);
    
    [solver suggestVariable:variable equals:2];
    [solver resolve];
    XCTAssertEqual(variable.value, 2);
    XCTAssertTrue([solver isValid]);
}

-(void)testIndependentValuesCanBeSuggestedForConcurrentEdits
{
    CSWSimplexSolver *solver = [self autoSolver];
    CSWVariable *variable = [CSWVariable variable];

    CSWConstraint *e1 = [[CSWConstraint alloc] initEditConstraintWithVariable:variable stength:[CSWStrength strengthStrong]];
    CSWConstraint *e2 = [[CSWConstraint alloc] initEditConstraintWithVariable:variable stength:[CSWStrength strengthWeak]];

    [solver addConstraints:@[e1, e2]];
    [solver solve];

    [solver suggestEditConstraint:e1 equals:42];
    [solver suggestEditConstraint:e2 equals:21];
    [solver resolve];

    XCTAssertEqual(variable.value, 42);
}

-(void)testDoesNotHaveMultipleSolutionWithASingleRequiredConstraint
{
    CSWSimplexSolver *solver = [self autoSolver];
    CSWVariable *x = [CSWVariable variable];
    CSWConstraint *xEquals10 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:10];
    [solver addConstraint:xEquals10];
    
    XCTAssertFalse([solver isMultipleSolutions]);
}

-(void)testDoesHaveManySolutionsWithMultipleNonRequiredConstraintsOnTheSameVariable
{
    CSWVariable *x = [CSWVariable variable];
    
    CSWConstraint *xEquals10 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:10];
    xEquals10.strength = [CSWStrength strengthWeak];
    
    CSWConstraint *xEquals20 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:20];
    xEquals20.strength = [CSWStrength strengthWeak];
    
    [solver addConstraints:@[xEquals10, xEquals20]];
    XCTAssertTrue([solver isMultipleSolutions]);
}

-(void)testDoesNotHaveManySolutionsWithANonRequiredAndRequiredConstraintOnTheSameVariable
{
    CSWVariable *x = [CSWVariable variable];

    CSWConstraint *xEquals20 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:20];
    CSWConstraint *xEquals10 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:10];
    xEquals10.strength = [CSWStrength strengthWeak];
    
    [solver addConstraints:@[xEquals10, xEquals20]];
    XCTAssertFalse([solver isMultipleSolutions]);
}

-(void)testDoesNotHaveMultipleSolutionsWhenSufficientlyConstrained
{
    CSWVariable *x = [CSWVariable variable];
    CSWVariable *y = [CSWVariable variable];
    CSWConstraint *xLessEqualToY = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorLessThanOrEqual rightVariable:y];

    CSWLinearExpression *exp = [[CSWLinearExpression alloc] initWithVariable:x coefficient:1 constant:3.0];
    CSWConstraint *yEquualsXPlus3 = [CSWConstraint constraintWithLeftVariable:y operator:CSWConstraintOperatorEqual rightExpression:exp];
    
    CSWConstraint *xEquals10 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:10];
    xEquals10.strength = [CSWStrength strengthWeak];

    [solver addConstraints:@[xLessEqualToY, xEquals10, yEquualsXPlus3]];
    XCTAssertFalse([solver isMultipleSolutions]);
}

-(void)testDoesNotHaveMultipleSolutionsWhenSufficientlyConstrainedAlternatve
{
    CSWVariable *x = [CSWVariable variable];
    CSWVariable *y = [CSWVariable variable];

    CSWConstraint *xLessEqualToY = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorLessThanOrEqual rightVariable:y];

    CSWLinearExpression *exp = [[CSWLinearExpression alloc] initWithVariable:x coefficient:1 constant:3.0];
    CSWConstraint *yEqualsXPlus3 = [CSWConstraint constraintWithLeftVariable:y operator:CSWConstraintOperatorEqual rightExpression:exp];
    
    CSWConstraint *yEquals10 = [CSWConstraint constraintWithLeftVariable:y operator:CSWConstraintOperatorEqual rightConstant:10];
    yEquals10.strength = [CSWStrength strengthWeak];

    [solver addConstraints:@[xLessEqualToY, yEquals10, yEqualsXPlus3]];
    XCTAssertFalse([solver isMultipleSolutions]);
}

-(void)testHasMultipleSolutionsWhenUnderConstraintedByTwoWeakConstraints
{
    CSWVariable *x = [CSWVariable variable];
    CSWVariable *y = [CSWVariable variable];
    CSWConstraint *xLessEqualToY = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorLessThanOrEqual rightVariable:y];
    
    CSWLinearExpression *exp = [[CSWLinearExpression alloc] initWithVariable:x coefficient:1 constant:3.0];
    CSWConstraint *yEqualsXPlus3 = [CSWConstraint constraintWithLeftVariable:y operator:CSWConstraintOperatorEqual rightExpression:exp];
    
    CSWConstraint *xEquals10 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:10];
    xEquals10.strength = [CSWStrength strengthWeak];
    
    CSWConstraint *yEquals10 = [CSWConstraint constraintWithLeftVariable:y operator:CSWConstraintOperatorEqual rightConstant:10];
    yEquals10.strength = [CSWStrength strengthWeak];

    [solver addConstraints:@[xLessEqualToY, xEquals10, yEquals10, yEqualsXPlus3]];
    XCTAssertTrue([solver isMultipleSolutions]);
}

-(void)testDoesNotHaveMultipleSolutionsWhenRemovingCompetingWeakConstraint
{
    CSWVariable *x = [CSWVariable variable];
    CSWVariable *y = [CSWVariable variable];
    CSWConstraint *xLessEqualToY = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorLessThanOrEqual rightVariable:y];

    CSWLinearExpression *exp = [[CSWLinearExpression alloc] initWithVariable:x coefficient:1 constant:3.0];
    CSWConstraint *yEqualsXPlus3 = [CSWConstraint constraintWithLeftVariable:y operator:CSWConstraintOperatorEqual rightExpression:exp];
    
    CSWConstraint *xEquals10 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:10];
    xEquals10.strength = [CSWStrength strengthWeak];
    
    CSWConstraint *yEquals10 = [CSWConstraint constraintWithLeftVariable:y operator:CSWConstraintOperatorEqual rightConstant:10];
    yEquals10.strength = [CSWStrength strengthWeak];

    [solver addConstraints:@[xLessEqualToY, xEquals10, yEquals10, yEqualsXPlus3]];
    [solver removeConstraint:yEquals10];
    
    XCTAssertFalse([solver isMultipleSolutions]);
}

-(void)testHasMultipleSolutionsAfterAddingWeakConstraint
{
    CSWVariable *x = [CSWVariable variable];
    CSWVariable *y = [CSWVariable variable];

    CSWConstraint *xLessEqualToY = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorLessThanOrEqual rightVariable:y];

    CSWLinearExpression *exp = [[CSWLinearExpression alloc] initWithVariable:x coefficient:1 constant:3.0];
    CSWConstraint *yEquualsXPlus3 = [CSWConstraint constraintWithLeftVariable:y operator:CSWConstraintOperatorEqual rightExpression:exp];
    CSWConstraint *xEquals10 = [CSWConstraint constraintWithLeftVariable:x operator:CSWConstraintOperatorEqual rightConstant:10];
    xEquals10.strength = [CSWStrength strengthWeak];
    CSWConstraint *yEquals10 = [CSWConstraint constraintWithLeftVariable:y operator:CSWConstraintOperatorEqual rightConstant:10];
    yEquals10.strength = [CSWStrength strengthWeak];

    [solver addConstraints:@[xLessEqualToY, yEquals10, yEquualsXPlus3]];
    [solver addConstraint:xEquals10];
    XCTAssertTrue([solver isMultipleSolutions]);
}

@end
