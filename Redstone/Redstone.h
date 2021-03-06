#if (TARGET_OS_SIMULATOR)
#define PREFERENCES_PATH @"/opt/simject/FESTIVAL/ml.festival.redstone.plist"
#define RESOURCES_PATH @"/opt/simject/FESTIVAL/Redstone"
#define LOCK_WALLPAPER_PATH [NSString stringWithFormat:@"%@/Library/SpringBoard/LockBackground.cpbitmap", NSHomeDirectory()]
#define HOME_WALLPAPER_PATH [NSString stringWithFormat:@"%@/Library/SpringBoard/HomeBackground.cpbitmap", NSHomeDirectory()]
#else
#define PREFERENCES_PATH @"/var/mobile/Library/Preferences/ml.festival.redstone.plist"
#define RESOURCES_PATH @"/var/mobile/Library/FESTIVAL/Redstone"
#define LOCK_WALLPAPER_PATH @"/var/mobile/Library/SpringBoard/LockBackground.cpbitmap"
#define HOME_WALLPAPER_PATH @"/var/mobile/Library/SpringBoard/HomeBackground.cpbitmap"
#endif

#define screenWidth [UIScreen mainScreen].bounds.size.width
#define screenHeight [UIScreen mainScreen].bounds.size.height
#define deg2rad(angle) ((angle) / 180.0 * M_PI)

#import <objc/runtime.h>

#import <SpringBoard/SpringBoard.h>
#import <Celestial/AVSystemController.h>
#import <SpringBoardUIServices/SpringBoardUIServices.h>
#import <BulletinBoard/BBBulletin.h>
#import <UserNotificationsKit/NCNotificationRequest.h>
#import "_UILegibilitySettings.h"

#pragma mark Libraries
#import "Libraries/CAKeyframeAnimation+AHEasing.h"
#import "Libraries/easing.h"
#import "Libraries/UIFont+WDCustomLoader.h"
#import "Libraries/UIImageAverageColorAddition.h"
#import "Libraries/UIView+Easing.h"

#pragma mark Core
#import "Core/RSCore.h"
#import "Core/RSPreferences.h"
#import "Core/RSMetrics.h"
#import "Core/RSAesthetics.h"
#import "Core/RSAnimation.h"

#pragma mark UI
#import "UI/RSTiltView.h"
#import "UI/RSFlyoutMenu.h"
#import "UI/RSTextField.h"
#import "UI/RSAlertController.h"
#import "UI/RSAlertAction.h"
#import "UI/RSSlider.h"
#import "UI/RSNowPlayingControls.h"

#pragma mark Home Screen
#import "HomeScreen/RSHomeScreenController.h"
#import "HomeScreen/RSHomeScreenScrollView.h"
#import "HomeScreen/RSHomeScreenWallpaperView.h"

#pragma mark Start Screen
#import "StartScreen/RSStartScreenController.h"
#import "StartScreen/RSStartScreenScrollView.h"
#import "StartScreen/RSTile.h"
#import "StartScreen/RSTileButton.h"
#import "StartScreen/RSTileInfo.h"
#import "StartScreen/RSLiveTileInterface.h"

#pragma mark App List
#import "AppList/RSAppListController.h"
#import "AppList/RSAppListScrollView.h"
#import "AppList/RSApp.h"
#import "AppList/RSAppListSection.h"
#import "AppList/RSJumpList.h"

#pragma mark Launch Screen
#import "LaunchScreen/RSLaunchScreenController.h"

#pragma mark Volume Controls
#import "AudioControls/RSAudioController.h"
#import "AudioControls/RSVolumeHUD.h"
#import "AudioControls/RSVolumeView.h"

#pragma mark Notifications
#import "Notifications/RSNotificationController.h"
#import "Notifications/RSNotificationView.h"

#pragma mark Lock Screen
#import "LockScreen/RSLockScreenController.h"
#import "LockScreen/RSLockScreenView.h"
#import "LockScreen/RSLockScreenNotificationArea.h"
#import "LockScreen/RSLockScreenNotificationApp.h"
#import "LockScreen/RSLockScreenSecurityController.h"
#import "LockScreen/RSLockScreenPasscodeEntryButton.h"
#import "LockScreen/RSLockScreenPasscodeEntryTextField.h"
#import "LockScreen/RSPasscodeLockViewSimpleFixedDigitKeypad.h"
#import "LockScreen/RSPasscodeLockViewLongNumericKeypad.h"
#import "LockScreen/RSPasscodeLockViewAlphanumericKeyboard.h"
