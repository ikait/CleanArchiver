//
// CarcArchiveTest.m:
//      command-line archive smoke tests for CleanArchiver's archive runner
//

#import <Foundation/Foundation.h>
#import "Carc.h"

static void
CATFail(NSString *message)
{
    fprintf(stderr, "%s\n", [message UTF8String]);
    exit(1);
}

static void
CATWriteFile(NSString *path, NSString *contents)
{
    NSError *error = nil;

    if (![contents writeToFile:path atomically:YES
	encoding:NSUTF8StringEncoding error:&error])
	CATFail([NSString stringWithFormat:@"cannot write %@: %@", path, error]);
}

static void
CATCreateDirectory(NSString *path)
{
    NSError *error = nil;

    if (![[NSFileManager defaultManager] createDirectoryAtPath:path
	withIntermediateDirectories:YES attributes:nil error:&error])
	CATFail([NSString stringWithFormat:@"cannot create %@: %@", path, error]);
}

static void
CATRunArchive(enum archiveType type, NSString *cwd, id input, NSString *output)
{
    BOOL isDirectory = NO;
    Carc *task = [[Carc alloc] init];

    [task setArchiveType:type];
    [task setCurrentDirectoryPath:cwd];
    [task setInput:input];
    [task setOutput:output];
    [task setDiscardRsrc:YES];
    [task setExcludeDSS:YES];
    [task setExcludedFiles:[NSArray arrayWithObject:@"skip.txt"]];
    [task launch];
    [task waitUntilExit];

    if ([task terminationStatus] != 0)
	CATFail([NSString stringWithFormat:@"archive failed: %@", output]);
    if (![[NSFileManager defaultManager] fileExistsAtPath:output
	isDirectory:&isDirectory] || isDirectory)
	CATFail([NSString stringWithFormat:@"archive missing: %@", output]);
}

int
main(int argc, const char *argv[])
{
    @autoreleasepool {
	NSString *root;
	NSString *inputRoot;
	NSString *folder;
	NSString *nested;
	NSString *outputRoot;

	if (argc != 2)
	    CATFail(@"usage: CarcArchiveTest <test-root>");

	root = [NSString stringWithUTF8String:argv[1]];
	inputRoot = [root stringByAppendingPathComponent:@"input"];
	folder = [inputRoot stringByAppendingPathComponent:@"Sample Folder"];
	nested = [folder stringByAppendingPathComponent:@"nested"];
	outputRoot = [root stringByAppendingPathComponent:@"output"];

	CATCreateDirectory(nested);
	CATCreateDirectory(outputRoot);
	CATWriteFile([folder stringByAppendingPathComponent:@"hello.txt"],
	    @"Hello from CleanArchiver\n");
	CATWriteFile([nested stringByAppendingPathComponent:@"inside.txt"],
	    @"Nested file\n");
	CATWriteFile([folder stringByAppendingPathComponent:@".DS_Store"],
	    @"Finder metadata\n");
	CATWriteFile([folder stringByAppendingPathComponent:@"skip.txt"],
	    @"Excluded file\n");

	CATRunArchive(ZIP, inputRoot, @"Sample Folder",
	    [outputRoot stringByAppendingPathComponent:@"sample.zip"]);
	CATRunArchive(GZIP, folder, @"hello.txt",
	    [outputRoot stringByAppendingPathComponent:@"hello.txt.gz"]);
	CATRunArchive(BZIP2, inputRoot, @"Sample Folder",
	    [outputRoot stringByAppendingPathComponent:@"sample.tar.bz2"]);
	CATRunArchive(DMG, inputRoot, @"Sample Folder",
	    [outputRoot stringByAppendingPathComponent:@"sample.dmg"]);

	printf("%s\n", [outputRoot fileSystemRepresentation]);
    }

    return 0;
}
