//
// CAArchiveQueue.h
//      FIFO queue for archive jobs
//

#import <Foundation/Foundation.h>

@class CAArchiveJob;

@interface CAArchiveQueue : NSObject
{
    NSMutableArray *_jobs;
}

- (void)enqueueJob:(CAArchiveJob *)job;
- (CAArchiveJob *)dequeueJob;
- (NSUInteger)count;
- (void)removeAllJobs;

@end
