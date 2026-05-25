//
// ControllerModelTest.m
//      unit checks for controller-side archive models
//

#import <Foundation/Foundation.h>
#import "CAArchiveJob.h"
#import "CAArchiveCommandBuilder.h"
#import "CAArchiveNameBuilder.h"
#import "CAArchivePreferences.h"
#import "CAArchiveQueue.h"

static void
CATFail(NSString *message)
{
    fprintf(stderr, "%s\n", [message UTF8String]);
    exit(1);
}

static void
CATAssert(BOOL condition, NSString *message)
{
    if (!condition)
	CATFail(message);
}

int
main(int argc, const char *argv[])
{
    @autoreleasepool {
	NSUserDefaults *defaults;
	CAArchivePreferences *preferences;
	CAArchiveCommandSpec *zipSpec;
	CAArchiveJob *job;
	CAArchiveQueue *queue;
	NSString *folderArchive;
	NSString *singleFileArchive;

	defaults = [[NSUserDefaults alloc] initWithSuiteName:
	    @"jp.sopht.CleanArchiver.ControllerModelTest"];
	[defaults removePersistentDomainForName:
	    @"jp.sopht.CleanArchiver.ControllerModelTest"];
	[CAArchivePreferences registerDefaultsInUserDefaults:defaults];

	preferences = [[CAArchivePreferences alloc] initWithUserDefaults:defaults];
	CATAssert([preferences compressionLevel] == -1,
	    @"default compression level should be archiver default");
	CATAssert([preferences discardResourceForks],
	    @"default should discard resource forks");

	[preferences setArchiveTypeIdentifier:CAArchiveTypeIdentifierZIP];
	[preferences setCompressionLevel:9];
	[preferences setEncoding:@"CP932"];
	[preferences setExcludeDSStore:YES];
	[preferences setArchiveIndividually:YES];
	[preferences save];

	preferences = [[CAArchivePreferences alloc] initWithUserDefaults:defaults];
	CATAssert([[preferences archiveTypeIdentifier]
	    isEqualToString:CAArchiveTypeIdentifierZIP],
	    @"archive type should persist");
	CATAssert([preferences compressionLevel] == 9,
	    @"compression level should persist");
	CATAssert([[preferences encoding] isEqualToString:@"CP932"],
	    @"encoding should persist");
	CATAssert([preferences archiveIndividually],
	    @"archive individually should persist");

	folderArchive = [CAArchiveNameBuilder archivePathForSourcePaths:
	    [NSArray arrayWithObject:@"/tmp/Sample Folder"]
	    archiveType:ZIPT
	    sourceIsDirectory:YES];
	CATAssert([folderArchive isEqualToString:@"/tmp/Sample Folder.zip"],
	    @"folder zip path should use .zip");

	singleFileArchive = [CAArchiveNameBuilder archivePathForSourcePaths:
	    [NSArray arrayWithObject:@"/tmp/readme.txt"]
	    archiveType:GZIPT
	    sourceIsDirectory:NO];
	CATAssert([singleFileArchive isEqualToString:@"/tmp/readme.txt.gz"],
	    @"single gzip path should use .gz");

	CATAssert(CAArchiveTypeMenuIndexForIdentifier(@"unknown") == GZIPT,
	    @"unknown archive type should fall back to gzip");

	zipSpec = [CAArchiveCommandBuilder zipCommandSpecWithSourceArguments:
	    [NSArray arrayWithObject:@"Sample Folder"]
	    firstSourceIsDirectory:YES
	    outputArgument:@"/tmp/Sample Folder.zip"
	    encoding:@"CP932"
	    compressionLevel:9
	    password:@"secret"
	    discardResourceForks:YES
	    excludeDSStore:YES
	    excludeMacFiles:NO
	    explicitExcludedFiles:[NSArray arrayWithObject:@"skip.txt"]];
	CATAssert([[zipSpec command] isEqualToString:@"zip"],
	    @"zip command spec should use zip");
	CATAssert([[zipSpec arguments] containsObject:@"-r"],
	    @"zip folder spec should recurse");
	CATAssert([[zipSpec arguments] containsObject:@"-df"],
	    @"zip spec should discard resource forks");
	CATAssert([[zipSpec arguments] containsObject:@"*/skip.txt"],
	    @"zip spec should exclude explicit files");

	job = [CAArchiveJob jobWithSourcePaths:
	    [NSArray arrayWithObjects:@"/tmp/a.txt", @"/tmp/b.txt", nil]
	    destinationPath:@"/tmp/Archive.zip"
	    archiveType:ZIPT
	    compressionLevel:1
	    encoding:@"UTF-8"
	    password:@"secret"
	    discardResourceForks:YES
	    excludeDSStore:YES
	    internetEnabledDMG:NO];
	CATAssert([[job inputBaseNames] isEqualToArray:
	    [NSArray arrayWithObjects:@"a.txt", @"b.txt", nil]],
	    @"job should expose source base names");
	CATAssert([[job workingDirectoryPath] isEqualToString:@"/tmp"],
	    @"job should use first source directory as working directory");

	queue = [[CAArchiveQueue alloc] init];
	[queue enqueueJob:job];
	CATAssert([queue count] == 1, @"queue should count enqueued jobs");
	CATAssert([queue dequeueJob] == job, @"queue should be FIFO");
	CATAssert([queue count] == 0, @"queue should remove dequeued jobs");
    }

    return 0;
}
