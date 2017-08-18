#import "Redstone.h"

@implementation RSTile

- (id)initWithFrame:(CGRect)frame size:(int)size bundleIdentifier:(NSString *)bundleIdentifier {
	if (self = [super initWithFrame:frame]) {
		self.size = size;
		self.icon = [[(SBIconController*)[objc_getClass("SBIconController") sharedInstance] model] leafIconForIdentifier:bundleIdentifier];
		self.tileInfo = [[RSTileInfo alloc] initWithBundleIdentifier:bundleIdentifier];
		self.originalCenter = self.center;
		
		[self setBackgroundColor:[RSAesthetics accentColorForTile:self.tileInfo]];
		
		// Tile Icon
		
		if (self.tileInfo.fullSizeArtwork) {} else {
			CGSize tileImageSize = [RSMetrics tileIconDimensionsForSize:size];
			tileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, tileImageSize.width, tileImageSize.height)];
			[tileImageView setCenter:CGPointMake(frame.size.width/2, frame.size.height/2)];
			[tileImageView setImage:[RSAesthetics imageForTileWithBundleIdentifier:[self.icon applicationBundleID] size:self.size colored:self.tileInfo.hasColoredIcon]];
			[tileImageView setTintColor:[UIColor whiteColor]];
			[self addSubview:tileImageView];
		}
		
		// Tile Label
		
		tileLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, frame.size.height-28, frame.size.width-16, 20)];
		[tileLabel setFont:[UIFont fontWithName:@"SegoeUI" size:14]];
		[tileLabel setTextAlignment:NSTextAlignmentLeft];
		[tileLabel setTextColor:[UIColor whiteColor]];
		
		if (self.tileInfo.localizedDisplayName) {
			[tileLabel setText:self.tileInfo.localizedDisplayName];
		} else if (self.tileInfo.displayName) {
			[tileLabel setText:self.tileInfo.displayName];
		} else {
			[tileLabel setText:[self.icon displayName]];
		}
		
		[self addSubview:tileLabel];
		
		if (self.size < 2 || self.tileInfo.tileHidesLabel || [[self.tileInfo.labelHiddenForSizes objectForKey:[[NSNumber numberWithInt:self.size] stringValue]] boolValue]) {
			[tileLabel setHidden:YES];
		}
		
		// Badge
		if (self.tileInfo.usesCornerBadge || [[self.tileInfo.cornerBadgeForSizes objectForKey:[[NSNumber numberWithInt:self.size] stringValue]] boolValue]) {
			badgeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
			[badgeLabel setFont:[UIFont fontWithName:@"SegoeUI" size:14]];
			[badgeLabel setTextColor:[UIColor whiteColor]];
			[badgeLabel setBaselineAdjustment:UIBaselineAdjustmentAlignCenters];
			[badgeLabel setLayoutMargins:UIEdgeInsetsZero];
			[badgeLabel setHidden:YES];
		} else {
			badgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
			[badgeLabel setFont:[UIFont fontWithName:@"SegoeUI" size:36]];
			[badgeLabel setTextColor:[UIColor whiteColor]];
			[badgeLabel setTextAlignment:NSTextAlignmentCenter];
			[badgeLabel setAdjustsFontSizeToFitWidth:YES];
			[badgeLabel setBaselineAdjustment:UIBaselineAdjustmentAlignCenters];
			[badgeLabel setLayoutMargins:UIEdgeInsetsZero];
			[badgeLabel setHidden:YES];
		}
		[self addSubview:badgeLabel];
		
		if ([[self.icon application] badgeNumberOrString] != nil) {
			[self setBadge:[[[self.icon application] badgeNumberOrString] intValue]];
		}
	
		// Gesture Recognizers
		
		longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(pressed:)];
		[longPressGestureRecognizer setMinimumPressDuration:0.5];
		[longPressGestureRecognizer setCancelsTouchesInView:NO];
		[longPressGestureRecognizer setDelaysTouchesBegan:NO];
		[longPressGestureRecognizer setDelegate:self];
		[self addGestureRecognizer:longPressGestureRecognizer];
		
		panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panMoved:)];
		[panGestureRecognizer setDelegate:self];
		[panGestureRecognizer setCancelsTouchesInView:NO];
		[panGestureRecognizer setDelaysTouchesBegan:NO];
		[self addGestureRecognizer:panGestureRecognizer];
		
		tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
		[tapGestureRecognizer setCancelsTouchesInView:NO];
		[tapGestureRecognizer setDelaysTouchesBegan:NO];
		[tapGestureRecognizer requireGestureRecognizerToFail:panGestureRecognizer];
		[tapGestureRecognizer requireGestureRecognizerToFail:longPressGestureRecognizer];
		[self addGestureRecognizer:tapGestureRecognizer];
		
		// Editing Mode Buttons
		
		unpinButton = [[RSTileButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30) title:@"\uE77A" target:self action:@selector(unpin)];
		[unpinButton setCenter:CGPointMake(frame.size.width, 0)];
		[unpinButton setHidden:YES];
		[self addSubview:unpinButton];
		
		resizeButton = [[RSTileButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30) title:@"\uE7EA" target:self action:@selector(setNextSize)];
		[resizeButton setCenter:CGPointMake(frame.size.width, frame.size.height)];
		[resizeButton setTransform:CGAffineTransformMakeRotation(deg2rad([self scaleButtonRotationForCurrentSize]))];
		[resizeButton setHidden:YES];
		
		if (self.tileInfo.supportedSizes.count > 1) {
			[self addSubview:resizeButton];
		}
	}
	
	return self;
}

