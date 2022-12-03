//
//  CSWEditInfo.h
//  cassowary
//
//  Created by Benjamin Johnson on 22/11/22.
//  Copyright © 2022 Benjamin Johnson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSWConstraint.h"
#import "CSWAbstractVariable.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWEditInfo : NSObject

@property (strong, nonatomic) CSWConstraint *constraint;

@property (strong, nonatomic) CSWAbstractVariable *variable;

@property (strong, nonatomic) CSWAbstractVariable *plusVariable;

@property (strong, nonatomic) CSWAbstractVariable *minusVariable;

@property NSInteger previousConstant;

-(instancetype)initWithVariable: (CSWAbstractVariable*)variable constraint: (CSWConstraint*)constraint plusVariable: (CSWAbstractVariable*)plusVariable minusVariable: (CSWAbstractVariable*)minusVariable previousConstant: (NSInteger)previousConstant;


@end

NS_ASSUME_NONNULL_END
