#import <UIKit/UIKit.h>

#define PreferencesChangedNotification "com.mathieubolard.killbackground.prefs"
#define PreferencesFilePath [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.mathieubolard.killbackgroundpreferences.plist"]

static NSDictionary *preferences = nil;

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[preferences release];
	preferences = [[NSDictionary alloc] initWithContentsOfFile:PreferencesFilePath];
}

@interface SBAppSliderController
@property(readonly, nonatomic) NSArray *applicationList;
+ (BOOL)_shouldUseSerialSnapshotQueue;
+ (BOOL)shouldProvideSnapshotIfPossible;
- (void)_quitAppAtIndex:(unsigned int)index;
- (void)forceDismissAnimated:(BOOL)animated;

- (void)killApps;
- (UIButton *)killButtonInFrame:(CGSize)frame isLeft:(BOOL)isLeft;
- (void)showBigButtonsInView:(UIView *)view;
- (void)killBackgroundAppsFromSlider:(SBAppSliderController *)controller applicationList:(NSArray *)list;
- (void)clearSwitcherBar:(UIView *)containerView;
- (void)sliderScroller:(id)arg1 itemTapped:(unsigned int)arg2;
@end

@interface SBControlCenterButton
@property(copy, nonatomic) NSNumber *sortKey;
@property(copy, nonatomic) NSString *identifier;
@end

@interface SBMediaController
+ (id)sharedInstance;
- (id)nowPlayingApplication;
- (BOOL)isPlaying;
@end

@interface SBApplication
- (id)bundleIdentifier;
@end

%hook SBAppSliderController

- (void)switcherWasPresented:(BOOL)arg1
{
	%orig;

	UIView *containerView = MSHookIvar<UIView *>(self, "_containerView");
	[self clearSwitcherBar:containerView];
	
	BOOL bigButtons = [[preferences objectForKey:@"BigButtons"] boolValue];
	// Add button
	if (bigButtons) {
		[self showBigButtonsInView:containerView];
	} else {
		BOOL isLeft = [[preferences objectForKey:@"Left"] boolValue];
		CGSize barSize = containerView.frame.size;
		UIButton *btn = [self killButtonInFrame:barSize isLeft:isLeft];
		[containerView addSubview:btn];
	}
}

-(void)sliderScroller:(id)scroller itemTapped:(unsigned)tapped
{
	UIView *containerView = MSHookIvar<UIView *>(self, "_containerView");
	[self clearSwitcherBar:containerView];

	%orig;
}

%new(v@:)
- (void)killApps
{
	[self killBackgroundAppsFromSlider:(SBAppSliderController *)self applicationList:self.applicationList];

	[self forceDismissAnimated:YES];
}

%new(v@:@@)
- (UIButton *)killButtonInFrame:(CGSize)frame isLeft:(BOOL)isLeft
{
	// Create button
	UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
	btn.autoresizingMask = isLeft ? (UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin) : (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin);
	[btn setImage:[UIImage imageWithContentsOfFile:@"/System/Library/CoreServices/SpringBoard.app/Kill-Badge.png"] forState:UIControlStateNormal];
	btn.frame = isLeft ? CGRectMake(0.0, frame.height-31.0, 29.0, 31.0) : CGRectMake(frame.width-29.0, frame.height-31.0, 29.0, 31.0);
	[btn addTarget:self action:@selector(killApps) forControlEvents:UIControlEventTouchUpInside];
	return btn;
}

%new(v@:@@)
- (void)showBigButtonsInView:(UIView *)view
{
	CGSize frame = view.frame.size;
	UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	leftBtn.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
	[leftBtn setImage:[UIImage imageWithContentsOfFile:@"/System/Library/CoreServices/SpringBoard.app/Kill-Left.png"] forState:UIControlStateNormal];
	leftBtn.frame = CGRectMake(0.0, frame.height-40.0, 40.0, 40.0);
	[leftBtn addTarget:self action:@selector(killApps) forControlEvents:UIControlEventTouchUpInside];
	[view addSubview:leftBtn];
	
	UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	rightBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
	[rightBtn setImage:[UIImage imageWithContentsOfFile:@"/System/Library/CoreServices/SpringBoard.app/Kill-Right.png"] forState:UIControlStateNormal];
	rightBtn.frame = CGRectMake(frame.width-40.0, frame.height-40.0, 40.0, 40.0);
	[rightBtn addTarget:self action:@selector(killApps) forControlEvents:UIControlEventTouchUpInside];
	[view addSubview:rightBtn];
}

%new(v@:@@)
- (void)killBackgroundAppsFromSlider:(SBAppSliderController *)sliderController applicationList:(NSArray *)applications
{
	BOOL killMusic = [[preferences objectForKey:@"KillMusic"] boolValue];

	SBMediaController *mediaController = [%c(SBMediaController) sharedInstance];
	BOOL isPlaying = [mediaController isPlaying];

	NSString *playingID = @"";
	SBApplication *nowPlayingApplication = [mediaController nowPlayingApplication];
	playingID = [nowPlayingApplication bundleIdentifier];

	BOOL shouldKillMusic = NO;
	int count = 0;
	for (id application in applications) {
		if ([application isEqualToString:@"com.apple.springboard"]) continue;
		else if (!killMusic && isPlaying && [application isEqualToString:playingID]) {
			shouldKillMusic = YES;
		} else {
			if (!shouldKillMusic) {
				[sliderController _quitAppAtIndex:1];
			} else {
				if (count+1 < applications.count) {
					[sliderController _quitAppAtIndex:2];
				}
			}
		}
		count++;
	}
}

%new(v@:@@)
- (void)clearSwitcherBar:(UIView *)containerView
{
	for (id subview in [containerView subviews]) {
		if ([subview isKindOfClass:[UIButton class]]) {
			[subview removeFromSuperview];
		}
	}
}
%end

__attribute__((constructor)) static void killbackground_init() {
	
	@autoreleasepool {
		%init;
		preferences = [[NSDictionary alloc] initWithContentsOfFile:PreferencesFilePath];
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	}
}
