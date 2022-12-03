//
//  CSWStrengthTests.m
//  cassowaryTests
//
//  Created by Benjamin Johnson on 10/11/22.
//  Copyright © 2022 Benjamin Johnson. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CSWSymbolicWeight.h"
#import "CSWStrength.h"

@interface CSWStrengthTests : XCTestCase

@end

@implementation CSWStrengthTests

-(void)testCanInitWithNameAndSymbolicWeight
{
    CSWSymbolicWeight *weight = [[CSWSymbolicWeight alloc] initWithLevelsCount:3];
    NSString *strengthName = @"strength";
    
    CSWStrength *strength = [[CSWStrength alloc] initWithName: strengthName symbolicWeight:weight weight:2.0];
    
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
    CSWStrength *strength = [CSWStrength strengthRequired];
    CSWSymbolicWeight *weight = [strength symbolicWeight];
    CSWSymbolicWeight *expectedWeight = [[CSWSymbolicWeight alloc] initWithLevels:@[@(1000), @(1000), @(1000)]];
    XCTAssertTrue([weight isEqualToSymbolicWeight: expectedWeight]);
    XCTAssertTrue([strength.name isEqual:@"<Required>"]);
}

-(void)testInitWithStrongStrength
{
    CSWStrength *strength = [CSWStrength strengthStrong];
    CSWSymbolicWeight *weight = [strength symbolicWeight];
    CSWSymbolicWeight *expectedWeight = [[CSWSymbolicWeight alloc] initWithLevels:@[@(1.0), @(0), @(0)]];
    XCTAssertTrue([weight isEqualToSymbolicWeight: expectedWeight]);
    XCTAssertTrue([strength.name isEqual:@"strong"]);
}

-(void)testInitWithMediumStrength
{
    CSWStrength *strength = [CSWStrength strengthMedium];
    CSWSymbolicWeight *weight = [strength symbolicWeight];
    CSWSymbolicWeight *expectedWeight = [[CSWSymbolicWeight alloc] initWithLevels:@[@(0), @(1), @(0)]];
    XCTAssertTrue([weight isEqualToSymbolicWeight: expectedWeight]);
    XCTAssertTrue([strength.name isEqual:@"medium"]);
}

@end
