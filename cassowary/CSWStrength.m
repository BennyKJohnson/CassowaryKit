#import "CSWStrength.h"

@implementation CSWStrength

-(instancetype)initWithName: (NSString*)name weight: (CSWSymbolicWeight*)weight
{
    if (self = [super init]) {
        self.name = name;
        self.weight = weight;
    }
    return self;
}

+(instancetype)strengthRequired
{
    return [[CSWStrength alloc] initWithName:@"<Required>" weight:[[CSWSymbolicWeight alloc] initWithLevels:@[@(1000), @(1000), @(1000)]]];
}

+(instancetype)strengthStrong
{
    return [[CSWStrength alloc] initWithName:@"strong" weight:[[CSWSymbolicWeight alloc] initWithLevels:@[@(1.0), @(0), @(0)]]];
}

+(instancetype)strengthMedium
{
    return [[CSWStrength alloc] initWithName:@"medium" weight:[[CSWSymbolicWeight alloc] initWithLevels:@[@(0), @(1), @(0)]]];
}

+(instancetype)strengthWeak
{
    return [[CSWStrength alloc] initWithName:@"weak" weight:[[CSWSymbolicWeight alloc] initWithLevels:@[@(0), @(0), @(1)]]];
}

-(BOOL)isEqualToStrength: (CSWStrength*)strength
{
    return [self.name isEqual:strength.name] && [self.weight isEqualToSymbolicWeight:[strength weight]];
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
    return [self.weight isEqual:[[CSWStrength strengthRequired] weight]];
}

@end
