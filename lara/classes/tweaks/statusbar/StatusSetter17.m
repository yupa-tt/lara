//
//  StatusSetter17.m
//  lara
//
//  Based on StatusSetter16_1 from Cowabunga (MIT License)
//  Adapted for iOS 17+:
//    - isMDCMode チェックを全削除
//    - statusBarOverridesEditing ファイル書き込みパスを全削除
//    - 常に UIStatusBarServer を直接呼び出す
//      (lara はサンドボックス脱出済みなので SpringBoard への XPC 通信が可能)
//

#import "StatusSetter17.h"

// MARK: - StatusBarItem enum

typedef NS_ENUM(int, StatusBarItem) {
    TimeStatusBarItem                           = 0,
    DateStatusBarItem                           = 1,
    QuietModeStatusBarItem                      = 2,
    AirplaneModeStatusBarItem                   = 3,
    CellularSignalStrengthStatusBarItem         = 4,
    SecondaryCellularSignalStrengthStatusBarItem = 5,
    CellularServiceStatusBarItem                = 6,
    SecondaryCellularServiceStatusBarItem       = 7,
    // 8
    CellularDataNetworkStatusBarItem            = 9,
    SecondaryCellularDataNetworkStatusBarItem   = 10,
    // 11
    MainBatteryStatusBarItem                    = 12,
    ProminentlyShowBatteryDetailStatusBarItem   = 13,
    // 14, 15
    BluetoothStatusBarItem                      = 16,
    TTYStatusBarItem                            = 17,
    AlarmStatusBarItem                          = 18,
    // 19, 20
    LocationStatusBarItem                       = 21,
    RotationLockStatusBarItem                   = 22,
    CameraUseStatusBarItem                      = 23,
    AirPlayStatusBarItem                        = 24,
    AssistantStatusBarItem                      = 25,
    CarPlayStatusBarItem                        = 26,
    StudentStatusBarItem                        = 27,
    MicrophoneUseStatusBarItem                  = 28,
    VPNStatusBarItem                            = 29,
    // 30-37
    LiquidDetectionStatusBarItem                = 38,
    VoiceControlStatusBarItem                   = 39,
    // 40-43
    Extra1StatusBarItem                         = 44,
};

typedef NS_ENUM(unsigned int, BatteryState) {
    BatteryStateUnplugged = 0
};

// MARK: - StatusBarRawData struct

typedef struct {
    bool itemIsEnabled[45];
    char padding;
    char timeString[64];
    char shortTimeString[64];
    char dateString[256];
    int gsmSignalStrengthRaw;
    int secondaryGsmSignalStrengthRaw;
    int gsmSignalStrengthBars;
    int secondaryGsmSignalStrengthBars;
    char serviceString[100];
    char secondaryServiceString[100];
    char serviceCrossfadeString[100];
    char secondaryServiceCrossfadeString[100];
    char serviceImages[2][100];
    char operatorDirectory[1024];
    unsigned int serviceContentType;
    unsigned int secondaryServiceContentType;
    unsigned int cellLowDataModeActive:1;
    unsigned int secondaryCellLowDataModeActive:1;
    int wifiSignalStrengthRaw;
    int wifiSignalStrengthBars;
    unsigned int wifiLowDataModeActive:1;
    unsigned int dataNetworkType;
    unsigned int secondaryDataNetworkType;
    int batteryCapacity;
    unsigned int batteryState;
    char batteryDetailString[150];
    int bluetoothBatteryCapacity;
    int thermalColor;
    unsigned int thermalSunlightMode : 1;
    unsigned int slowActivity : 1;
    unsigned int syncActivity : 1;
    char activityDisplayId[256];
    unsigned int bluetoothConnected : 1;
    unsigned int displayRawGSMSignal : 1;
    unsigned int displayRawWifiSignal : 1;
    unsigned int locationIconType : 1;
    unsigned int voiceControlIconType:2;
    unsigned int quietModeInactive : 1;
    unsigned int tetheringConnectionCount;
    unsigned int batterySaverModeActive : 1;
    unsigned int deviceIsRTL : 1;
    unsigned int lock : 1;
    char breadcrumbTitle[256];
    char breadcrumbSecondaryTitle[256];
    char personName[100];
    unsigned int electronicTollCollectionAvailable : 1;
    unsigned int radarAvailable : 1;
    unsigned int wifiLinkWarning : 1;
    unsigned int wifiSearching : 1;
    double backgroundActivityDisplayStartDate;
    unsigned int shouldShowEmergencyOnlyStatus : 1;
    unsigned int secondaryCellularConfigured : 1;
    char primaryServiceBadgeString[100];
    char secondaryServiceBadgeString[100];
    char quietModeImage[256];
    unsigned int extra1 : 1;
} StatusBarRawData;

