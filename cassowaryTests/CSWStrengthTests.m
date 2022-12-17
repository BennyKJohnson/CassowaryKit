 #import <XCTest/XCTest.h>
#import "CSWSymbolicWeight.h"
#import "CSWStrength.h"
#import "CSWTierWeightedStrength.h"

@interface CSWStrengthTests : XCTestCase

@end

@implementation CSWStrengthTests

-(void)testCanInitWithNameAndSymbolicWeight
{
    CSWSymbolicWeight *weight = [[CSWSymbolicWeight alloc] initWithLevelsCount:3];
    NSString *strengthName = @"strength";
    
    CSWTierWeightedStrength *strength = [[CSWTierWeightedStrength alloc] initWithName: strengthName symbolicWeight:weight weight:2.0];
    
    XCTAssertTrue([strength isKindOfClass:[CSWStrength class]]);
    XCTAssertEqual(strength.name, strengthName);
    XCTAssertEqual(strength.symbolicWeight, weight);
    XCTAssertEqual(strength.weight, 2.0);
}

-(void)testCSWStrengthIsEqualWhenLevelsAreEqual
{
    CSWSymbolicWeight *weight1 = [[CSWSymbolicWeight alloc] initWithLevels:@[@(1000), @(1000), @(1000)]];
    CSWSymbolicWeight *weight2 = [[CSWSymbolicWeight alloc] initWithLevels:@[@(1000), @(1000), @(1000)]];
    
    XCTAssertTrue([weight1 isEqual:weight2]);
}

-(void)testCSWStrengthIsNotEqualWhenLevelsAreNotEqual
{
    CSWSymbolicWeight *weight1 = [[CSWSymbolicWeight alloc] initWithLevels:@[@(1000), @(1000), @(1001)]];
    CSWSymbolicWeight *weight2 = [[CSWSymbolicWeight alloc] initWithLevels:@[@(1000), @(1000), @(1000)]];
    
    XCTAssertFalse([weight1 isEqual:weight2]);
}

-(void)testInitWithRequiredStrength
{
    CSWTierWeightedStrength *strength = [CSWTierWeightedStrength strengthRequired];
    CSWSymbolicWeight *weight = [strength symbolicWeight];
    CSWSymbolicWeight *expectedWeight = [[CSWSymbolicWeight alloc] initWithLevels:@[@(1000), @(1000), @(1000)]];
    XCTAssertTrue([weight isEqualToSymbolicWeight: expectedWeight]);
    XCTAssertTrue([strength.name isEqual:@"<Required>"]);
}

-(void)testInitWithStrongStrength
{
    CSWTierWeightedStrength *strength = [CSWTierWeightedStrength strengthStrong];
    CSWSymbolicWeight *weight = [strength symbolicWeight];
    CSWSymbolicWeight *expectedWeight = [[CSWSymbolicWeight alloc] initWithLevels:@[@(1.0), @(0), @(0)]];
    XCTAssertTrue([weight isEqualToSymbolicWeight: expectedWeight]);
    XCTAssertTrue([strength.name isEqual:@"strong"]);
}

-(void)testInitWithMediumStrength
{
    CSWTierWeightedStrength *strength = [CSWTierWeightedStrength strengthMedium];
    CSWSymbolicWeight *weight = [strength symbolicWeight];
    CSWSymbolicWeight *expectedWeight = [[CSWSymbolicWeight alloc] initWithLevels:@[@(0), @(1), @(0)]];
    XCTAssertTrue([weight isEqualToSymbolicWeight: expectedWeight]);
    XCTAssertTrue([strength.name isEqual:@"medium"]);
}

@end
