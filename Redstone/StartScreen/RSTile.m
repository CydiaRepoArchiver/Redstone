#import "Redstone.h"

@implementation RSTile

- (id)initWithFrame:(CGRect)frame size:(int)size bundleIdentifier:(NSString *)bundleIdentifier {
	if (self = [super initWithFrame:frame]) {
		self.size = size;
		self.icon = [[(SBIconController*)[objc_getClass("SBIconController") sharedInstance] model] leafIconForIdentifier:bundleIdentifier];
		self.tileInfo = [[RSTileInfo alloc] initWithBundleIdentifier:bundleIdentifier];
		self.originalCenter = self.center;
		
		[self setBackgroundColor:[RSAesthetics accentColorForTile:self.tileInfo]];
		
		tileWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
		[tileWrapper setClipsToBounds:YES];
		[self addSubview:tileWrapper];
		
		tileContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
		[tileWrapper addSubview:tileContainer];
		
		// Tile Icon
		
		if (self.tileInfo.fullSizeArtwork) {
			tileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
			[tileImageView setImage:[RSAesthetics imageForTileWithBundleIdentifier:[self.icon applicationBundleID] size:self.size colored:YES]];
			[tileContainer addSubview:tileImageView];
		} else {
			CGSize tileImageSize = [RSMetrics tileIconDimensionsForSize:size];
			tileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, tileImageSize.width, tileImageSize.height)];
			[tileImageView setCenter:CGPointMake(frame.size.width/2, frame.size.height/2)];
			[tileImageView setImage:[RSAesthetics imageForTileWithBundleIdentifier:[self.icon applicationBundleID] size:self.size colored:self.tileInfo.hasColoredIcon]];
			[tileImageView setTintColor:[RSAesthetics readableForegroundColorForBackgroundColor:self.backgroundColor]];
			[tileContainer addSubview:tileImageView];
		}
		
		// Tile Label
		
		tileLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, frame.size.height-28, frame.size.width-16, 20)];
		[tileLabel setFont:[UIFont fontWithName:@"SegoeUI" size:14]];
		[tileLabel setTextAlignment:NSTextAlignmentLeft];
		[tileLabel setTextColor:[RSAesthetics readableForegroundColorForBackgroundColor:self.backgroundColor]];
		
		if (self.tileInfo.localizedDisplayName) {
			[tileLabel setText:self.tileInfo.localizedDisplayName];
		} else if (self.tileInfo.displayName) {
			[tileLabel setText:self.tileInfo.displayName];
		} else {
			[tileLabel setText:[self.icon displayName]];
		}
		
		[tileContainer addSubview:tileLabel];
		
		if (self.size < 2 || self.tileInfo.tileHidesLabel || [[self.tileInfo.labelHiddenForSizes objectForKey:[[NSNumber numberWithInt:self.size] stringValue]] boolValue]) {
			[tileLabel setHidden:YES];
		}
		
		// Badge
		if (self.tileInfo.usesCornerBadge || [[self.tileInfo.cornerBadgeForSizes objectForKey:[[NSNumber numberWithInt:self.size] stringValue]] boolValue]) {
			badgeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
			[badgeLabel setFont:[UIFont fontWithName:@"SegoeUI" size:14]];
			[badgeLabel setTextColor:[RSAesthetics readableForegroundColorForBackgroundColor:self.backgroundColor]];
			[badgeLabel setBaselineAdjustment:UIBaselineAdjustmentAlignCenters];
			[badgeLabel setLayoutMargins:UIEdgeInsetsZero];
			[badgeLabel setHidden:YES];
		} else {
			badgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
			[badgeLabel setFont:[UIFont fontWithName:@"SegoeUI" size:36]];
			[badgeLabel setTextColor:[RSAesthetics readableForegroundColorForBackgroundColor:self.backgroundColor]];
			[badgeLabel setTextAlignment:NSTextAlignmentCenter];
			[badgeLabel setAdjustsFontSizeToFitWidth:YES];
			[badgeLabel setBaselineAdjustment:UIBaselineAdjustmentAlignCenters];
			[badgeLabel setLayoutMargins:UIEdgeInsetsZero];
			[badgeLabel setHidden:YES];
		}
		[tileContainer addSubview:badgeLabel];
		
		if ([[self.icon application] badgeNumberOrString] != nil) {
			[self setBadge:[[[self.icon application] badgeNumberOrString] intValue]];
		}
		
		// Live Tile
		if ([[[RSPreferences preferences] objectForKey:@"liveTilesEnabled"] boolValue]) {
			liveTileBundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/Live Tiles/%@.tile", RESOURCES_PATH, bundleIdentifier]];
			if (liveTileBundle) {
				liveTile = [[[liveTileBundle principalClass] alloc] initWithFrame:CGRectMake(0, frame.size.height, frame.size.width, frame.size.height) tile:self];
			}
			if (liveTile) {
				[liveTile setClipsToBounds:YES];
				[tileWrapper addSubview:liveTile];
			}
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

- (void)removeFromSuperview {
	[self stopLiveTile];
	
	if ([liveTile respondsToSelector:@selector(prepareForRemoval)]) {
		[liveTile prepareForRemoval];
	}
	
	liveTile.tile = nil;
	liveTile = nil;
	[super removeFromSuperview];
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
		self.icon = [[(SBIconController*)[objc_getClass("SBIconController") sharedInstance] model] leafIconForIdentifier:self.icon.applicationBundleID];
		[[[[RSCore sharedInstance] homeScreenController] launchScreenController] setLaunchIdentifier:self.icon.applicationBundleID];
		[[[[RSCore sharedInstance] homeScreenController] launchScreenController] setIsUnlocking:NO];
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
	
	[tileWrapper setFrame:CGRectMake(0, 0, newFrame.size.width, newFrame.size.height)];
	
	if (liveTile) {
		[tileContainer setFrame:CGRectMake(0, tileContainer.frame.origin.y, self.bounds.size.width, self.bounds.size.height)];
		[liveTile setFrame:CGRectMake(0, liveTile.frame.origin.y, self.bounds.size.width, self.bounds.size.height)];
		
//		if ([liveTile isKindOfClass:[RSTileNotificationView class]]) {
//			[self setLiveTileHidden:(self.size < 2 || ![liveTile readyForDisplay])];
//		} else {
			[self startLiveTile];
//		}
	}
	
	if (self.size < 2 || self.tileInfo.tileHidesLabel || [[self.tileInfo.labelHiddenForSizes objectForKey:[[NSNumber numberWithInt:self.size] stringValue]] boolValue]) {
		[tileLabel setHidden:YES];
	} else {
		[tileLabel setHidden:NO];
		[tileLabel setFrame:CGRectMake(8,
									   newFrame.size.height - tileLabel.frame.size.height - 8,
									   tileLabel.frame.size.width,
									   tileLabel.frame.size.height)];
	}
	
	if (self.tileInfo.fullSizeArtwork) {
		[tileImageView setFrame:CGRectMake(0, 0, newFrame.size.width, newFrame.size.height)];
		[tileImageView setImage:[RSAesthetics imageForTileWithBundleIdentifier:[self.icon applicationBundleID] size:self.size colored:YES]];
	} else {
		CGSize tileImageSize = [RSMetrics tileIconDimensionsForSize:self.size];
		[tileImageView setFrame:CGRectMake(0, 0, tileImageSize.width, tileImageSize.height)];
		[tileImageView setCenter:CGPointMake(newFrame.size.width/2, newFrame.size.height/2)];
		[tileImageView setImage:[RSAesthetics imageForTileWithBundleIdentifier:[self.icon applicationBundleID] size:self.size colored:self.tileInfo.hasColoredIcon]];
		[tileImageView setTintColor:[RSAesthetics readableForegroundColorForBackgroundColor:self.backgroundColor]];
	}
	
	[self setBadge:badgeValue];
	
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
	
	if (!badgeCount || badgeCount < 1) {
		[badgeLabel setText:nil];
		[badgeLabel setHidden:YES];
		[tileImageView setCenter:CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2)];
		return;
	}
	
	if ((self.tileInfo.usesCornerBadge || [[self.tileInfo.cornerBadgeForSizes objectForKey:[[NSNumber numberWithInt:self.size] stringValue]] boolValue]) && self.size >= 2) {
		if (badgeCount > 99) {
			NSString* badgeString = @"99+";
			
			NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString:badgeString];
			[attributedString addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:4.0] range:[badgeString rangeOfString:@"+"]];
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
				
				[attributedString addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:4.5] range:[badgeString rangeOfString:@"+"]];
				[attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"SegoeUI" size:14] range:[badgeString rangeOfString:@"+"]];
			} else {
				[attributedString addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:10.0] range:[badgeString rangeOfString:@"+"]];
				[attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"SegoeUI" size:30] range:[badgeString rangeOfString:@"+"]];
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

