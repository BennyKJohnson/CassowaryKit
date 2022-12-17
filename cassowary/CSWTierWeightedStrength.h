#import <Foundation/Foundation.h>
#import "CSWSymbolicWeight.h"
#import "CSWStrength.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWTierWeightedStrength : CSWStrength <NSCopying>

@property (nonatomic, strong) CSWSymbolicWeight *symbolicWeight;

@property double weight;

-(instancetype)initWithName: (NSString*)name symbolicWeight: (CSWSymbolicWeight*)symbolicWeight weight: (double)weight;

+(instancetype)strengthRequired;

+(instancetype)strengthStrong;

+(instancetype)strengthMedium;

+(instancetype)strengthWeak;

-(BOOL)isRequired;

-(double)value;

@end

NS_ASSUME_NONNULL_END
