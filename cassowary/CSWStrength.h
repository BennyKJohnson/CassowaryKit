#import <Foundation/Foundation.h>
#import "CSWSymbolicWeight.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWStrength : NSObject <NSCopying>

@property (nonatomic, strong) NSString *name;

@property double strength;

-(instancetype)initWithName: (nullable NSString*)name strength: (double)strength;

+(instancetype)strengthRequired;

+(instancetype)strengthStrong;

+(instancetype)strengthMedium;

+(instancetype)strengthWeak;

-(BOOL)isRequired;

-(double)value;

@end

NS_ASSUME_NONNULL_END
