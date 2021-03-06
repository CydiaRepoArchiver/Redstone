#import "Redstone.h"
#import "substrate.h"

%group lockscreen_ios10

SBPagedScrollView* dashboardScrollView;

%hook SBDashBoardScrollGestureController

- (id)initWithDashBoardView:(id)arg1 systemGestureManager:(id)arg2 {
	id r = %orig;
	
	dashboardScrollView = MSHookIvar<SBPagedScrollView*>(r, "_scrollView");
	
	return r;
}

%end	// %hook SBDashBoardScrollGestureController

%hook SBPagedScrollView

- (void)layoutSubviews {
	if (self == dashboardScrollView) {
		[self setScrollEnabled:NO];
		[self setUserInteractionEnabled:NO];
		[self setContentOffset:CGPointMake(-screenWidth, 0)];
	} else {
		%orig;
	}
}

%end	// %hook SBDashBoardScrollGestureController

%hook SBDashBoardViewController

- (void)startLockScreenFadeInAnimationForSource:(int)arg1 {
	[[[[RSCore sharedInstance] lockScreenController] view] reset];
	
	%orig(arg1);
}

%end	// %hook SBDashBoardViewController

%hook SBDashBoardView

- (void)layoutSubviews {
	[MSHookIvar<UIView*>(self, "_pageControl") removeFromSuperview];
	[self setHidden:YES];
	
	if (![self.superview.subviews containsObject:[[[RSCore sharedInstance] lockScreenController] view]]) {
		[self.superview addSubview:[[[RSCore sharedInstance] lockScreenController] view]];
	}
	
	[self.superview bringSubviewToFront:[[[RSCore sharedInstance] lockScreenController] view]];
}

%end	// %hook SBDashboardView

%hook SBFLockScreenDateView

- (void)layoutSubviews {
	%orig;
	
	[MSHookIvar<SBUILegibilityLabel *>(self,"_timeLabel") removeFromSuperview];
	[MSHookIvar<SBUILegibilityLabel *>(self,"_dateSubtitleView") removeFromSuperview];
	[MSHookIvar<SBUILegibilityLabel *>(self,"_customSubtitleView") removeFromSuperview];
	
	[[[[RSCore sharedInstance] lockScreenController] view] setTime:[MSHookIvar<SBUILegibilityLabel *>(self,"_timeLabel") string]];
	[[[[RSCore sharedInstance] lockScreenController] view] setDate:[MSHookIvar<SBUILegibilityLabel *>(self,"_dateSubtitleView") string]];
}

%end	// %hook SBFLockScreenDateView

%end	// %group lockscreen_ios10

%group lockscreen_ios9

%hook SBLockScreenView

- (void)layoutSubviews {
	%orig;
	[self setHidden:YES];
	
	if (![self.superview.subviews containsObject:[[[RSCore sharedInstance] lockScreenController] view]]) {
		[self.superview addSubview:[[[RSCore sharedInstance] lockScreenController] view]];
	}
	
	[self.superview bringSubviewToFront:[[[RSCore sharedInstance] lockScreenController] view]];
}

%end	// %hook SBLockScreenView

%hook SBFLockScreenDateView

- (void)layoutSubviews {
	[MSHookIvar<SBUILegibilityLabel *>(self,"_legibilityTimeLabel") removeFromSuperview];
	[MSHookIvar<SBUILegibilityLabel *>(self,"_legibilityDateLabel") removeFromSuperview];
	
	[[[[RSCore sharedInstance] lockScreenController] view] setTime:[MSHookIvar<SBUILegibilityLabel *>(self,"_legibilityTimeLabel") string]];
	[[[[RSCore sharedInstance] lockScreenController] view] setDate:[MSHookIvar<SBUILegibilityLabel *>(self,"_legibilityDateLabel") string]];
	
	%orig;
}

%end	// %hook SBFLockScreenDateView

%end	// %group lockscreen_ios9



%group lockscreen_general

static SBUIPasscodeLockViewBase* storedPasscodeView;
static SBPasscodeKeyboard* storedPasscodeKeyboard;

%hook SBLockScreenManager

- (BOOL)_finishUIUnlockFromSource:(int)arg1 withOptions:(id)arg2 {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[[[[RSCore sharedInstance] lockScreenController] view] reset];
	});
	
	return %orig;
}

%end	// %hook SBLockScreenManager

%hook SBBacklightController

