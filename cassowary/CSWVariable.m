#import "CSWVariable.h"

@implementation CSWVariable

- (instancetype)init {
    if (self = [super init]) {
        self.type = CSWVaraibleTypeVariable;
    }
    
    return self;
}

- (instancetype)initWithName:(NSString *)name
{
    if (self = [super init]) {
        self.name = name;
        self.type = CSWVaraibleTypeVariable;
    }
    
    return self;
}

- (instancetype)initWithName:(NSString *)name type: (CSWVariableType)type
{
    if (self = [super init]) {
        self.name = name;
        self.type = type;
    }
    
    return self;
}

+(instancetype)dummyVariableWithName: (NSString*)name
{
    return [[CSWVariable alloc] initWithName:name type:CSWVariableTypeDummy];
}

+(instancetype)slackVariableWithName: (NSString*)name
{
    return [[CSWVariable alloc] initWithName:name type:CSWVariableTypeSlack];
}

+(instancetype)objectiveVariableWithName: (NSString*)name
{
    return [[CSWVariable alloc] initWithName:name type:CSWVariableTypeObjective];
}

+(instancetype)variableWithValue: (CGFloat)value
{
    return [self variableWithValue:value name:nil];
}

+(instancetype)variable
{
    return [self variableWithValue:0 name:nil];
}

+(instancetype)variableWithValue: (CGFloat)value name: (NSString*)name
{
    CSWVariable *variable = [[CSWVariable alloc] initWithName:name type:CSWVariableTypeExternal];
    variable.value = value;
    return variable;
}

-(BOOL)isDummy
{
    return self.type == CSWVariableTypeDummy;
}

- (BOOL)isExternal
{
    if (self.type == CSWVariableTypeExternal) {
        return YES;
    }
    return NO;
}

- (BOOL)isPivotable
{
    if (self.type == CSWVariableTypeSlack) {
        return YES;
    }
    return NO;
}

- (BOOL)isRestricted
{
    if (self.type == CSWVariableTypeDummy || self.type == CSWVariableTypeSlack) {
        return YES;
    }
    return NO;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Do not use CSWVariable directly" userInfo:nil];
    [exception raise];
    return nil;
}

- (NSString *)description
{
    if (self.type == CSWVariableTypeDummy) {
        return [NSString stringWithFormat:@"[%@:dummy]", self.name];
    } else if (self.type == CSWVariableTypeSlack) {
        return [NSString stringWithFormat:@"[%@:slack]", self.name];
    } else if (self.type == CSWVariableTypeExternal) {
        return [NSString stringWithFormat:@"[%@:%.02f]", self.name, self.value];
    } else if (self.type == CSWVariableTypeObjective) {
        return [NSString stringWithFormat:@"[%@:objective]", self.name];
    }
    
    return [NSString stringWithFormat:@"[%@]", self.name];
}

- (BOOL)isEqual:(id)other
{
    if (![other isKindOfClass:[CSWVariable class]]) {
        return NO;
    }
    
    CSWVariable *otherVariable = (CSWVariable*)other;
    
    if (self.type != otherVariable.type) {
        return NO;
    }
    
    if (![self.name isEqual: otherVariable.name]) {
        return NO;
    }
    
    if (self.type == CSWVariableTypeExternal && self.value != otherVariable.value) {
        return NO;
    }

    return YES;
}

@end
