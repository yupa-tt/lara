//
//  StatusSetter17.h
//  lara
//
//  Based on StatusSetter16_1 from Cowabunga (MIT License)
//  Adapted for lara: 書き込み/読み込みを関数ポインタで外部から注入する
//

#pragma once
#import "StatusSetter.h"

// StatusSetter17 が使う書き込み/読み込み関数の型
typedef BOOL  (*StatusBarWriteFunc)(const void *data, size_t len);
typedef BOOL  (*StatusBarReadFunc)(void *buf, size_t len);
typedef BOOL  (*StatusBarExistsFunc)(void);

@interface StatusSetter17 : NSObject <StatusSetter>

// lara の Swift 側から初期化時に注入する
+ (void)setWriteFunc:(StatusBarWriteFunc)writeFunc
           readFunc:(StatusBarReadFunc)readFunc
         existsFunc:(StatusBarExistsFunc)existsFunc;

@end
