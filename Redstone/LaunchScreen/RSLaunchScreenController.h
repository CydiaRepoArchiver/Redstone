#import <UIKit/UIKit.h>

@interface RSLaunchScreenController : NSObject {
	UIImageView* launchImageView;
	UIImageView* applicationSnapshot;
	
	NSTimer* rootTimeout;
}

@property (nonatomic, strong) UIWindow* window;
@property (nonatomic, strong) NSString* launchIdentifier;
@property (nonatomic, assign, readonly) BOOL isLaunchingApp;
@property (nonatomic, assign) BOOL isUnlocking;

- (void)animateIn;
- (void)animateCurrentApplicationSnapshot;

@end
