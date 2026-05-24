//
// CAArchivePreferences.h
//      typed wrapper around CleanArchiver defaults
//

#import <Foundation/Foundation.h>

extern NSString *AOArchiveIndividually;
extern NSString *AOArchiveType;
extern NSString *AOCompressionLevel;
extern NSString *AOEncoding;
extern NSString *AODiscardRsrc;
extern NSString *AOExcludeDSS;
extern NSString *AOInternetEnabledDMG;
extern NSString *AOPassword;
extern NSString *AOReplaceAutomatically;

@interface CAArchivePreferences : NSObject
{
    NSUserDefaults *_userDefaults;
    NSString *_archiveTypeTitle;
    int _compressionLevel;
    NSString *_encoding;
    BOOL _discardResourceForks;
    BOOL _excludeDSStore;
    BOOL _replaceAutomatically;
    BOOL _archiveIndividually;
    BOOL _internetEnabledDMG;
}

+ (void)registerDefaultsInUserDefaults:(NSUserDefaults *)userDefaults;
- (id)initWithUserDefaults:(NSUserDefaults *)userDefaults;
- (void)save;

- (NSString *)archiveTypeTitle;
- (void)setArchiveTypeTitle:(NSString *)archiveTypeTitle;
- (int)compressionLevel;
- (void)setCompressionLevel:(int)compressionLevel;
- (NSString *)encoding;
- (void)setEncoding:(NSString *)encoding;
- (BOOL)discardResourceForks;
- (void)setDiscardResourceForks:(BOOL)value;
- (BOOL)excludeDSStore;
- (void)setExcludeDSStore:(BOOL)value;
- (BOOL)replaceAutomatically;
- (void)setReplaceAutomatically:(BOOL)value;
- (BOOL)archiveIndividually;
- (void)setArchiveIndividually:(BOOL)value;
- (BOOL)internetEnabledDMG;
- (void)setInternetEnabledDMG:(BOOL)value;

@end
