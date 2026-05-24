//
// Carc.m:
// 	carc front end
//
// Copyright (c) 2009 INAJIMA Daisuke All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.
//

#import "Carc.h"
#import "CACommandLocator.h"
#import "CADMGArchiver.h"

@interface Carc () <CACommandRunning>
@end

static void
CAAddUniqueObject(NSMutableArray *array, id object)
{
    if (object != nil && ![array containsObject:object])
	[array addObject:object];
}

@implementation Carc

#pragma mark -
#pragma mark Creating and Deallocating Objects

- (id)init
{
    NSNotificationCenter *nc;

    if (self = [super init]) {
	_task = [[NSTask alloc] init];
	_internalTaskCondition = [[NSCondition alloc] init];
	_terminationStatus = 1;
	_launched = NO;
	_usesInternalTask = NO;
	_internalTaskFinished = YES;
	_terminateRequested = NO;

	nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self
	    selector:@selector(taskDidTerminate:)
	    name:NSTaskDidTerminateNotification
	    object:_task];

	[self setCurrentDirectoryPath:@""];
	[self setInput:nil];
	[self setOutput:nil];

	[self setArchiveType:NULL_TYPE];
	[self setArchivePassword:nil];
	[self setCompressionLevel:-1];
	[self setExcludeMacFiles:NO];
	[self setExcludedFiles:nil];
    }
    return self;
}

- (void)dealloc
{
    NSNotificationCenter *nc;

    nc = [NSNotificationCenter defaultCenter];

    [self terminate];
    [nc removeObserver:self];

    [_ownedOutputFileHandle closeFile];
}

#pragma mark -
#pragma mark Running and Stopping a Task

- (NSString *)pathForCommand:(NSString *)command
{
    return [CACommandLocator pathForCommand:command];
}

- (NSArray *)inputArguments
{

    if ([_input isKindOfClass:[NSFileHandle class]] ||
	[_input isKindOfClass:[NSPipe class]])
	return [NSArray arrayWithObject:@"-"];
    if ([_input isKindOfClass:[NSArray class]])
	return _input;
    if ([_input isKindOfClass:[NSString class]])
	return [NSArray arrayWithObject:_input];

    return nil;
}

- (id)standardInputObject
{

    if ([_input isKindOfClass:[NSFileHandle class]] ||
	[_input isKindOfClass:[NSPipe class]])
	return _input;

    return nil;
}

- (NSString *)absolutePathForInput:(NSString *)path
{
    NSString *cwd;

    if ([path isEqualToString:@"-"] || [path isAbsolutePath])
	return path;

    cwd = [_task currentDirectoryPath];
    if ([cwd length] == 0)
	return path;

    return [cwd stringByAppendingPathComponent:path];
}

- (BOOL)inputIsDirectory:(NSString *)path
{
    BOOL isDir;

    if ([path isEqualToString:@"-"])
	return NO;

    return [[NSFileManager defaultManager]
	fileExistsAtPath:[self absolutePathForInput:path] isDirectory:&isDir] && isDir;
}

- (id)standardOutputForArchiveData
{
    NSFileManager *fm;
    NSFileHandle *fh;

    if ([_output isKindOfClass:[NSFileHandle class]] ||
	[_output isKindOfClass:[NSPipe class]])
	return _output;

    if (![_output isKindOfClass:[NSString class]])
	return nil;

    [_ownedOutputFileHandle closeFile];
    _ownedOutputFileHandle = nil;

    fm = [NSFileManager defaultManager];
    [fm createFileAtPath:_output contents:nil attributes:nil];
    fh = [NSFileHandle fileHandleForWritingAtPath:_output];
    if (fh == nil)
	return nil;

    [fh truncateFileAtOffset:0];
    _ownedOutputFileHandle = fh;
    return fh;
}

- (NSString *)outputArgumentWithStandardOutput:(id *)standardOutput
{

    *standardOutput = nil;

    if ([_output isKindOfClass:[NSFileHandle class]] ||
	[_output isKindOfClass:[NSPipe class]]) {
	*standardOutput = _output;
	return @"-";
    }

    if ([_output isKindOfClass:[NSString class]])
	return _output;

    return nil;
}

