//
// ArchiveModelXCTest.m
//      Xcode unit tests for controller-side models
//

#import <XCTest/XCTest.h>
#import "CAArchiveJob.h"
#import "CAArchiveCommandBuilder.h"
#import "CAArchiveNameBuilder.h"
#import "CAArchivePreferences.h"
#import "CAArchiveQueue.h"
#import "CADMGArchiver.h"

@interface CAFailingCommandRunner : NSObject <CACommandRunning>
@end

@implementation CAFailingCommandRunner

- (int)runCommand:(NSString *)command
	arguments:(NSArray *)arguments
    standardInput:(NSString *)standardInput
   standardOutput:(NSString **)standardOutput
{
    return 1;
}

@end

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
    [preferences setArchiveTypeIdentifier:CAArchiveTypeIdentifierZIP];
    [preferences setCompressionLevel:9];
    [preferences setEncoding:@"CP932"];
    [preferences setArchiveIndividually:YES];
    [preferences save];

    preferences = [[CAArchivePreferences alloc] initWithUserDefaults:defaults];
    XCTAssertEqualObjects([preferences archiveTypeIdentifier],
	CAArchiveTypeIdentifierZIP);
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
    XCTAssertEqualObjects(CAArchiveTypeIdentifierForMenuIndex(DMGT),
	CAArchiveTypeIdentifierDMG);
    XCTAssertEqual(CAArchiveTypeMenuIndexForIdentifier(@"unknown"), GZIPT);
}

- (void)testArchiveCommandBuilder
{
    CAArchiveCommandSpec *spec;
    NSArray *expectedArguments;

    spec = [CAArchiveCommandBuilder compressionCommandSpecWithCommand:@"gzip"
	sourceArguments:[NSArray arrayWithObject:@"readme.txt"]
	firstSourceIsDirectory:NO
	compressionLevel:1
	discardResourceForks:YES
	excludeDSStore:YES
	excludeMacFiles:NO
	explicitExcludedFiles:nil];
    expectedArguments = [NSArray arrayWithObjects:@"-c", @"readme.txt", nil];
    XCTAssertEqualObjects([spec command], @"gzip");
    XCTAssertEqualObjects([spec arguments], expectedArguments);
    XCTAssertEqualObjects([[spec environment] objectForKey:@"GZIP"], @"-1");

    spec = [CAArchiveCommandBuilder zipCommandSpecWithSourceArguments:
	[NSArray arrayWithObject:@"Sample Folder"]
	firstSourceIsDirectory:YES
	outputArgument:@"Sample Folder.zip"
	encoding:@"CP932"
	compressionLevel:9
	password:@"secret"
	discardResourceForks:YES
	excludeDSStore:YES
	excludeMacFiles:NO
	explicitExcludedFiles:[NSArray arrayWithObject:@"skip.txt"]];
    XCTAssertEqualObjects([spec command], @"zip");
    XCTAssertTrue([[spec arguments] containsObject:@"-r"]);
    XCTAssertTrue([[spec arguments] containsObject:@"-df"]);
    XCTAssertTrue([[spec arguments] containsObject:@"*/skip.txt"]);
}

- (void)testDMGFailureReason
{
    CAFailingCommandRunner *runner;
    NSString *errorMessage;
    BOOL ok;

    runner = [[CAFailingCommandRunner alloc] init];
    errorMessage = nil;
    ok = [CADMGArchiver createDMGFromSource:@"/tmp/source"
	output:@"/tmp/output.dmg"
	password:nil
	internetEnabled:NO
	excludedFiles:nil
	commandRunner:runner
	errorMessage:&errorMessage];

    XCTAssertFalse(ok);
    XCTAssertEqualObjects(errorMessage, @"Could not create temporary disk image.");
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
