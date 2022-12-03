#import "CSWStrength.h"
#import "CSWFloatComparator.h"

@implementation CSWStrength

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
    return [[CSWStrength alloc] initWithName:@"<Required>" symbolicWeight:[[CSWSymbolicWeight alloc] initWithLevels:@[@(1000), @(1000), @(1000)]] weight:1.0];
}

+(instancetype)strengthStrong
{
    return [[CSWStrength alloc] initWithName:@"strong" symbolicWeight:[[CSWSymbolicWeight alloc] initWithLevels:@[@(1.0), @(0), @(0)]] weight:1.0];
}

+(instancetype)strengthMedium
{
    return [[CSWStrength alloc] initWithName:@"medium" symbolicWeight:[[CSWSymbolicWeight alloc] initWithLevels:@[@(0), @(1), @(0)]] weight:1.0];
}

+(instancetype)strengthWeak
{
    return [[CSWStrength alloc] initWithName:@"weak" symbolicWeight:[[CSWSymbolicWeight alloc] initWithLevels:@[@(0), @(0), @(1)]] weight:1.0];
}

-(BOOL)isEqualToStrength: (CSWStrength*)strength
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
    return [self.symbolicWeight isEqual:[[CSWStrength strengthRequired] symbolicWeight]];
}

-(double)value
{
    return self.weight * [self.symbolicWeight value];
}

- (id)copyWithZone:(NSZone *)zone
{
    CSWStrength *copy = [[[self class] allocWithZone:zone] initWithName:self.name symbolicWeight:[self.symbolicWeight copy] weight:self.weight];
    
    return copy;
}

@end
