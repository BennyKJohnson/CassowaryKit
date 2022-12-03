#import <XCTest/XCTest.h>
#import "CSWSymbolicWeight.h"

@interface CSWSymbolicWeightTests : XCTestCase

@end

@implementation CSWSymbolicWeightTests

- (void)testCanInitSymbolicWeightWithLevels {
    CSWSymbolicWeight *weight = [[CSWSymbolicWeight alloc] initWithLevelsCount:3];
    XCTAssertTrue([weight isKindOfClass:[CSWSymbolicWeight class]]);
    XCTAssertEqual(weight.levelCount, 3);
}

- (void)testCanInitSymbolicWeightsWithLevelsArray
{
    CSWSymbolicWeight *weight = [[CSWSymbolicWeight alloc] initWithLevels:@[@(1), @(2)]];
    XCTAssertEqual(weight.levelCount, 2);
    XCTAssertEqual(weight.levels[0], 1);
    XCTAssertEqual(weight.levels[1], 2);
}

-(void)testCopy
{
    CSWSymbolicWeight *weight = [[CSWSymbolicWeight alloc] initWithLevels:@[@(1), @(2)]];
    CSWSymbolicWeight *weightCopy = [weight copy];
    
    XCTAssertNotEqual(weight.levels, weightCopy.levels);
    XCTAssertEqual(weightCopy.levels[0], 1);
    XCTAssertEqual(weightCopy.levels[1], 2);
}

@end
