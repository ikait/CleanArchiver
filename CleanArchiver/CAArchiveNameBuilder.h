//
// CAArchiveNameBuilder.h
//      builds default archive destination names
//

#import <Foundation/Foundation.h>
#import "CAArchiveTypes.h"

@interface CAArchiveNameBuilder : NSObject

+ (NSString *)archivePathForSourcePaths:(NSArray *)sourcePaths
			    archiveType:(enum archiveTypeMenuIndex)archiveType
		      sourceIsDirectory:(BOOL)sourceIsDirectory;
+ (NSString *)archiveExtensionForType:(enum archiveTypeMenuIndex)archiveType
		    sourceCount:(NSUInteger)sourceCount
	     sourceIsDirectory:(BOOL)sourceIsDirectory;

@end
