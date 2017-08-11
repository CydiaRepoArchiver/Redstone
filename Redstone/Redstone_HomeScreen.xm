#import "Redstone.h"

%group homescreen

UIView* mainDisplaySceneLayoutView;
BOOL switcherIsOpen;
static BOOL hasBeenUnlockedBefore;

void playApplicationZoomAnimation(int direction, void (^callback)()) {
	RSHomeScreenController* homeScreenController = [[RSCore sharedInstance] homeScreenController];
	RSStartScreenController* startScreenController = [homeScreenController startScreenController];
	//RSAppListController* appListController = [homeScreenController appListController];
	RSLaunchScreenController* launchScreenController = [homeScreenController launchScreenController];
	
	if (direction == 0) {
		// Home Screen to App
		
		CGFloat delay = [homeScreenController launchApplication];
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay+0.31 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[launchScreenController animateIn];
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[homeScreenController setContentOffset:CGPointZero];
				[startScreenController setContentOffset:CGPointMake(0, -24)];
			});
			
			callback();
		});
	} else if (direction == 1) {
		// App to Home Screeen
		
		if ([launchScreenController launchIdentifier] != nil && ![launchScreenController isUnlocking]) {
			[launchScreenController animateCurrentApplicationSnapshot];
			[startScreenController setTilesHidden:YES];
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[RSAnimation startScreenAnimateIn];
				
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					[launchScreenController setLaunchIdentifier:nil];
				});
				
				callback();
			});
		} else {
			if (hasBeenUnlockedBefore) {
				//[[RSHomeScreenController sharedInstance] deviceHasBeenUnlocked];
			} else {
				hasBeenUnlockedBefore = YES;
				
				[RSAnimation startScreenAnimateIn];
			}
			
			callback();
		}
	
		[launchScreenController setIsUnlocking:NO];
	}
}

// iOS 10
%hook SBUIAnimationZoomApp

- (void)__startAnimation {
	playApplicationZoomAnimation([self zoomDirection], ^{
		%orig;
	});
}

%end // %hook SBUIAnimationZoomApp

%hook SBLockScreenManager

-(BOOL)_finishUIUnlockFromSource:(int)arg1 withOptions:(id)arg2 {
	//[[RSStartScreenController sharedInstance] setTilesVisible:NO];
	
	id frontApp = [(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication];
	
	if (frontApp == nil) {
		[[[[RSCore sharedInstance] homeScreenController] launchScreenController] setIsUnlocking:YES];
	}
	
	return %orig;
}

%end // %hook SBLockScreenManager

%hook SpringBoard

- (long long) homeScreenRotationStyle {
	return 0;
}

- (void)frontDisplayDidChange:(id)arg1 {
	%orig(arg1);
	
	//[[RSCore sharedInstance] frontDisplayDidChange:arg1];
}

%end // %hook SpringBoard

%hook SBHomeScreenViewController

- (NSInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)arg1 {
	return YES;
}

%end // %hook SBHomeScreenViewController

%hook SBMainDisplaySceneLayoutViewController

- (void)loadView {
	%orig;
	
	mainDisplaySceneLayoutView = self.view;
}

- (void)viewDidLoad {
	%orig;
	
	[self.view setUserInteractionEnabled:NO];
}

- (void)viewDidLayoutSubviews {
	%orig;
	
	if (switcherIsOpen) {
		[self.view setUserInteractionEnabled:YES];
	} else {
		[self.view setUserInteractionEnabled:NO];
	}
}

%end // %hook SBMainDisplaySceneLayoutViewController

%hook SBDeckSwitcherViewController

- (void)viewWillAppear:(BOOL)arg1 {
	%log;
	
	switcherIsOpen = YES;
	[mainDisplaySceneLayoutView setUserInteractionEnabled:YES];
	
	%orig;
}

- (void)viewWillDisappear:(BOOL)arg1 {
	%log;
	
	switcherIsOpen = NO;
	[mainDisplaySceneLayoutView setUserInteractionEnabled:NO];
	
	%orig;
}

%end // %hook SBDeckSwitcherViewController

%end // %group homescreen

%ctor {
	if ([[[RSPreferences preferences] objectForKey:@"homeScreenEnabled"] boolValue]) {
		%init(homescreen);
	}
}
