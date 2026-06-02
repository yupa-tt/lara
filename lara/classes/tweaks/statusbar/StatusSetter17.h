//
//  StatusSetter17.h
//  lara
//
#pragma once
#import "StatusSetter.h"

@interface StatusSetter17 : NSObject <StatusSetter>

// Swift から呼びやすいようにブロックで受け取る
+ (void)setWriteBlock:(BOOL (^)(const void *data, NSUInteger len))writeBlock
           readBlock:(BOOL (^)(void *buf, NSUInteger len))readBlock
         existsBlock:(BOOL (^)(void))existsBlock;

@end
