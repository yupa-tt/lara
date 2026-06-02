//
//  StatusSetter17.h
//  lara
//
//  Based on StatusSetter16_1 from Cowabunga (MIT License)
//  Adapted for iOS 17+ (lara targets iOS 17.0 - 18.7.1, iOS 26.0.x)
//
//  NOTE: StatusBarOverrideData struct may differ across iOS versions.
//        Verify sizeof(StatusBarOverrideData) matches SpringBoard's symbol on each target version.
//

#pragma once
#import "StatusSetter.h"

@interface StatusSetter17 : NSObject <StatusSetter>
@end