- (NSMutableArray *)excludedFilePatternsDiscardingResources:(BOOL *)discardResources
{
    NSMutableArray *patterns;
    unsigned i;

    patterns = [NSMutableArray array];
    for (i = 0; i < [_excludedFiles count]; i++)
	CAAddUniqueObject(patterns, [_excludedFiles objectAtIndex:i]);

    if (_excludeDSS)
	CAAddUniqueObject(patterns, @".DS_Store");

    if (_excludeMacFiles) {
	*discardResources = YES;
	CAAddUniqueObject(patterns, @"._*");
	CAAddUniqueObject(patterns, @".DS_Store");
	CAAddUniqueObject(patterns, @"icon\r");
    }

    if ([patterns containsObject:@"._*"])
	*discardResources = YES;

    if (*discardResources)
	CAAddUniqueObject(patterns, @"._*");

    return patterns;
}

- (BOOL)configureTaskWithCommand:(NSString *)command
		       arguments:(NSArray *)arguments
		     environment:(NSDictionary *)extraEnvironment
		  standardInput:(id)standardInput
		 standardOutput:(id)standardOutput
{
    NSMutableDictionary *environment;
    NSString *path;

    path = [self pathForCommand:command];
    if (path == nil)
	return NO;

    environment = [CACommandLocator environmentWithOverrides:extraEnvironment];

    [_task setLaunchPath:path];
    [_task setArguments:arguments];
    [_task setEnvironment:environment];

    if (standardInput != nil)
	[_task setStandardInput:standardInput];
    if (standardOutput != nil)
	[_task setStandardOutput:standardOutput];

    return YES;
}

- (BOOL)configureCompressionTaskWithCommand:(NSString *)compress
{
    NSArray *srcs;
    NSMutableArray *args;
    NSMutableDictionary *environment;
    NSMutableArray *excludedFiles;
    BOOL discardResources;
    BOOL useTar;
    id standardOutput;
    unsigned i;

    srcs = [self inputArguments];
    if ([srcs count] == 0)
	return NO;

    discardResources = _discardRsrc;
    excludedFiles = [self excludedFilePatternsDiscardingResources:&discardResources];
    useTar = [srcs count] > 1 || [self inputIsDirectory:[srcs objectAtIndex:0]]
	|| !discardResources;

    environment = [NSMutableDictionary dictionary];
    if (_compressionLevel != -1) {
	if ([compress isEqualToString:@"bzip2"])
	    [environment setObject:[NSString stringWithFormat:@"-%d", _compressionLevel]
		forKey:@"BZIP2"];
	else if ([compress isEqualToString:@"gzip"])
	    [environment setObject:[NSString stringWithFormat:@"-%d", _compressionLevel]
		forKey:@"GZIP"];
    }

    if (discardResources) {
	[environment setObject:@"1" forKey:@"COPYFILE_DISABLE"];
	[environment setObject:@"1" forKey:@"COPY_EXTENDED_ATTRIBUTES_DISABLE"];
    }

    standardOutput = [self standardOutputForArchiveData];
    if (standardOutput == nil)
	return NO;

    if (useTar) {
	args = [NSMutableArray arrayWithObjects:@"-cf", @"-",
	    @"--use-compress-program", compress, nil];
	for (i = 0; i < [excludedFiles count]; i++) {
	    [args addObject:@"--exclude"];
	    [args addObject:[excludedFiles objectAtIndex:i]];
	}
	[args addObjectsFromArray:srcs];

	return [self configureTaskWithCommand:@"tar"
	    arguments:args
	    environment:environment
	    standardInput:[self standardInputObject]
	    standardOutput:standardOutput];
    }

    args = [NSMutableArray arrayWithObjects:@"-c", [srcs objectAtIndex:0], nil];
    return [self configureTaskWithCommand:compress
	arguments:args
	environment:environment
	standardInput:[self standardInputObject]
	standardOutput:standardOutput];
}

- (BOOL)configureDMGTask
{
    NSArray *srcs;

    srcs = [self inputArguments];
    if ([srcs count] != 1 || ![self inputIsDirectory:[srcs objectAtIndex:0]])
	return NO;
    if (![_output isKindOfClass:[NSString class]])
	return NO;

    return YES;
}

