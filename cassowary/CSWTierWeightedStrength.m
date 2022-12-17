#import "CSWTierWeightedStrength.h"
#import "CSWFloatComparator.h"

@implementation CSWTierWeightedStrength

-(instancetype)initWithName: (NSString*)name symbolicWeight: (CSWSymbolicWeight*)symbolicWeight weight: (double)weight;
{
    if (self = [super init]) {
        self.name = name;
        self.symbolicWeight = symbolicWeight;
        self.weight = weight;
    }
    return self;
}

+(instancetype)strengthRequired
{
    return [[CSWTierWeightedStrength alloc] initWithName:@"<Required>" symbolicWeight:[[CSWSymbolicWeight alloc] initWithLevels:@[@(1000), @(1000), @(1000)]] weight:1.0];
}

+(instancetype)strengthStrong
{
    return [[CSWTierWeightedStrength alloc] initWithName:@"strong" symbolicWeight:[[CSWSymbolicWeight alloc] initWithLevels:@[@(1.0), @(0), @(0)]] weight:1.0];
}

+(instancetype)strengthMedium
{
    return [[CSWTierWeightedStrength alloc] initWithName:@"medium" symbolicWeight:[[CSWSymbolicWeight alloc] initWithLevels:@[@(0), @(1), @(0)]] weight:1.0];
}

+(instancetype)strengthWeak
{
    return [[CSWTierWeightedStrength alloc] initWithName:@"weak" symbolicWeight:[[CSWSymbolicWeight alloc] initWithLevels:@[@(0), @(0), @(1)]] weight:1.0];
}

-(BOOL)isEqualToStrength: (CSWTierWeightedStrength*)strength
{
    return [self.name isEqual:strength.name] && [self.symbolicWeight isEqualToSymbolicWeight:[strength symbolicWeight]] && [CSWFloatComparator isApproxiatelyEqual:self.weight b:strength.weight];
}

- (BOOL)isEqual:(id)other
{
    if (other == nil) {
        return NO;
    }
    
    if (other == self) {
        return YES;
    }
    
    return [self isEqualToStrength:other];
}

-(BOOL)isRequired
{
    return [self.symbolicWeight isEqual:[[CSWTierWeightedStrength strengthRequired] symbolicWeight]];
}

-(double)value
{
    return self.weight * [self.symbolicWeight value];
}

- (id)copyWithZone:(NSZone *)zone
{
    CSWTierWeightedStrength *copy = [[[self class] allocWithZone:zone] initWithName:self.name symbolicWeight:[self.symbolicWeight copy] weight:self.weight];
    
    return copy;
}

@end