- (CGRect)basePosition {
	return CGRectMake(self.center.x - (self.bounds.size.width/2),
					  self.center.y - (self.bounds.size.height/2),
					  self.bounds.size.width,
					  self.bounds.size.height);
}

#pragma mark Gesture Recognizers

- (void)pressed:(UILongPressGestureRecognizer*)sender {
	panEnabled = NO;
	
	if (![[[[RSCore sharedInstance] homeScreenController] startScreenController] isEditing]) {
		[longPressGestureRecognizer setEnabled:NO];
		
		[tapGestureRecognizer setEnabled:NO];
		[tapGestureRecognizer setEnabled:YES];
		
		[[[[RSCore sharedInstance] homeScreenController] startScreenController] setIsEditing:YES];
		[[[[RSCore sharedInstance] homeScreenController] startScreenController] setSelectedTile:self];
	}
}

- (void)panMoved:(UIPanGestureRecognizer*)sender {
	CGPoint touchLocation = [sender locationInView:self.superview];
	
	if (sender.state == UIGestureRecognizerStateBegan) {
		[[[[RSCore sharedInstance] homeScreenController] startScreenController] setSelectedTile:self];
		
		CGPoint relativePosition = [self.superview convertPoint:self.center toView:self.superview];
		centerOffset = CGPointMake(relativePosition.x - touchLocation.x, relativePosition.y - touchLocation.y);
		
		[unpinButton setHidden:YES];
		[resizeButton setHidden:YES];
	}
	
	if (sender.state == UIGestureRecognizerStateChanged && panEnabled) {
		self.center = CGPointMake(touchLocation.x + centerOffset.x, touchLocation.y + centerOffset.y);
	}
	
	if (sender.state == UIGestureRecognizerStateEnded && panEnabled) {
		centerOffset = CGPointZero;
		
		[unpinButton setHidden:NO];
		[resizeButton setHidden:NO];
		
		[[[[RSCore sharedInstance] homeScreenController] startScreenController] snapTile:self withTouchPosition:self.center];
	}
}

- (void)tapped:(UITapGestureRecognizer*)sender {
	if ([[[[RSCore sharedInstance] homeScreenController] startScreenController] isEditing]) {
		if ([[[[RSCore sharedInstance] homeScreenController] startScreenController] selectedTile] == self) {
			[[[[RSCore sharedInstance] homeScreenController] startScreenController] setIsEditing:NO];
		} else {
			[[[[RSCore sharedInstance] homeScreenController] startScreenController] setSelectedTile:self];
		}
	} else {
		[[[[RSCore sharedInstance] homeScreenController] launchScreenController] setLaunchIdentifier:self.icon.applicationBundleID];
		[[objc_getClass("SBIconController") sharedInstance] _launchIcon:self.icon];
	}
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	if (self.isSelectedTile) {
		if (CGRectContainsPoint(unpinButton.frame, point)) {
			[tapGestureRecognizer setEnabled:NO];
			[panGestureRecognizer setEnabled:NO];
			
			return unpinButton;
		} else if (CGRectContainsPoint(resizeButton.frame, point)) {
			[tapGestureRecognizer setEnabled:NO];
			[panGestureRecognizer setEnabled:NO];
			
			return resizeButton;
		}
	}
	
	[tapGestureRecognizer setEnabled:YES];
	[panGestureRecognizer setEnabled:YES];
	
	return [super hitTest:point withEvent:event];
}

#pragma mark Editing Mode