// MARK: - StatusBarOverrideData struct

typedef struct {
    bool overrideItemIsEnabled[45];
    char padding;
    unsigned int overrideTimeString : 1;
    unsigned int overrideDateString : 1;
    unsigned int overrideGsmSignalStrengthRaw : 1;
    unsigned int overrideSecondaryGsmSignalStrengthRaw : 1;
    unsigned int overrideGsmSignalStrengthBars : 1;
    unsigned int overrideSecondaryGsmSignalStrengthBars : 1;
    unsigned int overrideServiceString : 1;
    unsigned int overrideSecondaryServiceString : 1;
    unsigned int overrideServiceImages : 2;
    unsigned int overrideOperatorDirectory : 1;
    unsigned int overrideServiceContentType : 1;
    unsigned int overrideSecondaryServiceContentType : 1;
    unsigned int overrideWifiSignalStrengthRaw : 1;
    unsigned int overrideWifiSignalStrengthBars : 1;
    unsigned int overrideDataNetworkType : 1;
    unsigned int overrideSecondaryDataNetworkType : 1;
    unsigned int disallowsCellularDataNetworkTypes : 1;
    unsigned int overrideBatteryCapacity : 1;
    unsigned int overrideBatteryState : 1;
    unsigned int overrideBatteryDetailString : 1;
    unsigned int overrideBluetoothBatteryCapacity : 1;
    unsigned int overrideThermalColor : 1;
    unsigned int overrideSlowActivity : 1;
    unsigned int overrideActivityDisplayId : 1;
    unsigned int overrideBluetoothConnected : 1;
    unsigned int overrideBreadcrumb : 1;
    unsigned int overrideLock;
    unsigned int overrideDisplayRawGSMSignal : 1;
    unsigned int overrideDisplayRawWifiSignal : 1;
    unsigned int overridePersonName : 1;
    unsigned int overrideWifiLinkWarning : 1;
    unsigned int overrideSecondaryCellularConfigured : 1;
    unsigned int overridePrimaryServiceBadgeString : 1;
    unsigned int overrideSecondaryServiceBadgeString : 1;
    unsigned int overrideQuietModeImage : 1;
    unsigned int overrideExtra1 : 1;
    StatusBarRawData values;
} StatusBarOverrideData;

// MARK: - UIStatusBarServer private interface

@class UIStatusBarServer;

@protocol UIStatusBarServerClient
- (void)statusBarServer:(UIStatusBarServer *)arg1 didReceiveDoubleHeightStatusString:(NSString *)arg2 forStyle:(long long)arg3;
- (void)statusBarServer:(UIStatusBarServer *)arg1 didReceiveGlowAnimationState:(bool)arg2 forStyle:(long long)arg3;
- (void)statusBarServer:(UIStatusBarServer *)arg1 didReceiveStatusBarData:(const StatusBarRawData *)arg2 withActions:(int)arg3;
- (void)statusBarServer:(UIStatusBarServer *)arg1 didReceiveStyleOverrides:(int)arg2;
@end

