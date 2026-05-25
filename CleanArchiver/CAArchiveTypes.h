//
// CAArchiveTypes.h
//      archive type identifiers shared by UI and archive models
//

#import <Foundation/Foundation.h>

enum archiveTypeMenuIndex {
    DMGT = 0,
    BZIP2T,
    GZIPT,
    ZIPT,
};

enum compressionLevelMenuIndex {
    FAST = 0,
    NORMAL,
    BEST,
};

extern NSString *const CAArchiveTypeIdentifierDMG;
extern NSString *const CAArchiveTypeIdentifierBZIP2;
extern NSString *const CAArchiveTypeIdentifierGZIP;
extern NSString *const CAArchiveTypeIdentifierZIP;

NSString *CAArchiveTypeIdentifierForMenuIndex(enum archiveTypeMenuIndex type);
enum archiveTypeMenuIndex CAArchiveTypeMenuIndexForIdentifier(NSString *identifier);