- (void)startLiveTile {
	if (!liveTile) {
		return;
	}
	
	if (liveTileUpdateTimer) {
		[liveTileUpdateTimer invalidate];
		liveTileUpdateTimer = nil;
	}
	
	if (liveTileAnimationTimer) {
		[liveTileAnimationTimer invalidate];
		liveTileAnimationTimer = nil;
	}
	
	if ([liveTile respondsToSelector:@selector(hasStarted)]) {
		[liveTile hasStarted];
	}
	
	if ([liveTile isReadyForDisplay]) {
//		if ([liveTile isKindOfClass:[RSTileNotificationView class]] && self.size < 2) {
//			[self setLiveTileHidden:YES];
//		} else {
			[self setLiveTileHidden:NO];
//		}
	}
	
	if ([liveTile updateInterval] > 0 && [liveTile respondsToSelector:@selector(update)]) {
		liveTileUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:[liveTile updateInterval] target:liveTile selector:@selector(update) userInfo:nil repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:liveTileUpdateTimer forMode:NSRunLoopCommonModes];
	}
	
	NSArray* viewsForSize = [liveTile viewsForSize:self.size];
	if (viewsForSize != nil && viewsForSize.count > 0) {
		[[liveTile subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
		for (int i=0; i<viewsForSize.count; i++) {
			[[viewsForSize objectAtIndex:i] setFrame:CGRectMake(0, (i > 0) ? self.bounds.size.height : 0, self.bounds.size.width, self.bounds.size.height)];
			[liveTile addSubview:[viewsForSize objectAtIndex:i]];
		}
	}
	
	liveTilePageIndex = 0;
	if (viewsForSize.count > 1 || [liveTile respondsToSelector:@selector(triggerAnimation)]) {
		for (int i=0; i<viewsForSize.count; i++) {
			[[viewsForSize objectAtIndex:i] setFrame:CGRectMake(0, (i > 0) ? self.bounds.size.height : 0, self.bounds.size.width, self.bounds.size.height)];
		}
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((arc4random_uniform(4) * 0.5)  * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			liveTileAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:6.0 target:self selector:@selector(displayNextLiveTilePage) userInfo:nil repeats:YES];
			[[NSRunLoop mainRunLoop] addTimer:liveTileAnimationTimer forMode:NSRunLoopCommonModes];
		});
	}
}