- (void)_startFadeOutAnimationFromLockSource:(int)arg1 {
	if ([[[[RSCore sharedInstance] lockScreenController] view] isScrolling] || [[[[RSCore sharedInstance] lockScreenController] view] isUnlocking]) {
		[self resetIdleTimer];
		return;
	}
	
	%orig(arg1);
}

%end	// %hook SBBacklightController

%hook SBUIPasscodeLockViewBase

- (id)initWithFrame:(CGRect)arg1 {
	id r = %orig;
	storedPasscodeView = r;
	return r;
}

- (void)layoutSubviews {
	[[RSLockScreenSecurityController sharedInstance] setCurrentPasscodeLockView:self];
	[[[[RSCore sharedInstance] lockScreenController] view] updatePasscodeKeyboard];
	%orig;
}

%new
+ (id)currentPasscodeView {
	return storedPasscodeView;
}

%end	// %hook SBUIPasscodeLockViewBase

%hook SBPasscodeKeyboard

+ (id)alloc {
	if (storedPasscodeKeyboard) {
		return storedPasscodeKeyboard;
	}
	
	return %orig;
}

- (id)init {
	if (storedPasscodeKeyboard) {
		return storedPasscodeKeyboard;
	}
	
	return %orig;
}

- (id)initWithFrame:(CGRect)arg1 {
	if (storedPasscodeKeyboard) {
		return storedPasscodeKeyboard;
	}
	
	id r = %orig;
	storedPasscodeKeyboard = r;
	return r;
}

- (void)layoutSubviews {
	%orig;
	
	storedPasscodeKeyboard = self;
	if (![self.superview isKindOfClass:[RSPasscodeLockViewAlphanumericKeyboard class]]) {
		[self removeFromSuperview];
	}
}

- (void)setFrame:(CGRect)arg1 {
	%orig(CGRectMake(0, 60, arg1.size.width, arg1.size.height));
}

%new
+ (id)storedPasscodeKeyboard {
	return storedPasscodeKeyboard;
}

%end	// %hook SBPasscodeKeyboard

%hook SBUIPasscodeLockViewWithKeypad

- (void)passcodeEntryFieldTextDidChange:(id)arg1 {
	[[[[RSCore sharedInstance] lockScreenController] view] handlePasscodeTextChanged];
	
	%orig;
}

%end	// %hook SBUIPasscodeLockViewWithKeypad

%hook SBUIPasscodeLockViewWithKeyboard

- (void)passcodeEntryFieldTextDidChange:(id)arg1 {
	%log;
	[[[[RSCore sharedInstance] lockScreenController] view] handlePasscodeTextChanged];
	
	%orig;
}

%end	// %hook SBUIPasscodeLockViewWithKeyboard

%hook SBFUserAuthenticationController

-(void)_handleSuccessfulAuthentication:(id)arg1 responder:(id)arg2 {
	//[[[RSLockScreenController sharedInstance] passcodeEntryController] handleSuccessfulAuthentication];
	%orig;
}

- (void)_handleFailedAuthentication:(id)arg1 error:(id)arg2 responder:(id)arg3 {
	[[[[[RSCore sharedInstance] lockScreenController] view] passcodeKeyboard] handleFailedAuthentication];
	%orig;
}

%end	// %hook SBFUserAuthenticationController

%hook SBApplication

- (void)setBadge:(id)arg1 {
	%orig(arg1);
	
	[[[[[RSCore sharedInstance] lockScreenController] view] notificationArea] setBadgeForApp:[self bundleIdentifier] value:[arg1 intValue]];
}

%end	// %hook SBApplication

%hook BBServer

- (void)_addBulletin:(BBBulletin*)arg1 {
	%orig;
	
	[[[[[RSCore sharedInstance] lockScreenController] view] notificationArea] setCurrentBulletin:arg1];
}

- (void)_removeBulletin:(BBBulletin*)arg1 rescheduleTimerIfAffected:(BOOL)arg2 shouldSync:(BOOL)arg3 {
	%orig;
	
	if (arg1 == [[[[[RSCore sharedInstance] lockScreenController] view] notificationArea] currentBulletin]) {
		[[[[[RSCore sharedInstance] lockScreenController] view] notificationArea] setCurrentBulletin:nil];
	}
}

%end	// %hook BBServer

%end	// %group lockscreen_general

%ctor {
	if ([[[RSPreferences preferences] objectForKey:@"enabled"] boolValue] && [[[RSPreferences preferences] objectForKey:@"lockScreenEnabled"] boolValue]) {
		
		if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_9_x_Max) {
			%init(lockscreen_ios10);
		} else {
			%init(lockscreen_ios9);
		}
		
		%init(lockscreen_general);
	}
}
