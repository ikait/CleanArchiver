//
// CAArchiveCommandBuilder.h
//      builds command arguments for non-DMG archive formats
//

#import <Foundation/Foundation.h>

@interface CAArchiveCommandSpec : NSObject
{
    NSString *_command;
    NSArray *_arguments;
    NSDictionary *_environment;
}

+ (id)specWithCommand:(NSString *)command
	    arguments:(NSArray *)arguments
	  environment:(NSDictionary *)environment;
- (NSString *)command;
- (NSArray *)arguments;
- (NSDictionary *)environment;

@end

@interface CAArchiveCommandBuilder : NSObject

+ (NSArray *)excludedFilePatternsWithExplicitExcludedFiles:(NSArray *)excludedFiles
					    excludeDSStore:(BOOL)excludeDSStore
					   excludeMacFiles:(BOOL)excludeMacFiles
				  discardResourceForks:(BOOL *)discardResourceForks;

+ (CAArchiveCommandSpec *)compressionCommandSpecWithCommand:(NSString *)compress
					    sourceArguments:(NSArray *)sourceArguments
				   firstSourceIsDirectory:(BOOL)firstSourceIsDirectory
					  compressionLevel:(int)compressionLevel
				       discardResourceForks:(BOOL)discardResourceForks
					    excludeDSStore:(BOOL)excludeDSStore
					   excludeMacFiles:(BOOL)excludeMacFiles
				      explicitExcludedFiles:(NSArray *)excludedFiles;

+ (CAArchiveCommandSpec *)zipCommandSpecWithSourceArguments:(NSArray *)sourceArguments
					      firstSourceIsDirectory:(BOOL)firstSourceIsDirectory
						    outputArgument:(NSString *)outputArgument
							  encoding:(NSString *)encoding
						  compressionLevel:(int)compressionLevel
							  password:(NSString *)password
					       discardResourceForks:(BOOL)discardResourceForks
						    excludeDSStore:(BOOL)excludeDSStore
						   excludeMacFiles:(BOOL)excludeMacFiles
					      explicitExcludedFiles:(NSArray *)excludedFiles;

@end
