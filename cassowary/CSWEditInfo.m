//
//  CSWEditInfo.m
//  cassowary
//
//  Created by Benjamin Johnson on 22/11/22.
//  Copyright © 2022 Benjamin Johnson. All rights reserved.
//

#import "CSWEditInfo.h"

@implementation CSWEditInfo

-(instancetype)initWithVariable: (CSWAbstractVariable*)variable constraint: (CSWConstraint*)constraint plusVariable: (CSWAbstractVariable*)plusVariable minusVariable: (CSWAbstractVariable*)minusVariable previousConstant: (NSInteger)previousConstant
{
    self = [super init];
    if (self != nil) {
        self.variable = variable;
        self.plusVariable = plusVariable;
        self.minusVariable = minusVariable;
        self.constraint = constraint;
        self.previousConstant = previousConstant;
    }
    
    return self;
}



@end
