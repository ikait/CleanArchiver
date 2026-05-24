//
// CADMGArchiver.h
//      creates compressed disk images for CleanArchiver
//

#import <Foundation/Foundation.h>

@protocol CACommandRunning

- (int)runCommand:(NSString *)command
	arguments:(NSArray *)arguments
    standardInput:(NSString *)standardInput
   standardOutput:(NSString **)standardOutput;

@end

@interface CADMGArchiver : NSObject

+ (BOOL)createDMGFromSource:(NSString *)source
		     output:(NSString *)output
		   password:(NSString *)password
	    internetEnabled:(BOOL)internetEnabled
	      excludedFiles:(NSArray *)excludedFiles
	      commandRunner:(id<CACommandRunning>)commandRunner;

@end
