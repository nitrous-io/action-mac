#import <MacRuby/MacRuby.h>

// if Ruby Proc, use performRubySelector, if obj-c block, just invoke it.
// caveat: args are NULL/nil terminated.
#define AIOCallBlock(blk, ...) ([NSStringFromClass([(blk) class]) isEqual:@"Proc"] ? [(id)(blk) performRubySelector:@selector(call:) withArguments:__VA_ARGS__, nil] : (blk)(__VA_ARGS__))

// makes a new block variable with __block storage type with a given block
#define AIO__block(blk, __blockBlk) __block typeof(blk) __blockBlk = blk