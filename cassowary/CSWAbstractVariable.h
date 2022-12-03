#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CSWAbstractVariable : NSObject <NSCopying>

-(BOOL)isExternal;

-(BOOL)isDummy;

-(BOOL)isPivotable;

-(BOOL)isRestricted;

@property (strong, nonatomic) NSString *name;

-(instancetype)initWithName: (NSString*)name;

- (id)copyWithZone:(nullable NSZone *)zone;

@end

NS_ASSUME_NONNULL_END
