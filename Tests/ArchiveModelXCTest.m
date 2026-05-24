//
// ArchiveModelXCTest.m
//      Xcode unit tests for controller-side models
//

#import <XCTest/XCTest.h>
#import "CAArchiveJob.h"
#import "CAArchiveNameBuilder.h"
#import "CAArchivePreferences.h"
#import "CAArchiveQueue.h"

@interface ArchiveModelXCTest : XCTestCase
@end

@implementation ArchiveModelXCTest

- (void)testPreferencesRoundTrip
{
    NSUserDefaults *defaults;
    CAArchivePreferences *preferences;

    defaults = [[NSUserDefaults alloc] initWithSuiteName:
	@"jp.sopht.CleanArchiver.ArchiveModelXCTest"];
    [defaults removePersistentDomainForName:
	@"jp.sopht.CleanArchiver.ArchiveModelXCTest"];
    [CAArchivePreferences registerDefaultsInUserDefaults:defaults];

    preferences = [[CAArchivePreferences alloc] initWithUserDefaults:defaults];
    [preferences setArchiveTypeTitle:@"zip"];
    [preferences setCompressionLevel:9];
    [preferences setEncoding:@"CP932"];
    [preferences setArchiveIndividually:YES];
    [preferences save];

    preferences = [[CAArchivePreferences alloc] initWithUserDefaults:defaults];
    XCTAssertEqualObjects([preferences archiveTypeTitle], @"zip");
    XCTAssertEqual([preferences compressionLevel], 9);
    XCTAssertEqualObjects([preferences encoding], @"CP932");
    XCTAssertTrue([preferences archiveIndividually]);
}

- (void)testArchiveNameBuilder
{
    XCTAssertEqualObjects([CAArchiveNameBuilder archivePathForSourcePaths:
	[NSArray arrayWithObject:@"/tmp/readme.txt"]
	archiveType:GZIPT
	sourceIsDirectory:NO], @"/tmp/readme.txt.gz");
    XCTAssertEqualObjects([CAArchiveNameBuilder archivePathForSourcePaths:
	[NSArray arrayWithObject:@"/tmp/Sample Folder"]
	archiveType:ZIPT
	sourceIsDirectory:YES], @"/tmp/Sample Folder.zip");
}

- (void)testJobAndQueue
{
    CAArchiveJob *job;
    CAArchiveQueue *queue;
    NSArray *expectedBaseNames;

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

    expectedBaseNames = [NSArray arrayWithObjects:@"a.txt", @"b.txt", nil];
    XCTAssertEqualObjects([job inputBaseNames], expectedBaseNames);
    XCTAssertEqualObjects([job workingDirectoryPath], @"/tmp");

    queue = [[CAArchiveQueue alloc] init];
    [queue enqueueJob:job];
    XCTAssertEqual([queue count], (NSUInteger)1);
    XCTAssertTrue([queue dequeueJob] == job);
    XCTAssertEqual([queue count], (NSUInteger)0);
}

@end