- (void)setIsSelectedTile:(BOOL)isSelectedTile {
	if ([[[[RSCore sharedInstance] homeScreenController] startScreenController] isEditing]) {
		_isSelectedTile = isSelectedTile;
		
		if (isSelectedTile) {
			panEnabled = YES;

			[[RSCore.sharedInstance homeScreenController].startScreenController.view.panGestureRecognizer setEnabled:NO];
			[[RSCore.sharedInstance homeScreenController].startScreenController.view.panGestureRecognizer setEnabled:YES];
			
			[unpinButton setHidden:NO];
			[resizeButton setHidden:NO];
			
			[self.superview bringSubviewToFront:self];
			[self setAlpha:1.0];
			[self setTransform:CGAffineTransformMakeScale(1.05, 1.05)];
		} else {
			panEnabled = NO;
			
			[unpinButton setHidden:YES];
			[resizeButton setHidden:YES];
			
			[UIView animateWithDuration:.2 animations:^{
				[self setEasingFunction:easeOutQuint forKeyPath:@"frame"];
				
				[self setAlpha:0.8];
				[self setTransform:CGAffineTransformMakeScale(0.85, 0.85)];
			} completion:^(BOOL finished) {
				[self removeEasingFunctionForKeyPath:@"frame"];
			}];
		}
	} else {
		_isSelectedTile = NO;
		panEnabled = NO;
		
		[unpinButton setHidden:YES];
		[resizeButton setHidden:YES];
		
		[UIView animateWithDuration:.2 animations:^{
			[self setEasingFunction:easeOutQuint forKeyPath:@"frame"];
			
			[self setAlpha:1.0];
			[self setTransform:CGAffineTransformIdentity];
		} completion:^(BOOL finished) {
			[self removeEasingFunctionForKeyPath:@"frame"];
		}];
		
		[longPressGestureRecognizer setEnabled:YES];
	}
}

- (void)unpin {
	[[[[RSCore sharedInstance] homeScreenController] startScreenController] unpinTile:self];
}

- (void)setNextSize {
	NSArray* sizes = self.tileInfo.supportedSizes;
	int currentSize = [sizes indexOfObject:[NSNumber numberWithInt:self.size]];
	
	if (sizes.count <= 1) {
		return;
	} else if (currentSize - 1 >= 0) {
		self.size = [[sizes objectAtIndex:currentSize - 1] intValue];
	} else {
		self.size = [[sizes objectAtIndex:sizes.count - 1] intValue];
	}
	
	CGSize newTileSize = [RSMetrics tileDimensionsForSize:self.size];
	
	CGFloat step = [RSMetrics sizeForPosition];
	
	CGFloat maxPositionX = self.superview.bounds.size.width - newTileSize.width;
	CGFloat maxPositionY = [(UIScrollView*)self.superview contentSize].height + [RSMetrics tileBorderSpacing];
	
	CGRect newFrame = CGRectMake(MIN(MAX(step * roundf((self.basePosition.origin.x / step)), 0), maxPositionX),
								 MIN(MAX(step * roundf((self.basePosition.origin.y / step)), 0), maxPositionY),
								 newTileSize.width,
								 newTileSize.height);
	
	CGAffineTransform currentTransform = self.transform;
	
	[self setTransform:CGAffineTransformIdentity];
	[self setFrame:newFrame];
	[self setTransform:currentTransform];
	
	if (self.size < 2 || self.tileInfo.tileHidesLabel || [[self.tileInfo.labelHiddenForSizes objectForKey:[[NSNumber numberWithInt:self.size] stringValue]] boolValue]) {
		[tileLabel setHidden:YES];
	} else {
		[tileLabel setHidden:NO];
		[tileLabel setFrame:CGRectMake(8,
									   newFrame.size.height - tileLabel.frame.size.height - 8,
									   tileLabel.frame.size.width,
									   tileLabel.frame.size.height)];
	}
	
	if (self.tileInfo.fullSizeArtwork) {} else {
		CGSize tileImageSize = [RSMetrics tileIconDimensionsForSize:self.size];
		[tileImageView setFrame:CGRectMake(0, 0, tileImageSize.width, tileImageSize.height)];
		[tileImageView setCenter:CGPointMake(newFrame.size.width/2, newFrame.size.height/2)];
		[tileImageView setImage:[RSAesthetics imageForTileWithBundleIdentifier:[self.icon applicationBundleID] size:self.size colored:self.tileInfo.hasColoredIcon]];
		[tileImageView setTintColor:[UIColor whiteColor]];
		[self addSubview:tileImageView];
	}
	
	[unpinButton setCenter:CGPointMake(newFrame.size.width, 0)];
	[resizeButton setCenter:CGPointMake(newFrame.size.width, newFrame.size.height)];
	
	[resizeButton setTransform:CGAffineTransformMakeRotation(deg2rad([self scaleButtonRotationForCurrentSize]))];
	
	[[[[RSCore sharedInstance] homeScreenController] startScreenController] moveAffectedTilesForTile:self hasResizedTile:YES];
	//[[[[RSCore sharedInstance] homeScreenController] startScreenController] moveAffectedTilesForTile:self hasResizedTile:NO];
}

