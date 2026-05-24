//
// CACommandLocator.h
//      resolves commands used by CleanArchiver
//

#import <Foundation/Foundation.h>

@interface CACommandLocator : NSObject

+ (NSString *)resourcePath;
+ (NSString *)pathForCommand:(NSString *)command;
+ (NSString *)searchPath;
+ (NSMutableDictionary *)environmentWithOverrides:(NSDictionary *)extraEnvironment;

@end
