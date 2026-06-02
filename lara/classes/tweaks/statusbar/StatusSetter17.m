//
//  StatusSetter17.m
//  lara
//
//  Based on StatusSetter16_1 from Cowabunga (MIT License)
//  Adapted for lara:
//    - Cowabunga の MDCモードと同じくファイルへの構造体書き込みで実装
//    - ファイルI/OはSwift側から注入した関数ポインタ経由で行う
//      (vfs_write未実装のため sbxoverwrite 経由で書く必要があるため)
//

#import "StatusSetter17.h"
#import <Foundation/Foundation.h>
#import <string.h>

// MARK: - StatusBarItem enum

typedef NS_ENUM(int, StatusBarItem) {
    TimeStatusBarItem                            = 0,
    DateStatusBarItem                            = 1,
    QuietModeStatusBarItem                       = 2,
    AirplaneModeStatusBarItem                    = 3,
    CellularSignalStrengthStatusBarItem          = 4,
    SecondaryCellularSignalStrengthStatusBarItem = 5,
    CellularServiceStatusBarItem                 = 6,
    SecondaryCellularServiceStatusBarItem        = 7,
    CellularDataNetworkStatusBarItem             = 9,
    SecondaryCellularDataNetworkStatusBarItem    = 10,
    MainBatteryStatusBarItem                     = 12,
    ProminentlyShowBatteryDetailStatusBarItem    = 13,
    BluetoothStatusBarItem                       = 16,
    TTYStatusBarItem                             = 17,
    AlarmStatusBarItem                           = 18,
    LocationStatusBarItem                        = 21,
    RotationLockStatusBarItem                    = 22,
    CameraUseStatusBarItem                       = 23,
    AirPlayStatusBarItem                         = 24,
    AssistantStatusBarItem                       = 25,
    CarPlayStatusBarItem                         = 26,
    StudentStatusBarItem                         = 27,
    MicrophoneUseStatusBarItem                   = 28,
    VPNStatusBarItem                             = 29,
    LiquidDetectionStatusBarItem                 = 38,
    VoiceControlStatusBarItem                    = 39,
    Extra1StatusBarItem                          = 44,
};

// MARK: - Structs

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

// MARK: - Function pointer storage

static BOOL (^g_writeBlock)(const void *data, NSUInteger len) = nil;
static BOOL (^g_readBlock)(void *buf, NSUInteger len)       = nil;
static BOOL (^g_existsBlock)(void)                         = nil;

// MARK: - StatusSetter17

@implementation StatusSetter17

+ (void)setWriteBlock:(BOOL (^)(const void *data, NSUInteger len))writeBlock
           readBlock:(BOOL (^)(void *buf, NSUInteger len))readBlock
         existsBlock:(BOOL (^)(void))existsBlock {
    g_writeBlock  = [writeBlock copy];
    g_readBlock   = [readBlock copy];
    g_existsBlock = [existsBlock copy];
}

// Cowabunga MDCモードと同じ仕組み：
// 構造体 + 256バイトパディングを statusBarOverrides に書き出す。
// 書き込みは Swift 側の sbxoverwrite 経由（関数ポインタで注入）。
- (void)applyChanges:(StatusBarOverrideData *)overrides {
    if (!g_writeBlock) { NSLog(@"[StatusSetter17] writeBlock not set"); return; }

    // Cowabunga と同じく末尾に 256バイトのパディングを付ける
    size_t totalLen = sizeof(StatusBarOverrideData) + 256;
    uint8_t *buf = (uint8_t *)calloc(1, totalLen);
    if (!buf) return;
    memcpy(buf, overrides, sizeof(StatusBarOverrideData));
    g_writeBlock(buf, (NSUInteger)totalLen);
    free(buf);
}

- (StatusBarOverrideData *)getOverrides {
    NSMutableData *storage = [NSMutableData dataWithLength:sizeof(StatusBarOverrideData)];
    StatusBarOverrideData *o = (StatusBarOverrideData *)[storage mutableBytes];

    if (g_existsBlock && g_existsBlock() && g_readBlock) {
        g_readBlock(o, sizeof(StatusBarOverrideData));
    }
    // ファイルがなければゼロ初期化のまま返す
    return o;
}

