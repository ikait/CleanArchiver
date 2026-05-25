//
// CAArchiveCommandBuilder.m
//      builds command arguments for non-DMG archive formats
//

#import "CAArchiveCommandBuilder.h"

static void
CAAddUniqueObject(NSMutableArray *array, id object)
{
    if (object != nil && ![array containsObject:object])
	[array addObject:object];
}

@implementation CAArchiveCommandSpec

+ (id)specWithCommand:(NSString *)command
	    arguments:(NSArray *)arguments
	  environment:(NSDictionary *)environment
{
    CAArchiveCommandSpec *spec;

    spec = [[self alloc] init];
    spec->_command = [command copy];
    spec->_arguments = [arguments copy];
    spec->_environment = [environment copy];
    return spec;
}

- (NSString *)command { return _command; }
- (NSArray *)arguments { return _arguments; }
- (NSDictionary *)environment { return _environment; }

@end

@implementation CAArchiveCommandBuilder

+ (NSArray *)excludedFilePatternsWithExplicitExcludedFiles:(NSArray *)excludedFiles
					    excludeDSStore:(BOOL)excludeDSStore
					   excludeMacFiles:(BOOL)excludeMacFiles
				  discardResourceForks:(BOOL *)discardResourceForks
{
    NSMutableArray *patterns;
    NSUInteger i;

    patterns = [NSMutableArray array];
    for (i = 0; i < [excludedFiles count]; i++)
	CAAddUniqueObject(patterns, [excludedFiles objectAtIndex:i]);

    if (excludeDSStore)
	CAAddUniqueObject(patterns, @".DS_Store");

    if (excludeMacFiles) {
	*discardResourceForks = YES;
	CAAddUniqueObject(patterns, @"._*");
	CAAddUniqueObject(patterns, @".DS_Store");
	CAAddUniqueObject(patterns, @"icon\r");
    }

    if ([patterns containsObject:@"._*"])
	*discardResourceForks = YES;

    if (*discardResourceForks)
	CAAddUniqueObject(patterns, @"._*");

    return patterns;
}

+ (NSDictionary *)compressionEnvironmentForCommand:(NSString *)compress
				 compressionLevel:(int)compressionLevel
			 discardResourceForks:(BOOL)discardResourceForks
{
    NSMutableDictionary *environment;

    environment = [NSMutableDictionary dictionary];
    if (compressionLevel != -1) {
	if ([compress isEqualToString:@"bzip2"])
	    [environment setObject:[NSString stringWithFormat:@"-%d",
		compressionLevel] forKey:@"BZIP2"];
	else if ([compress isEqualToString:@"gzip"])
	    [environment setObject:[NSString stringWithFormat:@"-%d",
		compressionLevel] forKey:@"GZIP"];
    }

    if (discardResourceForks) {
	[environment setObject:@"1" forKey:@"COPYFILE_DISABLE"];
	[environment setObject:@"1" forKey:@"COPY_EXTENDED_ATTRIBUTES_DISABLE"];
    }

    return environment;
}

+ (CAArchiveCommandSpec *)compressionCommandSpecWithCommand:(NSString *)compress
					    sourceArguments:(NSArray *)sourceArguments
				   firstSourceIsDirectory:(BOOL)firstSourceIsDirectory
					  compressionLevel:(int)compressionLevel
				       discardResourceForks:(BOOL)discardResourceForks
					    excludeDSStore:(BOOL)excludeDSStore
					   excludeMacFiles:(BOOL)excludeMacFiles
				      explicitExcludedFiles:(NSArray *)excludedFiles
{
    NSMutableArray *args;
    NSDictionary *environment;
    NSArray *excludedPatterns;
    BOOL discardResources;
    BOOL useTar;
    NSUInteger i;

    discardResources = discardResourceForks;
    excludedPatterns = [self excludedFilePatternsWithExplicitExcludedFiles:
	excludedFiles excludeDSStore:excludeDSStore excludeMacFiles:excludeMacFiles
	discardResourceForks:&discardResources];
    environment = [self compressionEnvironmentForCommand:compress
	compressionLevel:compressionLevel
	discardResourceForks:discardResources];
    useTar = [sourceArguments count] > 1 || firstSourceIsDirectory ||
	!discardResources;

    if (useTar) {
	args = [NSMutableArray arrayWithObjects:@"-cf", @"-",
	    @"--use-compress-program", compress, nil];
	for (i = 0; i < [excludedPatterns count]; i++) {
	    [args addObject:@"--exclude"];
	    [args addObject:[excludedPatterns objectAtIndex:i]];
	}
	[args addObjectsFromArray:sourceArguments];
	return [CAArchiveCommandSpec specWithCommand:@"tar"
	    arguments:args environment:environment];
    }

    args = [NSMutableArray arrayWithObjects:@"-c",
	[sourceArguments objectAtIndex:0], nil];
    return [CAArchiveCommandSpec specWithCommand:compress
	arguments:args environment:environment];
}

+ (CAArchiveCommandSpec *)zipCommandSpecWithSourceArguments:(NSArray *)sourceArguments
					      firstSourceIsDirectory:(BOOL)firstSourceIsDirectory
						    outputArgument:(NSString *)outputArgument
							  encoding:(NSString *)encoding
						  compressionLevel:(int)compressionLevel
							  password:(NSString *)password
					       discardResourceForks:(BOOL)discardResourceForks
						    excludeDSStore:(BOOL)excludeDSStore
						   excludeMacFiles:(BOOL)excludeMacFiles
					      explicitExcludedFiles:(NSArray *)excludedFiles
{
    NSMutableArray *args;
    NSArray *excludedPatterns;
    BOOL discardResources;
    NSUInteger i;

    discardResources = discardResourceForks;
    excludedPatterns = [self excludedFilePatternsWithExplicitExcludedFiles:
	excludedFiles excludeDSStore:excludeDSStore excludeMacFiles:excludeMacFiles
	discardResourceForks:&discardResources];

    args = [NSMutableArray arrayWithObject:@"-q"];
    if ([sourceArguments count] > 1 || firstSourceIsDirectory)
	[args addObject:@"-r"];
    if ([encoding length] > 0) {
	[args addObject:@"-CF"];
	[args addObject:@"UTF-8-MAC"];
	[args addObject:@"-CT"];
	[args addObject:encoding];
    }
    if (compressionLevel != -1)
	[args addObject:[NSString stringWithFormat:@"-%d", compressionLevel]];
    if ([password length] > 0) {
	[args addObject:@"-P"];
	[args addObject:password];
    }
    if (discardResources)
	[args addObject:@"-df"];

    [args addObject:outputArgument];
    [args addObjectsFromArray:sourceArguments];

    for (i = 0; i < [excludedPatterns count]; i++) {
	[args addObject:@"-x"];
	[args addObject:[NSString stringWithFormat:@"*/%@",
	    [excludedPatterns objectAtIndex:i]]];
    }

    return [CAArchiveCommandSpec specWithCommand:@"zip"
	arguments:args environment:nil];
}

@end
