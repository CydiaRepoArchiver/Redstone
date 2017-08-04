#import "../Redstone.h"

@implementation RSHomeScreenController

- (id)init {
	if (self = [super init]) {
		self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
		
		wallpaperView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
		[self.view addSubview:wallpaperView];
		
		homeScreenScrollView = [[RSHomeScreenScrollView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
		[self.view addSubview:homeScreenScrollView];
		
		startScreenController = [RSStartScreenController new];
		[homeScreenScrollView addSubview:startScreenController.view];
		
		appListController = [RSAppListController new];
		[homeScreenScrollView addSubview:appListController.view];
		
		UILongPressGestureRecognizer* longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(test)];
		[self.view addGestureRecognizer:longPressGesture];
	}
	return self;
}

- (void)test {
	[RSCore showAllExcept:self.view];
}

@end