- (CGFloat)scaleButtonRotationForCurrentSize {
	switch (self.size) {
		case 1:
			return -135.0;
			break;
		case 2:
			return 45.0;
			break;
		case 3:
			return 0.0;
			break;
		case 4:
			return 90.0;
		default:
			return 0.0;
			break;
			
	}
}

#pragma mark Live Tile

- (void)setBadge:(int)badgeCount {
	badgeValue = badgeCount;
	
	if (!badgeCount || badgeCount == 0) {
		[badgeLabel setText:nil];
		[badgeLabel setHidden:YES];
		[tileImageView setCenter:CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2)];
		return;
	}
	
	if ((self.tileInfo.usesCornerBadge || [[self.tileInfo.cornerBadgeForSizes objectForKey:[[NSNumber numberWithInt:self.size] stringValue]] boolValue]) && self.size >= 2) {
		if (badgeCount > 99) {
			NSString* badgeString = @"99+";
			
			NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString:badgeString];
			[attributedString addAttributes:@{
											  NSBaselineOffsetAttributeName: @4.0
											  } range:[badgeString rangeOfString:@"+"]];
			[badgeLabel setAttributedText:attributedString];
			[badgeLabel setHidden:NO];
		} else {
			[badgeLabel setText:[NSString stringWithFormat:@"%d", badgeCount]];
		}
		
		[badgeLabel setFont:[UIFont fontWithName:@"SegoeUI" size:14]];
		[badgeLabel sizeToFit];
		[badgeLabel setFrame:CGRectMake(self.bounds.size.width - badgeLabel.frame.size.width - 8,
									self.bounds.size.height - badgeLabel.frame.size.height - 8,
									badgeLabel.frame.size.width,
									badgeLabel.frame.size.height)];
	} else {
		if (self.size < 2) {
			[badgeLabel setFont:[UIFont fontWithName:@"SegoeUI" size:20]];
		} else {
			[badgeLabel setFont:[UIFont fontWithName:@"SegoeUI" size:36]];
		}
		
		if (badgeCount > 99) {
			NSString* badgeString = @"99+";
			
			NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString:badgeString];
			
			if (self.size < 2) {
				[badgeLabel setFont:[UIFont fontWithName:@"SegoeUI" size:16]];
				
				[attributedString addAttributes:@{
												  NSBaselineOffsetAttributeName: @4.5,
												  NSFontAttributeName: [UIFont fontWithName:@"SegoeUI" size:14]
												  } range:[badgeString rangeOfString:@"+"]];
			} else {
				[attributedString addAttributes:@{
												  NSBaselineOffsetAttributeName: @10.0,
												  NSFontAttributeName: [UIFont fontWithName:@"SegoeUI" size:30]
												  } range:[badgeString rangeOfString:@"+"]];
			}
			
			[badgeLabel setAttributedText:attributedString];
			[badgeLabel setHidden:NO];
		} else {
			[badgeLabel setText:[NSString stringWithFormat:@"%d", badgeCount]];
		}
		
		[badgeLabel sizeToFit];
		
		CGSize tileImageSize = [RSMetrics tileIconDimensionsForSize:self.size];
		CGSize combinedSize = CGSizeMake(tileImageSize.width + badgeLabel.frame.size.width + 8, tileImageSize.height);
		
		if (self.size < 2) {
			combinedSize = CGSizeMake(tileImageSize.width + badgeLabel.frame.size.width + 2, tileImageSize.height);
		}
		
		[tileImageView setCenter:CGPointMake(self.bounds.size.width/2 - (combinedSize.width - tileImageView.frame.size.width)/2, self.bounds.size.height/2)];
		[badgeLabel setCenter:CGPointMake(self.bounds.size.width/2 + (combinedSize.width - badgeLabel.frame.size.width)/2, self.bounds.size.height/2)];
		
		[badgeLabel setHidden:NO];
	}
}

@end
