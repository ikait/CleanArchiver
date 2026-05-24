//
// CAArchiveNameBuilder.m
//      builds default archive destination names
//

#import "CAArchiveNameBuilder.h"

@implementation CAArchiveNameBuilder

+ (NSString *)archiveExtensionForType:(enum archiveTypeMenuIndex)archiveType
		    sourceCount:(NSUInteger)sourceCount
	     sourceIsDirectory:(BOOL)sourceIsDirectory
{
    switch (archiveType) {
    case DMGT:
	return @"dmg";
    case BZIP2T:
	return (sourceCount == 1 && !sourceIsDirectory) ? @"bz2" : @"tar.bz2";
    case GZIPT:
	return (sourceCount == 1 && !sourceIsDirectory) ? @"gz" : @"tar.gz";
    case ZIPT:
	return @"zip";
    }

    return nil;
}

+ (NSString *)archivePathForSourcePaths:(NSArray *)sourcePaths
			    archiveType:(enum archiveTypeMenuIndex)archiveType
		      sourceIsDirectory:(BOOL)sourceIsDirectory
{
    NSString *extension;

    extension = [self archiveExtensionForType:archiveType
	sourceCount:[sourcePaths count]
	sourceIsDirectory:sourceIsDirectory];
    if (extension == nil)
	return nil;

    if ([sourcePaths count] == 1)
	return [[sourcePaths objectAtIndex:0] stringByAppendingPathExtension:extension];

    return [@"Archive" stringByAppendingPathExtension:extension];
}

@end
