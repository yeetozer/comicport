#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface ZipExtractor : NSObject
+ (BOOL)extractArchiveAtPath:(NSString *)archivePath toDirectory:(NSString *)destination error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