// MARK: - Carrier

- (bool)isCarrierOverridden { return [self getOverrides]->overrideServiceString == 1; }
- (NSString *)getCarrierOverride { return @([self getOverrides]->values.serviceString); }
- (void)setCarrier:(NSString *)text {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideServiceString = 1;
    strcpy(o->values.serviceString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    strcpy(o->values.serviceCrossfadeString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    [self applyChanges:o];
}
- (void)unsetCarrier {
    StatusBarOverrideData *o = [self getOverrides]; o->overrideServiceString = 0; [self applyChanges:o];
}

- (bool)isSecondaryCarrierOverridden { return [self getOverrides]->overrideSecondaryServiceString == 1; }
- (NSString *)getSecondaryCarrierOverride { return @([self getOverrides]->values.secondaryServiceString); }
- (void)setSecondaryCarrier:(NSString *)text {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideSecondaryServiceString = 1;
    strcpy(o->values.secondaryServiceString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    strcpy(o->values.secondaryServiceCrossfadeString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    [self applyChanges:o];
}
- (void)unsetSecondaryCarrier {
    StatusBarOverrideData *o = [self getOverrides]; o->overrideSecondaryServiceString = 0; [self applyChanges:o];
}

- (bool)isPrimaryServiceBadgeOverridden { return [self getOverrides]->overridePrimaryServiceBadgeString == 1; }
- (NSString *)getPrimaryServiceBadgeOverride { return @([self getOverrides]->values.primaryServiceBadgeString); }
- (void)setPrimaryServiceBadge:(NSString *)text {
    StatusBarOverrideData *o = [self getOverrides];
    o->overridePrimaryServiceBadgeString = 1;
    strcpy(o->values.primaryServiceBadgeString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    [self applyChanges:o];
}
- (void)unsetPrimaryServiceBadge {
    StatusBarOverrideData *o = [self getOverrides]; o->overridePrimaryServiceBadgeString = 0; [self applyChanges:o];
}

- (bool)isSecondaryServiceBadgeOverridden { return [self getOverrides]->overrideSecondaryServiceBadgeString == 1; }
- (NSString *)getSecondaryServiceBadgeOverride { return @([self getOverrides]->values.secondaryServiceBadgeString); }
- (void)setSecondaryServiceBadge:(NSString *)text {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideSecondaryServiceBadgeString = 1;
    strcpy(o->values.secondaryServiceBadgeString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    [self applyChanges:o];
}
- (void)unsetSecondaryServiceBadge {
    StatusBarOverrideData *o = [self getOverrides]; o->overrideSecondaryServiceBadgeString = 0; [self applyChanges:o];
}

- (bool)isDateOverridden { return [self getOverrides]->overrideDateString == 1; }
- (NSString *)getDateOverride { return @([self getOverrides]->values.dateString); }
- (void)setDate:(NSString *)text {
    StatusBarOverrideData *o = [self getOverrides]; o->overrideDateString = 1;
    strcpy(o->values.dateString, [text cStringUsingEncoding:NSUTF8StringEncoding]); [self applyChanges:o];
}
- (void)unsetDate { StatusBarOverrideData *o = [self getOverrides]; o->overrideDateString = 0; [self applyChanges:o]; }

- (bool)isTimeOverridden { return [self getOverrides]->overrideTimeString == 1; }
- (NSString *)getTimeOverride { return @([self getOverrides]->values.timeString); }
- (void)setTime:(NSString *)text {
    StatusBarOverrideData *o = [self getOverrides]; o->overrideTimeString = 1;
    strcpy(o->values.timeString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    strcpy(o->values.shortTimeString, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    [self applyChanges:o];
}
- (void)unsetTime { StatusBarOverrideData *o = [self getOverrides]; o->overrideTimeString = 0; [self applyChanges:o]; }

- (bool)isBatteryDetailOverridden { return [self getOverrides]->overrideBatteryDetailString == 1; }
- (NSString *)getBatteryDetailOverride { return @([self getOverrides]->values.batteryDetailString); }
- (void)setBatteryDetail:(NSString *)text {
    StatusBarOverrideData *o = [self getOverrides]; o->overrideBatteryDetailString = 1;
    strcpy(o->values.batteryDetailString, [text cStringUsingEncoding:NSUTF8StringEncoding]); [self applyChanges:o];
}
- (void)unsetBatteryDetail { StatusBarOverrideData *o = [self getOverrides]; o->overrideBatteryDetailString = 0; [self applyChanges:o]; }

- (bool)isCrumbOverridden { return [self getOverrides]->overrideBreadcrumb == 1; }
- (NSString *)getCrumbOverride { return @([self getOverrides]->values.breadcrumbTitle); }
- (void)setCrumb:(NSString *)text {
    StatusBarOverrideData *o = [self getOverrides]; o->overrideBreadcrumb = 1;
    strcpy(o->values.breadcrumbTitle, [text cStringUsingEncoding:NSUTF8StringEncoding]); [self applyChanges:o];
}
- (void)unsetCrumb { StatusBarOverrideData *o = [self getOverrides]; o->overrideBreadcrumb = 0; [self applyChanges:o]; }

- (bool)isCellularServiceOverridden { return [self getOverrides]->overrideItemIsEnabled[CellularServiceStatusBarItem] == 1; }
- (bool)getCellularServiceOverride { return [self getOverrides]->values.itemIsEnabled[CellularServiceStatusBarItem]; }
- (void)setCellularService:(bool)val {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideItemIsEnabled[CellularServiceStatusBarItem] = 1; o->values.itemIsEnabled[CellularServiceStatusBarItem] = val; [self applyChanges:o];
}
- (void)unsetCellularService { StatusBarOverrideData *o = [self getOverrides]; o->overrideItemIsEnabled[CellularServiceStatusBarItem] = 0; [self applyChanges:o]; }

- (bool)isSecondaryCellularServiceOverridden { return [self getOverrides]->overrideItemIsEnabled[SecondaryCellularServiceStatusBarItem] == 1; }
- (bool)getSecondaryCellularServiceOverride { return [self getOverrides]->values.itemIsEnabled[SecondaryCellularServiceStatusBarItem]; }
- (void)setSecondaryCellularService:(bool)val {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideItemIsEnabled[SecondaryCellularServiceStatusBarItem] = 1; o->values.itemIsEnabled[SecondaryCellularServiceStatusBarItem] = val; [self applyChanges:o];
}
- (void)unsetSecondaryCellularService { StatusBarOverrideData *o = [self getOverrides]; o->overrideItemIsEnabled[SecondaryCellularServiceStatusBarItem] = 0; [self applyChanges:o]; }

- (bool)isDataNetworkTypeOverridden { return [self getOverrides]->overrideDataNetworkType == 1; }
- (int)getDataNetworkTypeOverride { return (int)[self getOverrides]->values.dataNetworkType; }
- (void)setDataNetworkType:(int)identifier {
    StatusBarOverrideData *o = [self getOverrides]; o->overrideDataNetworkType = 1; o->values.dataNetworkType = identifier; [self applyChanges:o];
}
- (void)unsetDataNetworkType { StatusBarOverrideData *o = [self getOverrides]; o->overrideDataNetworkType = 0; [self applyChanges:o]; }

- (bool)isSecondaryDataNetworkTypeOverridden { return [self getOverrides]->overrideSecondaryDataNetworkType == 1; }
- (int)getSecondaryDataNetworkTypeOverride { return (int)[self getOverrides]->values.secondaryDataNetworkType; }
- (void)setSecondaryDataNetworkType:(int)identifier {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideItemIsEnabled[SecondaryCellularDataNetworkStatusBarItem] = 1;
    o->values.itemIsEnabled[SecondaryCellularDataNetworkStatusBarItem] = 1;
    o->overrideSecondaryDataNetworkType = 1;
    o->values.secondaryDataNetworkType = identifier;
    [self applyChanges:o];
}
- (void)unsetSecondaryDataNetworkType {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideSecondaryDataNetworkType = 0;
    o->overrideItemIsEnabled[SecondaryCellularDataNetworkStatusBarItem] = 0;
    [self applyChanges:o];
}

- (bool)isBatteryCapacityOverridden { return [self getOverrides]->overrideBatteryCapacity == 1; }
- (int)getBatteryCapacityOverride { return [self getOverrides]->values.batteryCapacity; }
- (void)setBatteryCapacity:(int)capacity {
    StatusBarOverrideData *o = [self getOverrides]; o->overrideBatteryCapacity = 1; o->values.batteryCapacity = capacity; [self applyChanges:o];
}
- (void)unsetBatteryCapacity { StatusBarOverrideData *o = [self getOverrides]; o->overrideBatteryCapacity = 0; [self applyChanges:o]; }

- (bool)isWiFiSignalStrengthBarsOverridden { return [self getOverrides]->overrideWifiSignalStrengthBars == 1; }
- (int)getWiFiSignalStrengthBarsOverride { return [self getOverrides]->values.wifiSignalStrengthBars; }
- (void)setWiFiSignalStrengthBars:(int)s {
    StatusBarOverrideData *o = [self getOverrides]; o->overrideWifiSignalStrengthBars = 1; o->values.wifiSignalStrengthBars = s; [self applyChanges:o];
}
- (void)unsetWiFiSignalStrengthBars { StatusBarOverrideData *o = [self getOverrides]; o->overrideWifiSignalStrengthBars = 0; [self applyChanges:o]; }

- (bool)isGsmSignalStrengthBarsOverridden { return [self getOverrides]->overrideGsmSignalStrengthBars == 1; }
- (int)getGsmSignalStrengthBarsOverride { return [self getOverrides]->values.gsmSignalStrengthBars; }
- (void)setGsmSignalStrengthBars:(int)s {
    StatusBarOverrideData *o = [self getOverrides]; o->overrideGsmSignalStrengthBars = 1; o->values.gsmSignalStrengthBars = s; [self applyChanges:o];
}
- (void)unsetGsmSignalStrengthBars { StatusBarOverrideData *o = [self getOverrides]; o->overrideGsmSignalStrengthBars = 0; [self applyChanges:o]; }

- (bool)isSecondaryGsmSignalStrengthBarsOverridden { return [self getOverrides]->overrideSecondaryGsmSignalStrengthBars == 1; }
- (int)getSecondaryGsmSignalStrengthBarsOverride { return [self getOverrides]->values.secondaryGsmSignalStrengthBars; }
- (void)setSecondaryGsmSignalStrengthBars:(int)s {
    StatusBarOverrideData *o = [self getOverrides];
    o->values.secondaryGsmSignalStrengthBars = s;
    o->overrideSecondaryGsmSignalStrengthBars = 1;
    o->overrideItemIsEnabled[SecondaryCellularSignalStrengthStatusBarItem] = 1;
    o->values.itemIsEnabled[SecondaryCellularSignalStrengthStatusBarItem] = 1;
    [self applyChanges:o];
}
- (void)unsetSecondaryGsmSignalStrengthBars {
    StatusBarOverrideData *o = [self getOverrides];
    o->overrideSecondaryGsmSignalStrengthBars = 0;
    o->overrideItemIsEnabled[SecondaryCellularSignalStrengthStatusBarItem] = 0;
    [self applyChanges:o];
}

- (bool)isDisplayingRawWiFiSignal { return [self getOverrides]->values.displayRawWifiSignal == 1; }
- (void)displayRawWifiSignal:(bool)displaying {
    StatusBarOverrideData *o = [self getOverrides]; o->overrideDisplayRawWifiSignal = 1; o->values.displayRawWifiSignal = displaying; [self applyChanges:o];
}
- (bool)isDisplayingRawGSMSignal { return [self getOverrides]->values.displayRawGSMSignal == 1; }
- (void)displayRawGSMSignal:(bool)displaying {
    StatusBarOverrideData *o = [self getOverrides]; o->overrideDisplayRawGSMSignal = 1; o->values.displayRawGSMSignal = displaying; [self applyChanges:o];
}

- (bool)isClockHidden { return [self getOverrides]->overrideItemIsEnabled[TimeStatusBarItem] == 1; }
- (void)hideClock:(bool)h {
    StatusBarOverrideData *o = [self getOverrides];
    if (h) { o->overrideItemIsEnabled[TimeStatusBarItem] = 1; o->values.itemIsEnabled[TimeStatusBarItem] = 0; } else { o->overrideItemIsEnabled[TimeStatusBarItem] = 0; }
    [self applyChanges:o];
}
- (bool)isDNDHidden { return [self getOverrides]->overrideItemIsEnabled[QuietModeStatusBarItem] == 1; }
- (void)hideDND:(bool)h {
    StatusBarOverrideData *o = [self getOverrides];
    if (h) { o->overrideItemIsEnabled[QuietModeStatusBarItem] = 1; o->values.itemIsEnabled[QuietModeStatusBarItem] = 0; } else { o->overrideItemIsEnabled[QuietModeStatusBarItem] = 0; }
    [self applyChanges:o];
}
- (bool)isAirplaneHidden { return [self getOverrides]->overrideItemIsEnabled[AirplaneModeStatusBarItem] == 1; }
- (void)hideAirplane:(bool)h {
    StatusBarOverrideData *o = [self getOverrides];
    if (h) { o->overrideItemIsEnabled[AirplaneModeStatusBarItem] = 1; o->values.itemIsEnabled[AirplaneModeStatusBarItem] = 0; } else { o->overrideItemIsEnabled[AirplaneModeStatusBarItem] = 0; }
    [self applyChanges:o];
}
- (bool)isCellHidden { return [self getOverrides]->overrideItemIsEnabled[CellularSignalStrengthStatusBarItem] == 1; }
- (void)hideCell:(bool)h {
    StatusBarOverrideData *o = [self getOverrides];
    if (h) { o->overrideItemIsEnabled[CellularSignalStrengthStatusBarItem] = 1; o->values.itemIsEnabled[CellularSignalStrengthStatusBarItem] = 0; } else { o->overrideItemIsEnabled[CellularSignalStrengthStatusBarItem] = 0; }
    [self applyChanges:o];
}
- (bool)isWiFiHidden { return [self getOverrides]->overrideItemIsEnabled[BluetoothStatusBarItem - 2] == 1; }
- (void)hideWiFi:(bool)h {
    StatusBarOverrideData *o = [self getOverrides]; int idx = BluetoothStatusBarItem - 2;
    if (h) { o->overrideItemIsEnabled[idx] = 1; o->values.itemIsEnabled[idx] = 0; } else { o->overrideItemIsEnabled[idx] = 0; }
    [self applyChanges:o];
}
- (bool)isBatteryHidden { return [self getOverrides]->overrideItemIsEnabled[MainBatteryStatusBarItem] == 1; }
- (void)hideBattery:(bool)h {
    StatusBarOverrideData *o = [self getOverrides];
    if (h) { o->overrideItemIsEnabled[MainBatteryStatusBarItem] = 1; o->values.itemIsEnabled[MainBatteryStatusBarItem] = 0; } else { o->overrideItemIsEnabled[MainBatteryStatusBarItem] = 0; }
    [self applyChanges:o];
}
- (bool)isBluetoothHidden { return [self getOverrides]->overrideItemIsEnabled[BluetoothStatusBarItem] == 1; }
- (void)hideBluetooth:(bool)h {
    StatusBarOverrideData *o = [self getOverrides];
    if (h) { o->overrideItemIsEnabled[BluetoothStatusBarItem] = 1; o->values.itemIsEnabled[BluetoothStatusBarItem] = 0; } else { o->overrideItemIsEnabled[BluetoothStatusBarItem] = 0; }
    [self applyChanges:o];
}
- (bool)isAlarmHidden { return [self getOverrides]->overrideItemIsEnabled[AlarmStatusBarItem] == 1; }
- (void)hideAlarm:(bool)h {
    StatusBarOverrideData *o = [self getOverrides];
    if (h) { o->overrideItemIsEnabled[AlarmStatusBarItem] = 1; o->values.itemIsEnabled[AlarmStatusBarItem] = 0; } else { o->overrideItemIsEnabled[AlarmStatusBarItem] = 0; }
    [self applyChanges:o];
}
- (bool)isLocationHidden { return [self getOverrides]->overrideItemIsEnabled[LocationStatusBarItem] == 1; }
- (void)hideLocation:(bool)h {
    StatusBarOverrideData *o = [self getOverrides];
    if (h) { o->overrideItemIsEnabled[LocationStatusBarItem] = 1; o->values.itemIsEnabled[LocationStatusBarItem] = 0; } else { o->overrideItemIsEnabled[LocationStatusBarItem] = 0; }
    [self applyChanges:o];
}
- (bool)isRotationHidden { return [self getOverrides]->overrideItemIsEnabled[RotationLockStatusBarItem] == 1; }
- (void)hideRotation:(bool)h {
    StatusBarOverrideData *o = [self getOverrides];
    if (h) { o->overrideItemIsEnabled[RotationLockStatusBarItem] = 1; o->values.itemIsEnabled[RotationLockStatusBarItem] = 0; } else { o->overrideItemIsEnabled[RotationLockStatusBarItem] = 0; }
    [self applyChanges:o];
}
- (bool)isAirPlayHidden { return [self getOverrides]->overrideItemIsEnabled[AirPlayStatusBarItem] == 1; }
- (void)hideAirPlay:(bool)h {
    StatusBarOverrideData *o = [self getOverrides];
    if (h) { o->overrideItemIsEnabled[AirPlayStatusBarItem] = 1; o->values.itemIsEnabled[AirPlayStatusBarItem] = 0; } else { o->overrideItemIsEnabled[AirPlayStatusBarItem] = 0; }
    [self applyChanges:o];
}
- (bool)isCarPlayHidden { return [self getOverrides]->overrideItemIsEnabled[CarPlayStatusBarItem] == 1; }
- (void)hideCarPlay:(bool)h {
    StatusBarOverrideData *o = [self getOverrides];
    if (h) { o->overrideItemIsEnabled[CarPlayStatusBarItem] = 1; o->values.itemIsEnabled[CarPlayStatusBarItem] = 0; } else { o->overrideItemIsEnabled[CarPlayStatusBarItem] = 0; }
    [self applyChanges:o];
}
- (bool)isVPNHidden { return [self getOverrides]->overrideItemIsEnabled[VPNStatusBarItem] == 1; }
- (void)hideVPN:(bool)h {
    StatusBarOverrideData *o = [self getOverrides];
    if (h) { o->overrideItemIsEnabled[VPNStatusBarItem] = 1; o->values.itemIsEnabled[VPNStatusBarItem] = 0; } else { o->overrideItemIsEnabled[VPNStatusBarItem] = 0; }
    [self applyChanges:o];
}
- (bool)isMicrophoneUseHidden { return [self getOverrides]->overrideItemIsEnabled[MicrophoneUseStatusBarItem] == 1; }
- (void)hideMicrophoneUse:(bool)h {
    StatusBarOverrideData *o = [self getOverrides];
    if (h) { o->overrideItemIsEnabled[MicrophoneUseStatusBarItem] = 1; o->values.itemIsEnabled[MicrophoneUseStatusBarItem] = 0; } else { o->overrideItemIsEnabled[MicrophoneUseStatusBarItem] = 0; }
    [self applyChanges:o];
}
- (bool)isCameraUseHidden { return [self getOverrides]->overrideItemIsEnabled[CameraUseStatusBarItem] == 1; }
- (void)hideCameraUse:(bool)h {
    StatusBarOverrideData *o = [self getOverrides];
    if (h) { o->overrideItemIsEnabled[CameraUseStatusBarItem] = 1; o->values.itemIsEnabled[CameraUseStatusBarItem] = 0; } else { o->overrideItemIsEnabled[CameraUseStatusBarItem] = 0; }
    [self applyChanges:o];
}

@end
