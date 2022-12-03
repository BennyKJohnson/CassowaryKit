#import <Foundation/Foundation.h>
#import "CSWSymbolicWeight.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSWStrength : NSObject

@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) CSWSymbolicWeight *weight;

-(instancetype)initWithName: (NSString*)name weight: (CSWSymbolicWeight*)weight;

+(instancetype)strengthRequired;

+(instancetype)strengthStrong;

+(instancetype)strengthMedium;

+(instancetype)strengthWeak;

-(BOOL)isRequired;

@end

NS_ASSUME_NONNULL_END