- (int)runCommand:(NSString *)command
	arguments:(NSArray *)arguments
      standardInput:(NSString *)standardInput
     standardOutput:(NSString **)standardOutput
{
    NSTask *task;
    NSPipe *inputPipe;
    NSPipe *outputPipe;
    NSFileHandle *inputWriter;
    NSData *outputData;
    NSString *path;
    int status;

    if (_terminateRequested)
	return 1;

    path = [self pathForCommand:command];
    if (path == nil)
	return 1;

    task = [[NSTask alloc] init];
    [task setLaunchPath:path];
    [task setArguments:arguments];
    if ([[_task currentDirectoryPath] length] > 0)
	[task setCurrentDirectoryPath:[_task currentDirectoryPath]];
    [task setEnvironment:[CACommandLocator environmentWithOverrides:nil]];

    inputPipe = nil;
    if (standardInput != nil) {
	inputPipe = [NSPipe pipe];
	[task setStandardInput:inputPipe];
    }

    outputPipe = nil;
    if (standardOutput != NULL) {
	outputPipe = [NSPipe pipe];
	[task setStandardOutput:outputPipe];
    }

    [_internalTaskCondition lock];
    _runningTask = task;
    [_internalTaskCondition unlock];

    @try {
	[task launch];
	if (standardInput != nil) {
	    inputWriter = [inputPipe fileHandleForWriting];
	    [inputWriter writeData:[standardInput dataUsingEncoding:NSUTF8StringEncoding]];
	    [inputWriter closeFile];
	}
	[task waitUntilExit];
	status = [task terminationStatus];
    }
    @catch (NSException *exception) {
	status = 1;
    }

    if (standardOutput != NULL) {
	outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
	*standardOutput = [[NSString alloc] initWithData:outputData
	    encoding:NSUTF8StringEncoding];
    }

    [_internalTaskCondition lock];
    if (_runningTask == task)
	_runningTask = nil;
    [_internalTaskCondition unlock];

    return status;
}

- (void)runDMGArchive
{
    NSArray *srcs;
    NSString *src;
    NSMutableArray *excludedFiles;
    BOOL discardResources;
    int status;

    @autoreleasepool {
    status = 1;

    srcs = [self inputArguments];
    src = [srcs objectAtIndex:0];
    discardResources = _discardRsrc;
    excludedFiles = [self excludedFilePatternsDiscardingResources:&discardResources];
    if ([CADMGArchiver createDMGFromSource:src
	output:_output
	password:_archivePassword
	internetEnabled:_internetEnabledDMG
	excludedFiles:excludedFiles
	commandRunner:self])
	status = 0;

    [_internalTaskCondition lock];
    _terminationStatus = status;
    _internalTaskFinished = YES;
    [_internalTaskCondition signal];
    [_internalTaskCondition unlock];

    [self performSelectorOnMainThread:@selector(postDidFinishNotification)
	withObject:nil
	waitUntilDone:NO];
    }
}

- (BOOL)configureZipTask
{
    NSArray *srcs;
    NSMutableArray *args;
    NSMutableArray *excludedFiles;
    BOOL discardResources;
    NSString *dst;
    id standardOutput;
    unsigned i;

    srcs = [self inputArguments];
    if ([srcs count] == 0)
	return NO;

    discardResources = _discardRsrc;
    excludedFiles = [self excludedFilePatternsDiscardingResources:&discardResources];

    args = [NSMutableArray arrayWithObject:@"-q"];
    if ([srcs count] > 1 || [self inputIsDirectory:[srcs objectAtIndex:0]])
	[args addObject:@"-r"];
    if ([_encoding length] > 0) {
	[args addObject:@"-CF"];
	[args addObject:@"UTF-8-MAC"];
	[args addObject:@"-CT"];
	[args addObject:_encoding];
    }
    if (_compressionLevel != -1)
	[args addObject:[NSString stringWithFormat:@"-%d", _compressionLevel]];
    if ([_archivePassword length] > 0) {
	[args addObject:@"-P"];
	[args addObject:_archivePassword];
    }
    if (discardResources)
	[args addObject:@"-df"];

    dst = [self outputArgumentWithStandardOutput:&standardOutput];
    if (dst == nil)
	return NO;
    if ([_output isKindOfClass:[NSString class]])
	[[NSFileManager defaultManager] removeItemAtPath:_output error:nil];

    [args addObject:dst];
    [args addObjectsFromArray:srcs];

    for (i = 0; i < [excludedFiles count]; i++) {
	[args addObject:@"-x"];
	[args addObject:[NSString stringWithFormat:@"*/%@",
	    [excludedFiles objectAtIndex:i]]];
    }

    return [self configureTaskWithCommand:@"zip"
	arguments:args
	environment:nil
	standardInput:[self standardInputObject]
	standardOutput:standardOutput];
}

- (BOOL)configureArchiveTask
{

    switch (_archiveType) {
    case BZIP2:
	return [self configureCompressionTaskWithCommand:@"bzip2"];
    case DMG:
	return [self configureDMGTask];
    case GZIP:
	return [self configureCompressionTaskWithCommand:@"gzip"];
    case ZIP:
	return [self configureZipTask];
    default:
	return NO;
    }
}

- (void)postDidFinishNotification
{

    [[NSNotificationCenter defaultCenter]
	postNotificationName:AOCarcDidFinishArchivingNotification
	object:self];
}

