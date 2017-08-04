#import "../Redstone.h"

@implementation RSCore

static RSCore* sharedInstance;

+ (id)sharedInstance {
	return sharedInstance;
}

+ (void)hideAllExcept:(id)objectToShow {
	for (UIView* view in [[[objc_getClass("SBUIController") sharedInstance] window] subviews]) {
		if ([view isKindOfClass:NSClassFromString(@"SBHostWrapperView")]) {
			[view setHidden:NO];
		} else if (view != objectToShow) {
			[view setHidden:YES];
		}
	}
	
	if (objectToShow) {
		[objectToShow setHidden:NO];
	}
}

+ (void)showAllExcept:(id)objectToHide {
	for (UIView* view in [[[objc_getClass("SBUIController") sharedInstance] window] subviews]) {
		[view setHidden:(view == objectToHide)];
	}
	
	if (objectToHide) {
		[objectToHide setHidden:YES];
	}
}

- (id)initWithWindow:(UIWindow*)window {
	if (self = [super init]) {
		sharedInstance = self;
		
		_window = window;
		
		if ([[[RSPreferences preferences] objectForKey:@"homeScreenEnabled"] boolValue]) {
			homeScreenController = [RSHomeScreenController new];
			[_window addSubview:homeScreenController.view];
		
			[[self class] hideAllExcept:homeScreenController.view];
		}
	}
	
	return self;
}

@end