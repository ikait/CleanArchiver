//
// CACommandLocator.m
//      resolves commands used by CleanArchiver
//

#import "CACommandLocator.h"

@implementation CACommandLocator

+ (NSString *)resourcePath
{
    NSString *override;

    override = [[[NSProcessInfo processInfo] environment]
	objectForKey:@"CLEANARCHIVER_RESOURCE_PATH"];
    if ([override length] > 0) {
	if (![override isAbsolutePath])
	    override = [[[NSFileManager defaultManager] currentDirectoryPath]
		stringByAppendingPathComponent:override];
	return [override stringByStandardizingPath];
    }
    return [[NSBundle mainBundle] resourcePath];
}

+ (NSDictionary *)systemCommandPaths
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
	@"/usr/bin/tar", @"tar",
	@"/usr/bin/gzip", @"gzip",
	@"/usr/bin/bzip2", @"bzip2",
	@"/usr/bin/hdiutil", @"hdiutil",
	@"/usr/bin/find", @"find",
	nil];
}

+ (NSString *)pathForCommand:(NSString *)command
{
    NSFileManager *fm;
    NSString *path;

    fm = [NSFileManager defaultManager];

    if ([command rangeOfString:@"/"].location != NSNotFound) {
	if ([fm isExecutableFileAtPath:command])
	    return command;
	return nil;
    }

    if ([command isEqualToString:@"zip"]) {
	path = [[self resourcePath] stringByAppendingPathComponent:@"zip"];
	if ([fm isExecutableFileAtPath:path])
	    return path;
	return nil;
    }

    path = [[self systemCommandPaths] objectForKey:command];
    if (path != nil && [fm isExecutableFileAtPath:path])
	return path;

    return nil;
}

+ (NSString *)searchPath
{
    return [NSString stringWithFormat:@"%@:/usr/bin:/bin",
	[self resourcePath]];
}

+ (NSMutableDictionary *)environmentWithOverrides:(NSDictionary *)extraEnvironment
{
    NSMutableDictionary *environment;

    environment = [NSMutableDictionary dictionaryWithDictionary:
	[[NSProcessInfo processInfo] environment]];
    [environment setObject:[self searchPath] forKey:@"PATH"];
    if (extraEnvironment != nil)
	[environment addEntriesFromDictionary:extraEnvironment];

    return environment;
}

@end
