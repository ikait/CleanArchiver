//
// CAArchiveJob.h
//      immutable archive work item
//

#import <Foundation/Foundation.h>
#import "CAArchiveTypes.h"

@interface CAArchiveJob : NSObject
{
    NSArray *_sourcePaths;
    NSString *_destinationPath;
    enum archiveTypeMenuIndex _archiveType;
    int _compressionLevel;
    NSString *_encoding;
    NSString *_password;
    BOOL _discardResourceForks;
    BOOL _excludeDSStore;
    BOOL _internetEnabledDMG;
}

+ (id)jobWithSourcePaths:(NSArray *)sourcePaths
	 destinationPath:(NSString *)destinationPath
	    archiveType:(enum archiveTypeMenuIndex)archiveType
       compressionLevel:(int)compressionLevel
	       encoding:(NSString *)encoding
	       password:(NSString *)password
   discardResourceForks:(BOOL)discardResourceForks
	 excludeDSStore:(BOOL)excludeDSStore
     internetEnabledDMG:(BOOL)internetEnabledDMG;

- (NSArray *)sourcePaths;
- (NSString *)destinationPath;
- (enum archiveTypeMenuIndex)archiveType;
- (int)compressionLevel;
- (NSString *)encoding;
- (NSString *)password;
- (BOOL)discardResourceForks;
- (BOOL)excludeDSStore;
- (BOOL)internetEnabledDMG;
- (NSString *)workingDirectoryPath;
- (id)inputBaseNames;

@end
