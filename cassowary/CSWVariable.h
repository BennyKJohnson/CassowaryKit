#import <Foundation/Foundation.h>
#import "CSWAbstractVariable.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWVariable : CSWAbstractVariable <NSCopying>

@property (nonatomic) CGFloat value;

-(instancetype)initWithValue: (CGFloat)value;

-(instancetype)initWithValue: (CGFloat)value name: (nullable NSString*)name;

- (id)copyWithZone:(nullable NSZone *)zone;

+(instancetype)variable;

@end

NS_ASSUME_NONNULL_END
