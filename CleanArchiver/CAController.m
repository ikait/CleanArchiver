//
// CAController.m:
// 	Controller class of CleanArchiver
//
// Copyright (c) 2005, 2009 INAJIMA Daisuke All rights reserved.
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

#import "CAController.h"
#import "CAArchiveJob.h"
#import "CAArchiveNameBuilder.h"
#import "CAArchivePreferences.h"
#import "CAArchiveQueue.h"
#import "CAView.h"
#import "Carc.h"

static void
CARunAlert(NSString *message)
{
    NSAlert *alert;

    alert = [[NSAlert alloc] init];
    [alert setMessageText:message];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

@implementation CAController

#pragma mark -
#pragma mark Initializing and deallocating

+ (void)initialize
{
    [CAArchivePreferences registerDefaultsInUserDefaults:
	[NSUserDefaults standardUserDefaults]];
}

- (void)awakeFromNib
{
    NSNotificationCenter *nc;
    CAArchivePreferences *preferences;

    nc = [NSNotificationCenter defaultCenter];
    preferences = [[CAArchivePreferences alloc] initWithUserDefaults:
	[NSUserDefaults standardUserDefaults]];

    [_archiveTypeMenu selectItemWithTitle:
	[preferences archiveTypeTitle]];
    switch ([preferences compressionLevel]) {
    case 1:
	[_compressionLevelMenu selectItemAtIndex:FAST];
	break;
    case 9:
	[_compressionLevelMenu selectItemAtIndex:BEST];
	break;
    default:
	[_compressionLevelMenu selectItemAtIndex:NORMAL];
	break;
    }
    [self changeArchiveType:self];
    [_encodingCBox setStringValue:[preferences encoding]];
    [_discardRsrcCheck setState:[preferences discardResourceForks]];
    [_excludeDSSCheck setState:[preferences excludeDSStore]];
    [_replaceAutomaticallyCheck setState:
	[preferences replaceAutomatically]];
    [_archiveIndividuallyCheck
	setState:[preferences archiveIndividually]];
    [_internetEnabledDMGCheck
	setState:[preferences internetEnabledDMG]];

    [nc addObserver:self selector:@selector(handleFilesDropped:)
	name:AOFilesDroppedNotification object:nil];

    [nc addObserver:self selector:@selector(handleArchiveTerminated:)
	name:AOCarcDidFinishArchivingNotification object:nil];
}

- (void)dealloc {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Launching Applications

- (void)applicationWillFinishLaunching:(NSNotification *)n
{

    _operationQueue = [[CAArchiveQueue alloc] init];
    _archiveSessionInProgress = NO;
    _archivingCancelled = NO;
    _terminateAfterArchiving = -1;
}

- (void)applicationDidFinishLaunching:(NSNotification *)n
{

    if (_terminateAfterArchiving == -1)
	_terminateAfterArchiving = NO;
}

#pragma mark -
#pragma mark Opening Files

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{

    if (_terminateAfterArchiving == -1)
	_terminateAfterArchiving = YES;
    [self prepare:filenames];
}

#pragma mark -
#pragma mark Notification handlers

- (void)handleFilesDropped:(NSNotification *)n
{

    [self prepare:[n object]];
}

- (void)handleArchiveTerminated:(NSNotification *)n
{
    NSFileHandle *fh;
    NSFileManager *fm;

    fm = [NSFileManager defaultManager];

    if ([[_mainTask output] isKindOfClass:[NSFileHandle class]]) {
	fh = [_mainTask output];
	[fh truncateFileAtOffset:[fh offsetInFile]];
	[fh closeFile];
    }

    if (_archivingCancelled == NO && [_mainTask terminationStatus] != 0) {
	if ([[_mainTask lastError] length] > 0)
	    CARunAlert([NSString stringWithFormat:@"%@\n%@",
		[NSString stringWithFormat:NSLocalizedString(@"Can't create %@.",nil),
		    [_mainTask output]],
		[_mainTask lastError]]);
	else
	    CARunAlert([NSString
		    stringWithFormat:NSLocalizedString(@"Can't create %@.",nil),
		    [_mainTask output]]);
    }

    [[NSWorkspace sharedWorkspace]
    noteFileSystemChanged:[_mainTask output]];

    _mainTask = nil;

    if ([_operationQueue count] > 0)
	[self cleanArchive];
    else {
	[self endProgressPanel];
	_archiveSessionInProgress = NO;
	if (_terminateAfterArchiving == YES)
	    [NSApp terminate:self];
    }

    _archivingCancelled = NO;
}

#pragma mark -
#pragma mark Closing

- (void)windowWillClose:(NSNotification *)n
{

    [NSApp terminate:self];
}

#pragma mark -
#pragma mark Main menu outlet actions

- (IBAction)cancelArchiving:(id)sender
{
    NSFileManager *fm;
    NSString *dst;

    _archivingCancelled = YES;

    fm = [NSFileManager defaultManager];
    dst  = [_mainTask output];

    [_mainTask terminate];

    if (![dst isEqualToString:@""])
	[fm removeItemAtPath:dst error:nil];
}

- (IBAction)changeArchiveType:(id)sender
{
    enum archiveTypeMenuIndex type;

    type = (enum archiveTypeMenuIndex)[_archiveTypeMenu indexOfSelectedItem];
    switch (type) {
    case DMGT:
	[_discardRsrcCheck setEnabled:NO];
	[_discardRsrcCheck setState:NSControlStateValueOff];
	[_encodingCBox setEnabled:NO];
	[_passwordField setEnabled:YES];
	break;
    case BZIP2T:
    case GZIPT:
	[_discardRsrcCheck setEnabled:YES];
	[_encodingCBox setEnabled:NO];
	[_passwordField setEnabled:NO];
	break;
    case ZIPT:
	[_discardRsrcCheck setEnabled:YES];
	[_encodingCBox setEnabled:YES];
	[_passwordField setEnabled:YES];
	break;
    }
}

- (IBAction)saveAsDefault:(id)sender
{
    CAArchivePreferences *preferences;
    int level;

    switch ([_compressionLevelMenu indexOfSelectedItem]) {
    case FAST:
	    level = 1;
	    break;
    case BEST:
	    level = 9;
	    break;
    default:
	    level = -1;
	    break;
    }

    preferences = [[CAArchivePreferences alloc] initWithUserDefaults:
	[NSUserDefaults standardUserDefaults]];
    [preferences setArchiveTypeTitle:[_archiveTypeMenu titleOfSelectedItem]];
    [preferences setCompressionLevel:level];
    [preferences setEncoding:[_encodingCBox stringValue]];
    [preferences setDiscardResourceForks:[_discardRsrcCheck state]];
    [preferences setExcludeDSStore:[_excludeDSSCheck state]];
    [preferences setReplaceAutomatically:[_replaceAutomaticallyCheck state]];
    [preferences setArchiveIndividually:[_archiveIndividuallyCheck state]];
    [preferences setInternetEnabledDMG:[_internetEnabledDMGCheck state]];
    [preferences save];
}

#pragma mark -
#pragma mark ProgressPanel actions

- (void)beginProgressPanel
{

    [_progressIndicator setIndeterminate:YES];
    [_progressIndicator startAnimation:self];
    [[_excludeDSSCheck window] beginSheet:_progressWindow
	completionHandler:nil];
}

- (void)beginProgressPanelWithText:(NSString *)s
{

    [_progressMessage setStringValue:s];
    [self beginProgressPanel];
}

- (void)endProgressPanel
{

    [_progressIndicator stopAnimation:self];
    [[_progressWindow sheetParent] endSheet:_progressWindow];
    [_progressWindow orderOut:self];
}

#pragma mark -
#pragma mark Treating filenames

- (NSString *)getFileNameWithCandidate:(NSString *)name
{
    NSFileManager *fm;
    NSSavePanel *sp;
    NSString *basename, *dirname;
    NSInteger spStatus;

    if (name == nil)
	return name;

    fm = [NSFileManager defaultManager];
    sp = [NSSavePanel savePanel];
    basename = [name lastPathComponent];
    dirname = [name stringByDeletingLastPathComponent];

    if ([fm fileExistsAtPath:name] || [dirname isEqualToString:@""] ) {
	[sp setNameFieldStringValue:basename];
	if (![dirname isEqualToString:@""])
	    [sp setDirectoryURL:[NSURL fileURLWithPath:dirname]];
	spStatus = [sp runModal];
	if (spStatus == NSModalResponseOK)
	    return [[sp URL] path];
	else
	    return nil;
    } else
	return name;
}

- (NSString *)getArchiveFileNameWithSourceFileNames:(NSArray *)srcnames
    withArchiveType:(enum archiveTypeMenuIndex)type
    withReplaceAutomatically:(BOOL)ra
{
    NSFileManager *fm;
    NSString *dstname, *ext, *srcname;
    BOOL isDir;

    fm = [NSFileManager defaultManager];

    if ((srcname = [srcnames objectAtIndex:0]) == nil)
	return nil;

    [fm fileExistsAtPath:srcname isDirectory:&isDir];

    if (type == DMGT && !isDir) {
	CARunAlert(NSLocalizedString(
	    @"You can make a disk image only from a folder.", nil));
	return nil;
    }

    ext = [CAArchiveNameBuilder archiveExtensionForType:type
	sourceCount:[srcnames count]
	sourceIsDirectory:isDir];
    if (ext == nil)
	exit(1);

    dstname = [CAArchiveNameBuilder archivePathForSourcePaths:srcnames
	archiveType:type
	sourceIsDirectory:isDir];
    if (!ra)
	dstname = [self getFileNameWithCandidate:dstname];

    return dstname;
}

- (NSFileHandle *)getFileHandleOfFile:(NSString *)filename // ???: What purpose of this method?
{
    NSFileManager *fm;

    fm = [NSFileManager defaultManager];

    if (![fm fileExistsAtPath:filename])
	[fm createFileAtPath:filename contents:nil attributes:nil];
    return [NSFileHandle fileHandleForWritingAtPath:filename];
}

#pragma mark -
#pragma mark Compressing and extracting

- (void)prepare:(NSArray *)srcs
{
    CAArchiveJob *job;
    NSString *dst, *encoding, *password, *src;
    enum archiveTypeMenuIndex type;
    int i, level;
    BOOL ai, e_, ed, ie, ra;

    type = (enum archiveTypeMenuIndex)[_archiveTypeMenu indexOfSelectedItem];
    src = [srcs objectAtIndex:0];
    ai = [_archiveIndividuallyCheck state];
    e_ = [_discardRsrcCheck state];
    ed = [_excludeDSSCheck state];
    password = [_passwordField stringValue];
    ie = [_internetEnabledDMGCheck state];
    ra = [_replaceAutomaticallyCheck state];

    encoding = [_encodingCBox stringValue];
    encoding = [encoding stringByTrimmingCharactersInSet:
		    [NSCharacterSet whitespaceCharacterSet]];
    for (i = 0; i < [encoding length]; i++) {
	if ([encoding characterAtIndex:i] == ' ')
	    break;
    }
    if (i < [encoding length])
	encoding = [encoding substringToIndex:i];

    switch ([_compressionLevelMenu indexOfSelectedItem]) {
    case FAST:
	level = 1;
	break;
    case BEST:
	level = 9;
	break;
    default:
	level = -1;
	break;
    }

    if (ai) {
	for (i = 0; i < [srcs count]; i++) {
	    src = [srcs objectAtIndex:i];

	    dst = [self getArchiveFileNameWithSourceFileNames:
		[NSArray arrayWithObject:src]
		withArchiveType:type withReplaceAutomatically:ra];
	    if (dst != nil) {
		job = [CAArchiveJob jobWithSourcePaths:[NSArray arrayWithObject:src]
		    destinationPath:dst
		    archiveType:type
		    compressionLevel:level
		    encoding:encoding
		    password:password
		    discardResourceForks:e_
		    excludeDSStore:ed
		    internetEnabledDMG:ie];
		[_operationQueue enqueueJob:job];
	    }
	}
    } else {
	dst = [self getArchiveFileNameWithSourceFileNames:srcs
		withArchiveType:type withReplaceAutomatically:ra];
	if (dst != nil) {
	    job = [CAArchiveJob jobWithSourcePaths:srcs
		destinationPath:dst
		archiveType:type
		compressionLevel:level
		encoding:encoding
		password:password
		discardResourceForks:e_
		excludeDSStore:ed
		internetEnabledDMG:ie];
	    [_operationQueue enqueueJob:job];
	}
    }

    if (_archiveSessionInProgress == NO && [_operationQueue count] > 0) {
	_archiveSessionInProgress = YES;
	[self beginProgressPanelWithText:
	    NSLocalizedString(@"Preparing...", nil)];
	[self cleanArchive];
    } else if (_terminateAfterArchiving == YES)
	[NSApp terminate:self];

}

- (void)cleanArchive
{
    CAArchiveJob *job;
    NSMutableArray *exfiles;
    enum archiveTypeMenuIndex type;

    exfiles = [NSMutableArray array];
    job = [_operationQueue dequeueJob];
    type = [job archiveType];

    _mainTask = [[Carc alloc] init];

    switch (type) {
    case DMGT:
	[_mainTask setArchiveType:DMG];
	[_mainTask setInternetEnabledDMG:[job internetEnabledDMG]];
	break;
    case BZIP2T:
	[_mainTask setArchiveType:BZIP2];
	break;
    case GZIPT:
	[_mainTask setArchiveType:GZIP];
	break;
    case ZIPT:
	[_mainTask setArchiveType:ZIP];
	break;
    default:
	exit(1);
    }

    if ([job compressionLevel] != -1)
	[_mainTask setCompressionLevel:[job compressionLevel]];

    if ([[job encoding] length] > 0)
	[_mainTask setEncoding:[job encoding]];

    if (![[job password] isEqualToString:@""])
	[_mainTask setArchivePassword:[job password]];

    [_mainTask setInput:[job inputBaseNames]];

    if ([job discardResourceForks])
	[_mainTask setDiscardRsrc:YES];

    if ([job excludeDSStore])
	[_mainTask setExcludeDSS:YES];

    [_mainTask setCurrentDirectoryPath:[job workingDirectoryPath]];
    [_mainTask setOutput:[job destinationPath]];
    [_mainTask setExcludedFiles:exfiles];
    [_mainTask launch];

    [_progressMessage setStringValue:
	[NSString
	    stringWithFormat:NSLocalizedString(@"Archiving: %@", nil),
	    [[job destinationPath] lastPathComponent]]];

}

@end
