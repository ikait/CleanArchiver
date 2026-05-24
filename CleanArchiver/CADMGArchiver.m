//
// CADMGArchiver.m
//      creates compressed disk images for CleanArchiver
//

#import "CADMGArchiver.h"

@implementation CADMGArchiver

+ (NSString *)temporaryDMGPathForOutputPath:(NSString *)outputPath
{
    NSString *base;

    if ([[outputPath pathExtension] isEqualToString:@"dmg"])
	base = [outputPath stringByDeletingPathExtension];
    else
	base = outputPath;

    return [base stringByAppendingPathExtension:@"temp.dmg"];
}

+ (NSString *)deviceFromHdiutilAttachOutput:(NSString *)output
{
    NSRange range;
    NSString *tail;
    NSUInteger i;

    range = [output rangeOfString:@"/dev/disk"];
    if (range.location == NSNotFound)
	return nil;

    tail = [output substringFromIndex:range.location];
    for (i = 0; i < [tail length]; i++) {
	unichar c = [tail characterAtIndex:i];
	if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:c])
	    break;
    }

    return [tail substringToIndex:i];
}

+ (NSString *)volumeFromHdiutilAttachOutput:(NSString *)output
{
    NSArray *lines;
    NSString *line;
    NSRange range;
    NSInteger i;

    lines = [output componentsSeparatedByCharactersInSet:
	[NSCharacterSet newlineCharacterSet]];

    for (i = [lines count] - 1; i >= 0; i--) {
	line = [lines objectAtIndex:i];
	range = [line rangeOfString:@"/Volumes/"];
	if (range.location != NSNotFound)
	    return [line substringFromIndex:range.location];
    }

    return nil;
}

+ (BOOL)removeExcludedFiles:(NSArray *)excludedFiles
		 fromVolume:(NSString *)volume
	      commandRunner:(id<CACommandRunning>)commandRunner
{
    NSMutableArray *args;
    unsigned i;

    if ([excludedFiles count] == 0)
	return YES;

    args = [NSMutableArray arrayWithObjects:volume, @"(", nil];
    for (i = 0; i < [excludedFiles count]; i++) {
	if (i > 0)
	    [args addObject:@"-o"];
	[args addObject:@"-name"];
	[args addObject:[excludedFiles objectAtIndex:i]];
    }
    [args addObject:@")"];
    [args addObject:@"-delete"];

    return [commandRunner runCommand:@"find"
	arguments:args
	standardInput:nil
	standardOutput:NULL] == 0;
}

+ (BOOL)createDMGFromSource:(NSString *)source
		     output:(NSString *)output
		   password:(NSString *)password
	    internetEnabled:(BOOL)internetEnabled
	      excludedFiles:(NSArray *)excludedFiles
	      commandRunner:(id<CACommandRunning>)commandRunner
{
    NSString *tempPath;
    NSString *device;
    NSString *volume;
    NSString *attachOutput;
    NSMutableArray *args;
    BOOL ok;

    device = nil;
    tempPath = [self temporaryDMGPathForOutputPath:output];
    ok = NO;

    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:output error:nil];

    args = [NSMutableArray arrayWithObjects:@"create", @"-quiet",
	@"-srcFolder", source, @"-format", @"UDRW", @"-fs", @"HFS+",
	@"-ov", tempPath, nil];
    if ([commandRunner runCommand:@"hdiutil" arguments:args standardInput:nil
	standardOutput:NULL] != 0)
	goto finish;

    attachOutput = nil;
    args = [NSMutableArray arrayWithObjects:@"attach", @"-noverify", tempPath, nil];
    if ([commandRunner runCommand:@"hdiutil" arguments:args standardInput:nil
	standardOutput:&attachOutput] != 0)
	goto finish;

    device = [self deviceFromHdiutilAttachOutput:attachOutput];
    volume = [self volumeFromHdiutilAttachOutput:attachOutput];
    if (device == nil || volume == nil)
	goto finish;

    if (![self removeExcludedFiles:excludedFiles fromVolume:volume
	commandRunner:commandRunner])
	goto finish;

    args = [NSMutableArray arrayWithObjects:@"detach", @"-quiet", device, nil];
    if ([commandRunner runCommand:@"hdiutil" arguments:args standardInput:nil
	standardOutput:NULL] != 0)
	goto finish;
    device = nil;

    args = [NSMutableArray arrayWithObjects:@"convert", @"-quiet",
	@"-format", @"UDZO", @"-o", output, @"-ov", tempPath, nil];
    if ([password length] > 0) {
	[args addObject:@"-encryption"];
	[args addObject:@"-stdinpass"];
    }
    if ([commandRunner runCommand:@"hdiutil" arguments:args
	standardInput:([password length] > 0 ? password : nil)
	standardOutput:NULL] != 0)
	goto finish;

    if (internetEnabled) {
	args = [NSMutableArray arrayWithObjects:@"internet-enable", @"-quiet",
	    @"-yes", output, nil];
	if ([password length] > 0) {
	    [args addObject:@"-encryption"];
	    [args addObject:@"-stdinpass"];
	}
	if ([commandRunner runCommand:@"hdiutil" arguments:args
	    standardInput:([password length] > 0 ? password : nil)
	    standardOutput:NULL] != 0)
	    goto finish;
    }

    ok = YES;

finish:
    if (device != nil)
	[commandRunner runCommand:@"hdiutil"
	    arguments:[NSArray arrayWithObjects:@"detach", @"-quiet", device, nil]
	    standardInput:nil
	    standardOutput:NULL];
    if (tempPath != nil)
	[[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
    if (!ok)
	[[NSFileManager defaultManager] removeItemAtPath:output error:nil];

    return ok;
}

@end
