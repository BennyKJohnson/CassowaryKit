#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

 enum CSWVariableType {
    CSWVariableTypeDummy,
    CSWVariableTypeSlack,
    CSWVaraibleTypeVariable,
    CSWVariableTypeObjective,
    CSWVariableTypeExternal
};
typedef enum CSWVariableType CSWVariableType;

@interface CSWVariable : NSObject <NSCopying>

@property CSWVariableType type;

@property NSUInteger id;

@property (nonatomic) CGFloat value;

@property (strong, nonatomic) NSString *name;

-(BOOL)isExternal;

-(BOOL)isDummy;

-(BOOL)isPivotable;

-(BOOL)isRestricted;

-(instancetype)initWithName: (NSString*)name;

+(instancetype)variable;

+(instancetype)variableWithValue: (CGFloat)value;

+(instancetype)variableWithValue: (CGFloat)value name: (NSString* _Nullable)name;

- (id)copyWithZone:(nullable NSZone *)zone;

@end

NS_ASSUME_NONNULL_END
