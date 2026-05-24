//
// CAArchivePreferences.m
//      typed wrapper around CleanArchiver defaults
//

#import "CAArchivePreferences.h"

NSString *AOArchiveIndividually	= @"Archive Individually";
NSString *AOArchiveType		= @"Archive Type";
NSString *AOCompressionLevel	= @"Compression Level";
NSString *AOEncoding		= @"Encoding";
NSString *AODiscardRsrc		= @"Discard Resource Forks";
NSString *AOExcludeDSS		= @"Exclude .DS_Store";
NSString *AOInternetEnabledDMG	= @"Internet-Enabled Disk Image";
NSString *AOPassword		= @"Password";
NSString *AOReplaceAutomatically= @"Replace Automatically";

@implementation CAArchivePreferences

+ (void)registerDefaultsInUserDefaults:(NSUserDefaults *)userDefaults
{
    NSMutableDictionary *defaults;

    defaults = [NSMutableDictionary dictionary];
    [defaults setObject:@"gzip" forKey:AOArchiveType];
    [defaults setObject:[NSNumber numberWithInt:-1] forKey:AOCompressionLevel];
    [defaults setObject:@"" forKey:AOEncoding];
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:AODiscardRsrc];
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:AOExcludeDSS];
    [defaults setObject:[NSNumber numberWithBool:NO]
	forKey:AOReplaceAutomatically];
    [defaults setObject:[NSNumber numberWithBool:NO]
	forKey:AOArchiveIndividually];
    [defaults setObject:[NSNumber numberWithBool:NO]
	forKey:AOInternetEnabledDMG];

    [userDefaults registerDefaults:defaults];
}

- (id)initWithUserDefaults:(NSUserDefaults *)userDefaults
{
    if (self = [super init]) {
	_userDefaults = userDefaults;
	_archiveTypeTitle = [[_userDefaults objectForKey:AOArchiveType] copy];
	_compressionLevel = (int)[_userDefaults integerForKey:AOCompressionLevel];
	_encoding = [[_userDefaults objectForKey:AOEncoding] copy];
	_discardResourceForks = [_userDefaults boolForKey:AODiscardRsrc];
	_excludeDSStore = [_userDefaults boolForKey:AOExcludeDSS];
	_replaceAutomatically = [_userDefaults boolForKey:AOReplaceAutomatically];
	_archiveIndividually = [_userDefaults boolForKey:AOArchiveIndividually];
	_internetEnabledDMG = [_userDefaults boolForKey:AOInternetEnabledDMG];
    }
    return self;
}

- (void)save
{
    [_userDefaults setObject:_archiveTypeTitle forKey:AOArchiveType];
    [_userDefaults setInteger:_compressionLevel forKey:AOCompressionLevel];
    [_userDefaults setObject:_encoding forKey:AOEncoding];
    [_userDefaults setBool:_discardResourceForks forKey:AODiscardRsrc];
    [_userDefaults setBool:_excludeDSStore forKey:AOExcludeDSS];
    [_userDefaults setBool:_replaceAutomatically forKey:AOReplaceAutomatically];
    [_userDefaults setBool:_archiveIndividually forKey:AOArchiveIndividually];
    [_userDefaults setBool:_internetEnabledDMG forKey:AOInternetEnabledDMG];
}

- (NSString *)archiveTypeTitle { return _archiveTypeTitle; }
- (void)setArchiveTypeTitle:(NSString *)archiveTypeTitle { _archiveTypeTitle = [archiveTypeTitle copy]; }
- (int)compressionLevel { return _compressionLevel; }
- (void)setCompressionLevel:(int)compressionLevel { _compressionLevel = compressionLevel; }
- (NSString *)encoding { return _encoding; }
- (void)setEncoding:(NSString *)encoding { _encoding = [encoding copy]; }
- (BOOL)discardResourceForks { return _discardResourceForks; }
- (void)setDiscardResourceForks:(BOOL)value { _discardResourceForks = value; }
- (BOOL)excludeDSStore { return _excludeDSStore; }
- (void)setExcludeDSStore:(BOOL)value { _excludeDSStore = value; }
- (BOOL)replaceAutomatically { return _replaceAutomatically; }
- (void)setReplaceAutomatically:(BOOL)value { _replaceAutomatically = value; }
- (BOOL)archiveIndividually { return _archiveIndividually; }
- (void)setArchiveIndividually:(BOOL)value { _archiveIndividually = value; }
- (BOOL)internetEnabledDMG { return _internetEnabledDMG; }
- (void)setInternetEnabledDMG:(BOOL)value { _internetEnabledDMG = value; }

@end
