#import "Redstone.h"

@implementation RSVolumeView

- (id)initWithFrame:(CGRect)frame forCategory:(NSString*)_category {
	if (self = [super initWithFrame:frame]) {
		category = _category;
		
		categoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, screenWidth-20, 20)];
		[categoryLabel setFont:[UIFont fontWithName:@"SegoeUI" size:15]];
		[categoryLabel setTextColor:[UIColor whiteColor]];
		[self addSubview:categoryLabel];
		
		self.slider = [[RSSlider alloc] initWithFrame:CGRectMake(56, 37, frame.size.width - 112, 24)];
		[self addSubview:self.slider];
		
		volumeValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - 46, 31, 36, 36)];
		[volumeValueLabel setFont:[UIFont fontWithName:@"SegoeUI-Light" size:30]];
		[volumeValueLabel setTextAlignment:NSTextAlignmentCenter];
		[volumeValueLabel setTextColor:[UIColor whiteColor]];
		[volumeValueLabel setText:@"--"];
		[self addSubview:volumeValueLabel];
		
		[self updateVolumeDisplay];
	}
	
	return self;
}

- (void)updateVolumeDisplay {
	if ([category isEqualToString:@"Ringtone"]) {
		[categoryLabel setText:[RSAesthetics localizedStringForKey:@"RINGER_VOLUME"]];
	} else if ([category isEqualToString:@"Audio/Video"]) {
		[categoryLabel setText:[RSAesthetics localizedStringForKey:@"MEDIA_VOLUME"]];
	} else if ([category isEqualToString:@"Headphones"]) {
		[categoryLabel setText:[RSAesthetics localizedStringForKey:@"HEADPHONE_VOLUME"]];
	}
}

- (void)setVolumeValue:(float)volumeValue {
	[volumeValueLabel setText:[NSString stringWithFormat:@"%02.00f", volumeValue * 16.0]];
}

@end
