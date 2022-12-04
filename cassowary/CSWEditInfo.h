#import <Foundation/Foundation.h>
#import "CSWConstraint.h"
#import "CSWVariable.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWEditInfo : NSObject

@property (strong, nonatomic) CSWConstraint *constraint;

@property (strong, nonatomic) CSWVariable *variable;

@property (strong, nonatomic) CSWVariable *plusVariable;

@property (strong, nonatomic) CSWVariable *minusVariable;

@property NSInteger previousConstant;

-(instancetype)initWithVariable: (CSWVariable*)variable constraint: (CSWConstraint*)constraint plusVariable: (CSWVariable*)plusVariable minusVariable: (CSWVariable*)minusVariable previousConstant: (NSInteger)previousConstant;


@end

NS_ASSUME_NONNULL_END
