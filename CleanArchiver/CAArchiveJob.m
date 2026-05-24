//
// CAArchiveJob.m
//      immutable archive work item
//

#import "CAArchiveJob.h"

@implementation CAArchiveJob

+ (id)jobWithSourcePaths:(NSArray *)sourcePaths
	 destinationPath:(NSString *)destinationPath
	    archiveType:(enum archiveTypeMenuIndex)archiveType
       compressionLevel:(int)compressionLevel
	       encoding:(NSString *)encoding
	       password:(NSString *)password
   discardResourceForks:(BOOL)discardResourceForks
	 excludeDSStore:(BOOL)excludeDSStore
     internetEnabledDMG:(BOOL)internetEnabledDMG
{
    CAArchiveJob *job;

    job = [[self alloc] init];
    job->_sourcePaths = [sourcePaths copy];
    job->_destinationPath = [destinationPath copy];
    job->_archiveType = archiveType;
    job->_compressionLevel = compressionLevel;
    job->_encoding = [encoding copy];
    job->_password = [password copy];
    job->_discardResourceForks = discardResourceForks;
    job->_excludeDSStore = excludeDSStore;
    job->_internetEnabledDMG = internetEnabledDMG;

    return job;
}

- (NSArray *)sourcePaths { return _sourcePaths; }
- (NSString *)destinationPath { return _destinationPath; }
- (enum archiveTypeMenuIndex)archiveType { return _archiveType; }
- (int)compressionLevel { return _compressionLevel; }
- (NSString *)encoding { return _encoding; }
- (NSString *)password { return _password; }
- (BOOL)discardResourceForks { return _discardResourceForks; }
- (BOOL)excludeDSStore { return _excludeDSStore; }
- (BOOL)internetEnabledDMG { return _internetEnabledDMG; }

- (NSString *)workingDirectoryPath
{
    return [[_sourcePaths objectAtIndex:0] stringByDeletingLastPathComponent];
}

- (id)inputBaseNames
{
    NSMutableArray *baseNames;
    unsigned i;

    if ([_sourcePaths count] == 1)
	return [[_sourcePaths objectAtIndex:0] lastPathComponent];

    baseNames = [NSMutableArray array];
    for (i = 0; i < [_sourcePaths count]; i++)
	[baseNames addObject:[[_sourcePaths objectAtIndex:i] lastPathComponent]];
    return baseNames;
}

@end
