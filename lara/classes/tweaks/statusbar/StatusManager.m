//
//  StatusManager.m
//  lara
//
//  Ported from Cowabunga (MIT License)
//  Changes:
//    - isMDCMode / setIsMDCMode を削除
//    - iOS 14/15/16 用 StatusSetter を削除（lara は iOS 17 以降のみ対象）
//    - StatusSetter17 のみを使用
//

#import <UIKit/UIKit.h>
#import "StatusManager.h"
#import "StatusSetter.h"
#import "StatusSetter17.h"

@interface StatusManager ()
@property (nonatomic, strong) id<StatusSetter> setter;
@end

@implementation StatusManager

- (instancetype)init {
    self = [super init];
    return self;
}

- (id<StatusSetter>)setter {
    if (!_setter) {
        _setter = [StatusSetter17 new];
    }
    return _setter;
}

+ (StatusManager *)sharedInstance {
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{ sharedObject = [[self alloc] init]; });
    return sharedObject;
}

- (bool)isCarrierOverridden           { return [self.setter isCarrierOverridden]; }
- (NSString *)getCarrierOverride      { return [self.setter getCarrierOverride]; }
- (void)setCarrier:(NSString *)text   { [self.setter setCarrier:text]; }
- (void)unsetCarrier                  { [self.setter unsetCarrier]; }

- (bool)isSecondaryCarrierOverridden            { return [self.setter isSecondaryCarrierOverridden]; }
- (NSString *)getSecondaryCarrierOverride       { return [self.setter getSecondaryCarrierOverride]; }
- (void)setSecondaryCarrier:(NSString *)text    { [self.setter setSecondaryCarrier:text]; }
- (void)unsetSecondaryCarrier                   { [self.setter unsetSecondaryCarrier]; }

- (bool)isPrimaryServiceBadgeOverridden           { return [self.setter isPrimaryServiceBadgeOverridden]; }
- (NSString *)getPrimaryServiceBadgeOverride      { return [self.setter getPrimaryServiceBadgeOverride]; }
- (void)setPrimaryServiceBadge:(NSString *)text   { [self.setter setPrimaryServiceBadge:text]; }
- (void)unsetPrimaryServiceBadge                  { [self.setter unsetPrimaryServiceBadge]; }

- (bool)isSecondaryServiceBadgeOverridden           { return [self.setter isSecondaryServiceBadgeOverridden]; }
- (NSString *)getSecondaryServiceBadgeOverride      { return [self.setter getSecondaryServiceBadgeOverride]; }
- (void)setSecondaryServiceBadge:(NSString *)text   { [self.setter setSecondaryServiceBadge:text]; }
- (void)unsetSecondaryServiceBadge                  { [self.setter unsetSecondaryServiceBadge]; }

- (bool)isDateOverridden        { return [self.setter isDateOverridden]; }
- (NSString *)getDateOverride   { return [self.setter getDateOverride]; }
- (void)setDate:(NSString *)text{ [self.setter setDate:text]; }
- (void)unsetDate               { [self.setter unsetDate]; }

- (bool)isTimeOverridden        { return [self.setter isTimeOverridden]; }
- (NSString *)getTimeOverride   { return [self.setter getTimeOverride]; }
- (void)setTime:(NSString *)text{ [self.setter setTime:text]; }
- (void)unsetTime               { [self.setter unsetTime]; }

- (bool)isBatteryDetailOverridden           { return [self.setter isBatteryDetailOverridden]; }
- (NSString *)getBatteryDetailOverride      { return [self.setter getBatteryDetailOverride]; }
- (void)setBatteryDetail:(NSString *)text   { [self.setter setBatteryDetail:text]; }
- (void)unsetBatteryDetail                  { [self.setter unsetBatteryDetail]; }

- (bool)isCrumbOverridden           { return [self.setter isCrumbOverridden]; }
- (NSString *)getCrumbOverride      { return [self.setter getCrumbOverride]; }
- (void)setCrumb:(NSString *)text   { [self.setter setCrumb:text]; }
- (void)unsetCrumb                  { [self.setter unsetCrumb]; }

- (bool)isCellularServiceOverridden     { return [self.setter isCellularServiceOverridden]; }
- (bool)getCellularServiceOverride      { return [self.setter getCellularServiceOverride]; }
- (void)setCellularService:(bool)val    { [self.setter setCellularService:val]; }
- (void)unsetCellularService            { [self.setter unsetCellularService]; }

- (bool)isSecondaryCellularServiceOverridden    { return [self.setter isSecondaryCellularServiceOverridden]; }
- (bool)getSecondaryCellularServiceOverride     { return [self.setter getSecondaryCellularServiceOverride]; }
- (void)setSecondaryCellularService:(bool)val   { [self.setter setSecondaryCellularService:val]; }
- (void)unsetSecondaryCellularService           { [self.setter unsetSecondaryCellularService]; }

- (bool)isDataNetworkTypeOverridden         { return [self.setter isDataNetworkTypeOverridden]; }
- (int)getDataNetworkTypeOverride           { return [self.setter getDataNetworkTypeOverride]; }
- (void)setDataNetworkType:(int)identifier  { [self.setter setDataNetworkType:identifier]; }
- (void)unsetDataNetworkType                { [self.setter unsetDataNetworkType]; }