- (void)stopLiveTile {
	if (liveTileUpdateTimer) {
		[liveTileUpdateTimer invalidate];
		liveTileUpdateTimer = nil;
	}
	
	if (liveTileAnimationTimer) {
		[liveTileAnimationTimer invalidate];
		liveTileAnimationTimer = nil;
	}
	
	[self setLiveTileHidden:YES];
	
	if ([liveTile respondsToSelector:@selector(hasStopped)]) {
		[liveTile hasStopped];
	}
}

- (void)setLiveTileHidden:(BOOL)hidden {
	if (!liveTile) {
		return;
	}
	
	if (!hidden) {
		if ([liveTile started]) {
			return;
		}
		[liveTile setStarted:YES];
		
		[tileContainer setFrame:CGRectMake(0, -self.bounds.size.height, self.bounds.size.width, self.bounds.size.height)];
		[liveTile setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
		[tileContainer setHidden:YES];
	} else {
		if (![liveTile started]) {
			return;
		}
		[liveTile setStarted:NO];
		
		[tileContainer setHidden:NO];
		[tileContainer setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
		[liveTile setFrame:CGRectMake(0, self.bounds.size.height, self.bounds.size.width, self.bounds.size.height)];
	}
}

- (void)setLiveTileHidden:(BOOL)hidden animated:(BOOL)animated {
	if (!liveTile) {
		return;
	}
	
	if (!animated) {
		[self setLiveTileHidden:hidden];
	} else {
		if (!hidden) {
			if ([liveTile started]) {
				return;
			}
			[liveTile setStarted:YES];
			
			[tileContainer setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
			[liveTile setFrame:CGRectMake(0, self.bounds.size.height, self.bounds.size.width, self.bounds.size.height)];
			
			[UIView animateWithDuration:1.0 animations:^{
				[tileContainer setEasingFunction:easeOutQuint forKeyPath:@"frame"];
				[liveTile setEasingFunction:easeOutQuint forKeyPath:@"frame"];
				
				[tileContainer setFrame:CGRectMake(0, -self.bounds.size.height, self.bounds.size.width, self.bounds.size.height)];
				[liveTile setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
			} completion:^(BOOL finished){
				[tileContainer removeEasingFunctionForKeyPath:@"frame"];
				[liveTile removeEasingFunctionForKeyPath:@"frame"];
				
				[tileContainer setHidden:YES];
			}];
		} else {
			if (![liveTile started]) {
				return;
			}
			[liveTile setStarted:NO];
			
			[tileContainer setHidden:NO];
			[tileContainer setFrame:CGRectMake(0, -self.bounds.size.height, self.bounds.size.width, self.bounds.size.height)];
			[liveTile setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
			
			[UIView animateWithDuration:1.0 animations:^{
				[tileContainer setEasingFunction:easeOutQuint forKeyPath:@"frame"];
				[liveTile setEasingFunction:easeOutQuint forKeyPath:@"frame"];
				
				[tileContainer setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
				[liveTile setFrame:CGRectMake(0, self.bounds.size.height, self.bounds.size.width, self.bounds.size.height)];
			} completion:^(BOOL finished){
				[tileContainer removeEasingFunctionForKeyPath:@"frame"];
				[liveTile removeEasingFunctionForKeyPath:@"frame"];
			}];
		}
	}
}

- (void)displayNextLiveTilePage {
	if ([[objc_getClass("SBUserAgent") sharedUserAgent] deviceIsLocked]) {
		[self stopLiveTile];
		return;
	}
	
	if ([liveTile respondsToSelector:@selector(triggerAnimation)]) {
		[liveTile triggerAnimation];
		return;
	}
	
	NSArray* viewsForCurrentSize = [liveTile viewsForSize:self.size];
	UIView* currentPage = [viewsForCurrentSize objectAtIndex:liveTilePageIndex];
	UIView* nextPage = [viewsForCurrentSize objectAtIndex:(liveTilePageIndex+1 >= liveTile.subviews.count) ? 0 : liveTilePageIndex+1];
	
	[currentPage setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
	[nextPage setFrame:CGRectMake(0, self.bounds.size.height, self.bounds.size.width, self.bounds.size.height)];
	
	[UIView animateWithDuration:1.0 animations:^{
		[currentPage setEasingFunction:easeOutQuint forKeyPath:@"frame"];
		[nextPage setEasingFunction:easeOutQuint forKeyPath:@"frame"];
		
		[currentPage setFrame:CGRectMake(0, -self.bounds.size.height, self.bounds.size.width, self.bounds.size.height)];
		[nextPage setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
	} completion:^(BOOL finished){
		[currentPage removeEasingFunctionForKeyPath:@"frame"];
		[nextPage removeEasingFunctionForKeyPath:@"frame"];
		
		[currentPage setFrame:CGRectMake(0, self.bounds.size.height, self.bounds.size.width, self.bounds.size.height)];
	}];
	
	liveTilePageIndex++;
	if (liveTilePageIndex >= liveTile.subviews.count) {
		liveTilePageIndex = 0;
	}
}

@end
