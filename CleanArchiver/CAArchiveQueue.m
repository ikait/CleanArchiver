//
// CAArchiveQueue.m
//      FIFO queue for archive jobs
//

#import "CAArchiveQueue.h"
#import "CAArchiveJob.h"

@implementation CAArchiveQueue

- (id)init
{
    if (self = [super init])
	_jobs = [[NSMutableArray alloc] init];
    return self;
}

- (void)enqueueJob:(CAArchiveJob *)job
{
    if (job != nil)
	[_jobs addObject:job];
}

- (CAArchiveJob *)dequeueJob
{
    CAArchiveJob *job;

    if ([_jobs count] == 0)
	return nil;

    job = [_jobs objectAtIndex:0];
    [_jobs removeObjectAtIndex:0];
    return job;
}

- (NSUInteger)count
{
    return [_jobs count];
}

- (void)removeAllJobs
{
    [_jobs removeAllObjects];
}

@end