- (bool)isSecondaryDataNetworkTypeOverridden        { return [self.setter isSecondaryDataNetworkTypeOverridden]; }
- (int)getSecondaryDataNetworkTypeOverride          { return [self.setter getSecondaryDataNetworkTypeOverride]; }
- (void)setSecondaryDataNetworkType:(int)identifier { [self.setter setSecondaryDataNetworkType:identifier]; }
- (void)unsetSecondaryDataNetworkType               { [self.setter unsetSecondaryDataNetworkType]; }

- (bool)isBatteryCapacityOverridden     { return [self.setter isBatteryCapacityOverridden]; }
- (int)getBatteryCapacityOverride       { return [self.setter getBatteryCapacityOverride]; }
- (void)setBatteryCapacity:(int)cap     { [self.setter setBatteryCapacity:cap]; }
- (void)unsetBatteryCapacity            { [self.setter unsetBatteryCapacity]; }

- (bool)isWiFiSignalStrengthBarsOverridden      { return [self.setter isWiFiSignalStrengthBarsOverridden]; }
- (int)getWiFiSignalStrengthBarsOverride        { return [self.setter getWiFiSignalStrengthBarsOverride]; }
- (void)setWiFiSignalStrengthBars:(int)s        { [self.setter setWiFiSignalStrengthBars:s]; }
- (void)unsetWiFiSignalStrengthBars             { [self.setter unsetWiFiSignalStrengthBars]; }

- (bool)isGsmSignalStrengthBarsOverridden   { return [self.setter isGsmSignalStrengthBarsOverridden]; }
- (int)getGsmSignalStrengthBarsOverride     { return [self.setter getGsmSignalStrengthBarsOverride]; }
- (void)setGsmSignalStrengthBars:(int)s     { [self.setter setGsmSignalStrengthBars:s]; }
- (void)unsetGsmSignalStrengthBars          { [self.setter unsetGsmSignalStrengthBars]; }

- (bool)isSecondaryGsmSignalStrengthBarsOverridden  { return [self.setter isSecondaryGsmSignalStrengthBarsOverridden]; }
- (int)getSecondaryGsmSignalStrengthBarsOverride    { return [self.setter getSecondaryGsmSignalStrengthBarsOverride]; }
- (void)setSecondaryGsmSignalStrengthBars:(int)s    { [self.setter setSecondaryGsmSignalStrengthBars:s]; }
- (void)unsetSecondaryGsmSignalStrengthBars         { [self.setter unsetSecondaryGsmSignalStrengthBars]; }

- (bool)isDisplayingRawWiFiSignal           { return [self.setter isDisplayingRawWiFiSignal]; }
- (void)displayRawWifiSignal:(bool)d        { [self.setter displayRawWifiSignal:d]; }
- (bool)isDisplayingRawGSMSignal            { return [self.setter isDisplayingRawGSMSignal]; }
- (void)displayRawGSMSignal:(bool)d         { [self.setter displayRawGSMSignal:d]; }

- (bool)isClockHidden           { return [self.setter isClockHidden]; }
- (void)hideClock:(bool)h       { [self.setter hideClock:h]; }
- (bool)isDNDHidden             { return [self.setter isDNDHidden]; }
- (void)hideDND:(bool)h         { [self.setter hideDND:h]; }
- (bool)isAirplaneHidden        { return [self.setter isAirplaneHidden]; }
- (void)hideAirplane:(bool)h    { [self.setter hideAirplane:h]; }
- (bool)isCellHidden            { return [self.setter isCellHidden]; }
- (void)hideCell:(bool)h        { [self.setter hideCell:h]; }
- (bool)isWiFiHidden            { return [self.setter isWiFiHidden]; }
- (void)hideWiFi:(bool)h        { [self.setter hideWiFi:h]; }
- (bool)isBatteryHidden         { return [self.setter isBatteryHidden]; }
- (void)hideBattery:(bool)h     { [self.setter hideBattery:h]; }
- (bool)isBluetoothHidden       { return [self.setter isBluetoothHidden]; }
- (void)hideBluetooth:(bool)h   { [self.setter hideBluetooth:h]; }
- (bool)isAlarmHidden           { return [self.setter isAlarmHidden]; }
- (void)hideAlarm:(bool)h       { [self.setter hideAlarm:h]; }
- (bool)isLocationHidden        { return [self.setter isLocationHidden]; }
- (void)hideLocation:(bool)h    { [self.setter hideLocation:h]; }
- (bool)isRotationHidden        { return [self.setter isRotationHidden]; }
- (void)hideRotation:(bool)h    { [self.setter hideRotation:h]; }
- (bool)isAirPlayHidden         { return [self.setter isAirPlayHidden]; }
- (void)hideAirPlay:(bool)h     { [self.setter hideAirPlay:h]; }
- (bool)isCarPlayHidden         { return [self.setter isCarPlayHidden]; }
- (void)hideCarPlay:(bool)h     { [self.setter hideCarPlay:h]; }
- (bool)isVPNHidden             { return [self.setter isVPNHidden]; }
- (void)hideVPN:(bool)h         { [self.setter hideVPN:h]; }
- (bool)isMicrophoneUseHidden   { return [self.setter isMicrophoneUseHidden]; }
- (void)hideMicrophoneUse:(bool)h { [self.setter hideMicrophoneUse:h]; }
- (bool)isCameraUseHidden       { return [self.setter isCameraUseHidden]; }
- (void)hideCameraUse:(bool)h   { [self.setter hideCameraUse:h]; }

@end
