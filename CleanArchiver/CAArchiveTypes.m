//
// CAArchiveTypes.m
//      archive type identifiers shared by UI and archive models
//

#import "CAArchiveTypes.h"

NSString *const CAArchiveTypeIdentifierDMG = @"Disk Image";
NSString *const CAArchiveTypeIdentifierBZIP2 = @"bzip2";
NSString *const CAArchiveTypeIdentifierGZIP = @"gzip";
NSString *const CAArchiveTypeIdentifierZIP = @"zip";

NSString *
CAArchiveTypeIdentifierForMenuIndex(enum archiveTypeMenuIndex type)
{
    switch (type) {
    case DMGT:
	return CAArchiveTypeIdentifierDMG;
    case BZIP2T:
	return CAArchiveTypeIdentifierBZIP2;
    case GZIPT:
	return CAArchiveTypeIdentifierGZIP;
    case ZIPT:
	return CAArchiveTypeIdentifierZIP;
    }

    return CAArchiveTypeIdentifierGZIP;
}

enum archiveTypeMenuIndex
CAArchiveTypeMenuIndexForIdentifier(NSString *identifier)
{
    if ([identifier isEqualToString:CAArchiveTypeIdentifierDMG])
	return DMGT;
    if ([identifier isEqualToString:CAArchiveTypeIdentifierBZIP2])
	return BZIP2T;
    if ([identifier isEqualToString:CAArchiveTypeIdentifierZIP])
	return ZIPT;

    return GZIPT;
}