- (void)finishWithoutLaunching
{

    _terminationStatus = 1;
    [_ownedOutputFileHandle closeFile];
    _ownedOutputFileHandle = nil;
    [self performSelector:@selector(postDidFinishNotification)
	withObject:nil
	afterDelay:0];
}

- (void)launch
{

    if (_archiveType == DMG) {
	if (![self configureDMGTask]) {
	    [self finishWithoutLaunching];
	    return;
	}
	[_internalTaskCondition lock];
	_usesInternalTask = YES;
	_internalTaskFinished = NO;
	_terminateRequested = NO;
	_launched = YES;
	_terminationStatus = 1;
	[_internalTaskCondition unlock];
	[self performSelectorInBackground:@selector(runDMGArchive)
	    withObject:nil];
	return;
    }

    if (![self configureArchiveTask]) {
	[self finishWithoutLaunching];
	return;
    }

    @try {
	[_task launch];
	_launched = YES;
    }
    @catch (NSException *exception) {
	[self finishWithoutLaunching];
    }
}

- (void)resume
{

    if (_launched && [_task isRunning])
	[_task resume];
}

- (void)suspend
{

    if (_launched && [_task isRunning])
	[_task suspend];
}

- (void)terminate
{

    [_internalTaskCondition lock];
    _terminateRequested = YES;
    if (_usesInternalTask && _runningTask != nil && [_runningTask isRunning])
	[_runningTask terminate];
    [_internalTaskCondition unlock];

    if (_launched && [_task isRunning])
	[_task terminate];
}

- (void)waitUntilExit
{

    if (_usesInternalTask) {
	[_internalTaskCondition lock];
	while (!_internalTaskFinished)
	    [_internalTaskCondition wait];
	[_internalTaskCondition unlock];
	return;
    }

    if (_launched) {
	[_task waitUntilExit];
	_terminationStatus = [_task terminationStatus];
    }
}

#pragma mark -
#pragma mark Querying the Task State

- (int)terminationStatus
{

    if (_usesInternalTask)
	return _terminationStatus;

    if (_launched && ![_task isRunning])
	_terminationStatus = [_task terminationStatus];

    return _terminationStatus;
}

- (void)taskDidTerminate:(NSNotification *)n
{

    if ([n object] == _task) {
	_terminationStatus = [_task terminationStatus];
	[_ownedOutputFileHandle closeFile];
	_ownedOutputFileHandle = nil;
	[self postDidFinishNotification];
    }
}

#pragma mark -
#pragma mark Setter and Getter method

- (NSString *)currentDirectoryPath
{

    return [_task currentDirectoryPath];
}
- (void)setCurrentDirectoryPath:(NSString *)path
{

    [_task setCurrentDirectoryPath:path];
}

- (id)input
{

    return _input;
}
- (void)setInput:(id)anObject
{

    _input = anObject;
}

- (id)output
{

    return _output;
}
- (void)setOutput:(id)anObject
{

    _output = anObject;
}

- (NSString *)archivePassword
{

    return _archivePassword;
}
- (void)setArchivePassword:(NSString *)password
{

    _archivePassword = [password copy];
}

- (enum archiveType)archiveType
{

    return _archiveType;
}
- (void)setArchiveType:(enum archiveType)type
{

    _archiveType = type;
}

- (int)compressionLevel
{

    return _compressionLevel;
}
- (void)setCompressionLevel:(int)level
{

    _compressionLevel = level;
}

- (BOOL)discardRsrc
{

    return _discardRsrc;
}
- (void)setDiscardRsrc:(BOOL)yn
{

    _discardRsrc = yn;
}

- (NSString *)encoding
{

    return _encoding;
}
- (void)setEncoding:(NSString *)encoding
{

    _encoding = [encoding copy];
}

- (BOOL)excludeDSS
{

    return _excludeDSS;
}
- (void)setExcludeDSS:(BOOL)yn
{

    _excludeDSS = yn;
}

- (BOOL)excludeMacFiles
{

    return _excludeMacFiles;
}
- (void)setExcludeMacFiles:(BOOL)yn
{

    _excludeMacFiles = yn;
}

- (NSArray *)excludedFiles
{

    return _excludedFiles;
}
- (void)setExcludedFiles:(NSArray *)filenames
{

    _excludedFiles = [filenames copy];
}

- (BOOL)internetEnabledDMG
{

    return _internetEnabledDMG;
}
- (void)setInternetEnabledDMG:(BOOL)yn
{

    _internetEnabledDMG = yn;
}

@end

NSString *const AOCarcDidFinishArchivingNotification =
	      @"AOCarcDidFinishArchivingNotification";
