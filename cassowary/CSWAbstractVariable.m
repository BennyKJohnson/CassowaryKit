#import "CSWAbstractVariable.h"

@implementation CSWAbstractVariable

- (instancetype)initWithName:(NSString *)name
{
    if (self = [super init]) {
        self.name = name;
    }
    
    return self;
}

-(BOOL)isDummy
{
    return NO;
}

- (BOOL)isExternal
{
    return NO;
}

- (BOOL)isPivotable
{
    return NO;
}

- (BOOL)isRestricted
{
    return NO;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Do not use CSWAbstractVariable directly" userInfo:nil];
    [exception raise];
    return nil;
}

@end