@interface UIStatusBarServer : NSObject
@property (nonatomic, strong) id<UIStatusBarServerClient> statusBar;
+ (void)postStatusBarOverrideData:(StatusBarOverrideData *)arg1;
+ (void)permanentizeStatusBarOverrideData;
+ (StatusBarOverrideData *)getStatusBarOverrideData;
@end

// MARK: - StatusSetter17 implementation

@implementation StatusSetter17

// lara はサンドボックス脱出済みのため常に UIStatusBarServer を直接呼び出す。
// Cowabunga の isMDCMode チェックと statusBarOverridesEditing 書き込みパスは不要。
- (void)applyChanges:(StatusBarOverrideData *)overrides {
    [UIStatusBarServer postStatusBarOverrideData:overrides];
    [UIStatusBarServer permanentizeStatusBarOverrideData];
}

- (StatusBarOverrideData *)getOverrides {
    return [UIStatusBarServer getStatusBarOverrideData];
}

// MARK: - Carrier

- (bool)isCarrierOverridden {
    return [self getOverrides]->overrideServiceString == 1;
}
- (NSString *)getCarrierOverride {
    return @([self getOverrides]->values.serviceString);
}
- (void)setCarrier:(NSString *)text {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideServiceString = 1;
    strcpy(o->values.serviceString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    strcpy(o->values.serviceCrossfadeString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    [self applyChanges:o];
}
- (void)unsetCarrier {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideServiceString = 0;
    [self applyChanges:o];
}

- (bool)isSecondaryCarrierOverridden {
    return [self getOverrides]->overrideSecondaryServiceString == 1;
}
- (NSString *)getSecondaryCarrierOverride {
    return @([self getOverrides]->values.secondaryServiceString);
}
- (void)setSecondaryCarrier:(NSString *)text {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideSecondaryServiceString = 1;
    strcpy(o->values.secondaryServiceString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    strcpy(o->values.secondaryServiceCrossfadeString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    [self applyChanges:o];
}
- (void)unsetSecondaryCarrier {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideSecondaryServiceString = 0;
    [self applyChanges:o];
}

// MARK: - Service Badge

- (bool)isPrimaryServiceBadgeOverridden {
    return [self getOverrides]->overridePrimaryServiceBadgeString == 1;
}
- (NSString *)getPrimaryServiceBadgeOverride {
    return @([self getOverrides]->values.primaryServiceBadgeString);
}
- (void)setPrimaryServiceBadge:(NSString *)text {
    StatusBarOverrideData *o = [self getOverrides];
    o->overridePrimaryServiceBadgeString = 1;
    strcpy(o->values.primaryServiceBadgeString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    [self applyChanges:o];
}
- (void)unsetPrimaryServiceBadge {
    StatusBarOverrideData *o = [self getOverrides];
    o->overridePrimaryServiceBadgeString = 0;
    [self applyChanges:o];
}

- (bool)isSecondaryServiceBadgeOverridden {
    return [self getOverrides]->overrideSecondaryServiceBadgeString == 1;
}
- (NSString *)getSecondaryServiceBadgeOverride {
    return @([self getOverrides]->values.secondaryServiceBadgeString);
}
- (void)setSecondaryServiceBadge:(NSString *)text {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideSecondaryServiceBadgeString = 1;
    strcpy(o->values.secondaryServiceBadgeString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    [self applyChanges:o];
}
- (void)unsetSecondaryServiceBadge {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideSecondaryServiceBadgeString = 0;
    [self applyChanges:o];
}

// MARK: - Date / Time

- (bool)isDateOverridden { return [self getOverrides]->overrideDateString == 1; }
- (NSString *)getDateOverride { return @([self getOverrides]->values.dateString); }
- (void)setDate:(NSString *)text {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideDateString = 1;
    strcpy(o->values.dateString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    [self applyChanges:o];
}
- (void)unsetDate {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideDateString = 0;
    [self applyChanges:o];
}

- (bool)isTimeOverridden { return [self getOverrides]->overrideTimeString == 1; }
- (NSString *)getTimeOverride { return @([self getOverrides]->values.timeString); }
- (void)setTime:(NSString *)text {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideTimeString = 1;
    strcpy(o->values.timeString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    strcpy(o->values.shortTimeString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    [self applyChanges:o];
}
- (void)unsetTime {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideTimeString = 0;
    [self applyChanges:o];
}

// MARK: - Battery Detail / Crumb

- (bool)isBatteryDetailOverridden { return [self getOverrides]->overrideBatteryDetailString == 1; }
- (NSString *)getBatteryDetailOverride { return @([self getOverrides]->values.batteryDetailString); }
- (void)setBatteryDetail:(NSString *)text {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideBatteryDetailString = 1;
    strcpy(o->values.batteryDetailString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    [self applyChanges:o];
}
- (void)unsetBatteryDetail {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideBatteryDetailString = 0;
    [self applyChanges:o];
}

- (bool)isCrumbOverridden { return [self getOverrides]->overrideBreadcrumb == 1; }
- (NSString *)getCrumbOverride { return @([self getOverrides]->values.breadcrumbTitle); }
- (void)setCrumb:(NSString *)text {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideBreadcrumb = 1;
    strcpy(o->values.breadcrumbTitle, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    [self applyChanges:o];
}
- (void)unsetCrumb {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideBreadcrumb = 0;
    [self applyChanges:o];
}

// MARK: - Cellular Service

- (bool)isCellularServiceOverridden { return [self getOverrides]->overrideItemIsEnabled[CellularServiceStatusBarItem] == 1; }
- (bool)getCellularServiceOverride { return [self getOverrides]->values.itemIsEnabled[CellularServiceStatusBarItem]; }
- (void)setCellularService:(bool)val {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideItemIsEnabled[CellularServiceStatusBarItem] = 1;
    o->values.itemIsEnabled[CellularServiceStatusBarItem] = val;
    [self applyChanges:o];
}
- (void)unsetCellularService {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideItemIsEnabled[CellularServiceStatusBarItem] = 0;
    [self applyChanges:o];
}

- (bool)isSecondaryCellularServiceOverridden { return [self getOverrides]->overrideItemIsEnabled[SecondaryCellularServiceStatusBarItem] == 1; }
- (bool)getSecondaryCellularServiceOverride { return [self getOverrides]->values.itemIsEnabled[SecondaryCellularServiceStatusBarItem]; }
- (void)setSecondaryCellularService:(bool)val {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideItemIsEnabled[SecondaryCellularServiceStatusBarItem] = 1;
    o->values.itemIsEnabled[SecondaryCellularServiceStatusBarItem] = val;
    [self applyChanges:o];
}
- (void)unsetSecondaryCellularService {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideItemIsEnabled[SecondaryCellularServiceStatusBarItem] = 0;
    [self applyChanges:o];
}

// MARK: - Data Network Type

- (bool)isDataNetworkTypeOverridden { return [self getOverrides]->overrideDataNetworkType == 1; }
- (int)getDataNetworkTypeOverride { return (int)[self getOverrides]->values.dataNetworkType; }
- (void)setDataNetworkType:(int)identifier {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideDataNetworkType = 1;
    o->values.dataNetworkType = identifier;
    [self applyChanges:o];
}
- (void)unsetDataNetworkType {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideDataNetworkType = 0;
    [self applyChanges:o];
}

- (bool)isSecondaryDataNetworkTypeOverridden { return [self getOverrides]->overrideSecondaryDataNetworkType == 1; }
- (int)getSecondaryDataNetworkTypeOverride { return (int)[self getOverrides]->values.secondaryDataNetworkType; }
- (void)setSecondaryDataNetworkType:(int)identifier {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideSecondaryDataNetworkType = 1;
    o->values.secondaryDataNetworkType = identifier;
    [self applyChanges:o];
}
- (void)unsetSecondaryDataNetworkType {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideSecondaryDataNetworkType = 0;
    [self applyChanges:o];
}

// MARK: - Battery Capacity

- (bool)isBatteryCapacityOverridden { return [self getOverrides]->overrideBatteryCapacity == 1; }
- (int)getBatteryCapacityOverride { return [self getOverrides]->values.batteryCapacity; }
- (void)setBatteryCapacity:(int)capacity {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideBatteryCapacity = 1;
    o->values.batteryCapacity = capacity;
    [self applyChanges:o];
}
- (void)unsetBatteryCapacity {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideBatteryCapacity = 0;
    [self applyChanges:o];
}

// MARK: - Signal Strength

- (bool)isWiFiSignalStrengthBarsOverridden { return [self getOverrides]->overrideWifiSignalStrengthBars == 1; }
- (int)getWiFiSignalStrengthBarsOverride { return [self getOverrides]->values.wifiSignalStrengthBars; }
- (void)setWiFiSignalStrengthBars:(int)strength {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideWifiSignalStrengthBars = 1;
    o->values.wifiSignalStrengthBars = strength;
    [self applyChanges:o];
}
- (void)unsetWiFiSignalStrengthBars {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideWifiSignalStrengthBars = 0;
    [self applyChanges:o];
}

- (bool)isGsmSignalStrengthBarsOverridden { return [self getOverrides]->overrideGsmSignalStrengthBars == 1; }
- (int)getGsmSignalStrengthBarsOverride { return [self getOverrides]->values.gsmSignalStrengthBars; }
- (void)setGsmSignalStrengthBars:(int)strength {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideGsmSignalStrengthBars = 1;
    o->values.gsmSignalStrengthBars = strength;
    [self applyChanges:o];
}
- (void)unsetGsmSignalStrengthBars {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideGsmSignalStrengthBars = 0;
    [self applyChanges:o];
}

- (bool)isSecondaryGsmSignalStrengthBarsOverridden { return [self getOverrides]->overrideSecondaryGsmSignalStrengthBars == 1; }
- (int)getSecondaryGsmSignalStrengthBarsOverride { return [self getOverrides]->values.secondaryGsmSignalStrengthBars; }
- (void)setSecondaryGsmSignalStrengthBars:(int)strength {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideSecondaryGsmSignalStrengthBars = 1;
    o->values.secondaryGsmSignalStrengthBars = strength;
    [self applyChanges:o];
}
- (void)unsetSecondaryGsmSignalStrengthBars {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideSecondaryGsmSignalStrengthBars = 0;
    [self applyChanges:o];
}

// MARK: - Raw Signal Display

- (bool)isDisplayingRawWiFiSignal { return [self getOverrides]->values.displayRawWifiSignal == 1; }
- (void)displayRawWifiSignal:(bool)displaying {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideDisplayRawWifiSignal = 1;
    o->values.displayRawWifiSignal = displaying;
    [self applyChanges:o];
}

- (bool)isDisplayingRawGSMSignal { return [self getOverrides]->values.displayRawGSMSignal == 1; }
- (void)displayRawGSMSignal:(bool)displaying {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideDisplayRawGSMSignal = 1;
    o->values.displayRawGSMSignal = displaying;
    [self applyChanges:o];
}

// MARK: - Item Visibility (hide/show)

- (bool)isClockHidden { return [self getOverrides]->overrideItemIsEnabled[TimeStatusBarItem] == 1; }
- (void)hideClock:(bool)hidden {
    StatusBarOverrideData *o = [self getOverrides];
    if (hidden) { o->overrideItemIsEnabled[TimeStatusBarItem] = 1; o->values.itemIsEnabled[TimeStatusBarItem] = 0; }
    else        { o->overrideItemIsEnabled[TimeStatusBarItem] = 0; }
    [self applyChanges:o];
}

- (bool)isDNDHidden { return [self getOverrides]->overrideItemIsEnabled[QuietModeStatusBarItem] == 1; }
- (void)hideDND:(bool)hidden {
    StatusBarOverrideData *o = [self getOverrides];
    if (hidden) { o->overrideItemIsEnabled[QuietModeStatusBarItem] = 1; o->values.itemIsEnabled[QuietModeStatusBarItem] = 0; }
    else        { o->overrideItemIsEnabled[QuietModeStatusBarItem] = 0; }
    [self applyChanges:o];
}

- (bool)isAirplaneHidden { return [self getOverrides]->overrideItemIsEnabled[AirplaneModeStatusBarItem] == 1; }
- (void)hideAirplane:(bool)hidden {
    StatusBarOverrideData *o = [self getOverrides];
    if (hidden) { o->overrideItemIsEnabled[AirplaneModeStatusBarItem] = 1; o->values.itemIsEnabled[AirplaneModeStatusBarItem] = 0; }
    else        { o->overrideItemIsEnabled[AirplaneModeStatusBarItem] = 0; }
    [self applyChanges:o];
}

- (bool)isCellHidden { return [self getOverrides]->overrideItemIsEnabled[CellularSignalStrengthStatusBarItem] == 1; }
- (void)hideCell:(bool)hidden {
    StatusBarOverrideData *o = [self getOverrides];
    if (hidden) { o->overrideItemIsEnabled[CellularSignalStrengthStatusBarItem] = 1; o->values.itemIsEnabled[CellularSignalStrengthStatusBarItem] = 0; }
    else        { o->overrideItemIsEnabled[CellularSignalStrengthStatusBarItem] = 0; }
    [self applyChanges:o];
}

- (bool)isWiFiHidden { return [self getOverrides]->overrideItemIsEnabled[BluetoothStatusBarItem - 2] == 1; }
- (void)hideWiFi:(bool)hidden {
    // WiFi は独立した StatusBarItem 番号を持たないため BluetoothStatusBarItem-2 を使用
    StatusBarOverrideData *o = [self getOverrides];
    int idx = BluetoothStatusBarItem - 2; // = 14
    if (hidden) { o->overrideItemIsEnabled[idx] = 1; o->values.itemIsEnabled[idx] = 0; }
    else        { o->overrideItemIsEnabled[idx] = 0; }
    [self applyChanges:o];
}

- (bool)isBatteryHidden { return [self getOverrides]->overrideItemIsEnabled[MainBatteryStatusBarItem] == 1; }
- (void)hideBattery:(bool)hidden {
    StatusBarOverrideData *o = [self getOverrides];
    if (hidden) { o->overrideItemIsEnabled[MainBatteryStatusBarItem] = 1; o->values.itemIsEnabled[MainBatteryStatusBarItem] = 0; }
    else        { o->overrideItemIsEnabled[MainBatteryStatusBarItem] = 0; }
    [self applyChanges:o];
}

- (bool)isBluetoothHidden { return [self getOverrides]->overrideItemIsEnabled[BluetoothStatusBarItem] == 1; }
- (void)hideBluetooth:(bool)hidden {
    StatusBarOverrideData *o = [self getOverrides];
    if (hidden) { o->overrideItemIsEnabled[BluetoothStatusBarItem] = 1; o->values.itemIsEnabled[BluetoothStatusBarItem] = 0; }
    else        { o->overrideItemIsEnabled[BluetoothStatusBarItem] = 0; }
    [self applyChanges:o];
}

- (bool)isAlarmHidden { return [self getOverrides]->overrideItemIsEnabled[AlarmStatusBarItem] == 1; }
- (void)hideAlarm:(bool)hidden {
    StatusBarOverrideData *o = [self getOverrides];
    if (hidden) { o->overrideItemIsEnabled[AlarmStatusBarItem] = 1; o->values.itemIsEnabled[AlarmStatusBarItem] = 0; }
    else        { o->overrideItemIsEnabled[AlarmStatusBarItem] = 0; }
    [self applyChanges:o];
}

- (bool)isLocationHidden { return [self getOverrides]->overrideItemIsEnabled[LocationStatusBarItem] == 1; }
- (void)hideLocation:(bool)hidden {
    StatusBarOverrideData *o = [self getOverrides];
    if (hidden) { o->overrideItemIsEnabled[LocationStatusBarItem] = 1; o->values.itemIsEnabled[LocationStatusBarItem] = 0; }
    else        { o->overrideItemIsEnabled[LocationStatusBarItem] = 0; }
    [self applyChanges:o];
}

- (bool)isRotationHidden { return [self getOverrides]->overrideItemIsEnabled[RotationLockStatusBarItem] == 1; }
- (void)hideRotation:(bool)hidden {
    StatusBarOverrideData *o = [self getOverrides];
    if (hidden) { o->overrideItemIsEnabled[RotationLockStatusBarItem] = 1; o->values.itemIsEnabled[RotationLockStatusBarItem] = 0; }
    else        { o->overrideItemIsEnabled[RotationLockStatusBarItem] = 0; }
    [self applyChanges:o];
}

- (bool)isAirPlayHidden { return [self getOverrides]->overrideItemIsEnabled[AirPlayStatusBarItem] == 1; }
- (void)hideAirPlay:(bool)hidden {
    StatusBarOverrideData *o = [self getOverrides];
    if (hidden) { o->overrideItemIsEnabled[AirPlayStatusBarItem] = 1; o->values.itemIsEnabled[AirPlayStatusBarItem] = 0; }
    else        { o->overrideItemIsEnabled[AirPlayStatusBarItem] = 0; }
    [self applyChanges:o];
}

- (bool)isCarPlayHidden { return [self getOverrides]->overrideItemIsEnabled[CarPlayStatusBarItem] == 1; }
- (void)hideCarPlay:(bool)hidden {
    StatusBarOverrideData *o = [self getOverrides];
    if (hidden) { o->overrideItemIsEnabled[CarPlayStatusBarItem] = 1; o->values.itemIsEnabled[CarPlayStatusBarItem] = 0; }
    else        { o->overrideItemIsEnabled[CarPlayStatusBarItem] = 0; }
    [self applyChanges:o];
}

- (bool)isVPNHidden { return [self getOverrides]->overrideItemIsEnabled[VPNStatusBarItem] == 1; }
- (void)hideVPN:(bool)hidden {
    StatusBarOverrideData *o = [self getOverrides];
    if (hidden) { o->overrideItemIsEnabled[VPNStatusBarItem] = 1; o->values.itemIsEnabled[VPNStatusBarItem] = 0; }
    else        { o->overrideItemIsEnabled[VPNStatusBarItem] = 0; }
    [self applyChanges:o];
}

- (bool)isMicrophoneUseHidden { return [self getOverrides]->overrideItemIsEnabled[MicrophoneUseStatusBarItem] == 1; }
- (void)hideMicrophoneUse:(bool)hidden {
    StatusBarOverrideData *o = [self getOverrides];
    if (hidden) { o->overrideItemIsEnabled[MicrophoneUseStatusBarItem] = 1; o->values.itemIsEnabled[MicrophoneUseStatusBarItem] = 0; }
    else        { o->overrideItemIsEnabled[MicrophoneUseStatusBarItem] = 0; }
    [self applyChanges:o];
}

- (bool)isCameraUseHidden { return [self getOverrides]->overrideItemIsEnabled[CameraUseStatusBarItem] == 1; }
- (void)hideCameraUse:(bool)hidden {
    StatusBarOverrideData *o = [self getOverrides];
    if (hidden) { o->overrideItemIsEnabled[CameraUseStatusBarItem] = 1; o->values.itemIsEnabled[CameraUseStatusBarItem] = 0; }
    else        { o->overrideItemIsEnabled[CameraUseStatusBarItem] = 0; }
    [self applyChanges:o];
}

@end
