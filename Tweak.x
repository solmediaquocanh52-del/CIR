#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>
#import <math.h>

// ============================================================================
// CircleSwitcher v2.0.0 — Core SpringBoard Engine (iOS 14.0 - 16.3.1+ Rootless & Rootful)
// Integrates 3D Circular Wheel + Liquid Glass Specular Rim + 3D Switcher 2 Modes & Icon FX
// ============================================================================

@interface SBAppSwitcherPageView : UIView
@property (nonatomic, strong) UIView *view;
@property (nonatomic, assign) CGFloat cornerRadius;
- (void)_updateCornerRadius;
@end

@interface SBFluidSwitcherItemContainer : UIView
@property (nonatomic, strong) SBAppSwitcherPageView *pageView;
- (void)_cs_applyTransformAndGlass;
@end

@interface SBFluidSwitcherIconOverlayView : UIView
@end

@interface SBFluidSwitcherViewController : UIViewController
- (void)_cs_refreshVisibleContainers;
@end

// Preferences State
static NSString * const kCSDomain = @"com.vn.circleswitcher";
static NSString * const kCSReloadNotification = @"com.vn.circleswitcher/ReloadPrefs";

static BOOL kEnabled = YES;
static NSInteger kLayoutMode = 0;        // 0: Circle Wheel 3D, 1: 3D Cards, 2: Card Deck, 3: CoverFlow, 4: Inverse CoverFlow, 5: Subtler CoverFlow, 6: 2D Flat
static BOOL kCircleMorph = YES;
static CGFloat kCircleRadius = 110.0;
static CGFloat kWheelCurvature = 1.0;
static CGFloat kCardScale = 0.88;
static BOOL kLiquidGlass = YES;
static CGFloat kGlowIntensity = 0.45;
static NSInteger kGlowColorIndex = 0;
static BOOL kFadeIcons = YES;
static BOOL kScaleIcons = YES;
static BOOL kRollIcons = NO;
static BOOL kHapticFeedback = YES;

static __weak UIView *kLastCenteredContainer = nil;
static UIImpactFeedbackGenerator *kHapticGenerator = nil;

static UIColor *CSGlowColorForIndex(NSInteger idx, CGFloat alpha) {
    switch (idx) {
        case 1:  return [UIColor colorWithRed:0.15 green:0.55 blue:1.00 alpha:alpha]; // Royal Blue
        case 2:  return [UIColor colorWithRed:0.68 green:0.35 blue:1.00 alpha:alpha]; // Nebula Violet
        case 3:  return [UIColor colorWithRed:0.15 green:0.90 blue:0.65 alpha:alpha]; // Emerald Mint
        case 4:  return [UIColor colorWithWhite:1.00 alpha:alpha];                     // Pure Specular White
        case 0:
        default: return [UIColor colorWithRed:0.25 green:0.85 blue:1.00 alpha:alpha]; // Ice Cyan
    }
}

static NSDictionary *CSReadPreferencesDictionary(void) {
    // 1. Standard NSUserDefaults (supported via cfprefsd on both Rootless iOS 16 & Rootful iOS 14)
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kCSDomain];
    [defaults synchronize];
    NSDictionary *dict = [defaults dictionaryRepresentation];
    if (dict && dict[@"enabled"] != nil) {
        return dict;
    }

    // 2. Fallback direct plist read (Rootless /var/jb first, then Rootful /var/mobile)
    NSArray<NSString *> *paths = @[
        @"/var/jb/var/mobile/Library/Preferences/com.vn.circleswitcher.plist",
        @"/var/mobile/Library/Preferences/com.vn.circleswitcher.plist"
    ];
    for (NSString *path in paths) {
        NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:path];
        if (plist) {
            return plist;
        }
    }
    return nil;
}

static void CSLoadPreferences(void) {
    NSDictionary *prefs = CSReadPreferencesDictionary();

    kEnabled        = prefs[@"enabled"]        ? [prefs[@"enabled"] boolValue]        : YES;
    kLayoutMode     = prefs[@"layoutMode"]     ? [prefs[@"layoutMode"] integerValue]  : 0;
    kCircleMorph    = prefs[@"circleMorph"]    ? [prefs[@"circleMorph"] boolValue]    : YES;
    kCircleRadius   = prefs[@"circleRadius"]   ? [prefs[@"circleRadius"] floatValue]  : 110.0f;
    kWheelCurvature = prefs[@"wheelCurvature"] ? [prefs[@"wheelCurvature"] floatValue]: 1.0f;
    kCardScale      = prefs[@"cardScale"]      ? [prefs[@"cardScale"] floatValue]     : 0.88f;
    kLiquidGlass    = prefs[@"liquidGlass"]    ? [prefs[@"liquidGlass"] boolValue]    : YES;
    kGlowIntensity  = prefs[@"glowIntensity"]  ? [prefs[@"glowIntensity"] floatValue] : 0.45f;
    kGlowColorIndex = prefs[@"glowColorIndex"] ? [prefs[@"glowColorIndex"] integerValue] : 0;
    kFadeIcons      = prefs[@"fadeIcons"]      ? [prefs[@"fadeIcons"] boolValue]      : YES;
    kScaleIcons     = prefs[@"scaleIcons"]     ? [prefs[@"scaleIcons"] boolValue]     : YES;
    kRollIcons      = prefs[@"rollIcons"]      ? [prefs[@"rollIcons"] boolValue]      : NO;
    kHapticFeedback = prefs[@"hapticFeedback"] ? [prefs[@"hapticFeedback"] boolValue] : YES;
}

static void CSReloadCallback(CFNotificationCenterRef center,
                             void *observer,
                             CFStringRef name,
                             const void *object,
                             CFDictionaryRef userInfo) {
    CSLoadPreferences();
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CSInternalPreferencesDidUpdate" object:nil];
    });
}

// ============================================================================
// Liquid Glass & Circular Corner Styling on App Cards
// ============================================================================

%hook SBAppSwitcherPageView

- (void)layoutSubviews {
    %orig;
    if (!kEnabled) {
        self.layer.borderWidth = 0.0;
        self.layer.shadowOpacity = 0.0;
        return;
    }

    if (kCircleMorph) {
        CGFloat maxAllowed = MIN(self.bounds.size.width, self.bounds.size.height) * 0.5;
        CGFloat targetRadius = MIN(kCircleRadius, maxAllowed);
        self.layer.cornerRadius = targetRadius;
        self.layer.masksToBounds = YES;
        if (@available(iOS 13.0, *)) {
            self.layer.cornerCurve = kCACornerCurveContinuous;
        }
    }

    if (kLiquidGlass && kGlowIntensity > 0.01) {
        self.layer.borderWidth = 1.5;
        self.layer.borderColor = CSGlowColorForIndex(kGlowColorIndex, MIN(0.95, 0.35 + kGlowIntensity * 0.6)).CGColor;
    } else {
        self.layer.borderWidth = 0.0;
    }
}

- (void)_updateCornerRadius {
    %orig;
    if (kEnabled && kCircleMorph) {
        CGFloat maxAllowed = MIN(self.bounds.size.width, self.bounds.size.height) * 0.5;
        self.layer.cornerRadius = MIN(kCircleRadius, maxAllowed);
    }
}

%end

// ============================================================================
// 3D Circular Wheel & CoverFlow Transform Engine
// ============================================================================

%hook SBFluidSwitcherItemContainer

- (void)layoutSubviews {
    %orig;
    [self _cs_applyTransformAndGlass];
}

- (void)setCenter:(CGPoint)center {
    %orig;
    [self _cs_applyTransformAndGlass];
}

%new
- (void)_cs_applyTransformAndGlass {
    UIView *targetView = nil;
    if ([self respondsToSelector:@selector(pageView)] && self.pageView) {
        targetView = self.pageView;
    } else if (self.subviews.count > 0) {
        targetView = self.subviews.firstObject;
    }
    if (!targetView) return;

    if (!kEnabled) {
        targetView.layer.transform = CATransform3DIdentity;
        self.layer.shadowOpacity = 0.0;
        return;
    }

    UIWindow *win = self.window;
    CGFloat screenW = win ? win.bounds.size.width : [UIScreen mainScreen].bounds.size.width;
    if (screenW <= 0) screenW = 390.0;

    CGPoint centerInScreen = [self.superview convertPoint:self.center toView:win];
    CGFloat deltaX = centerInScreen.x - (screenW * 0.5);
    // Normalized offset: 0.0 at screen center, -1.0 left, +1.0 right
    CGFloat t = deltaX / (screenW * 0.55);
    CGFloat clampedT = MAX(-1.8, MIN(1.8, t));
    CGFloat absT = fabs(clampedT);

    // Haptic tick when a new card crosses the center deadzone
    if (kHapticFeedback && absT < 0.07 && kLastCenteredContainer != self) {
        kLastCenteredContainer = self;
        if (!kHapticGenerator) {
            kHapticGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        }
        [kHapticGenerator impactOccurred];
    }

    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0 / (920.0 / MAX(0.35, kWheelCurvature));

    CGFloat scale = kCardScale;
    CGFloat angleY = 0.0;
    CGFloat angleZ = 0.0;
    CGFloat transY = 0.0;
    CGFloat transZ = 0.0;

    switch (kLayoutMode) {
        case 0: {
            // Mode 0: Circle Wheel 3D (CircleSwitcher Signature)
            // Cards orbit along a vertical-horizontal 3D wheel arc
            angleY = -clampedT * (M_PI / 5.2) * kWheelCurvature;
            angleZ = clampedT * (M_PI / 18.0) * kWheelCurvature;
            transY = (absT * absT) * 44.0 * kWheelCurvature;
            transZ = -absT * 95.0 * kWheelCurvature;
            scale  = kCardScale * MAX(0.72, 1.0 - absT * 0.14);
            break;
        }
        case 1: {
            // Mode 1: 3D Cards (from 3D Switcher 2)
            angleY = -clampedT * (M_PI / 6.5) * kWheelCurvature;
            transZ = -absT * 60.0 * kWheelCurvature;
            scale  = kCardScale * MAX(0.78, 1.0 - absT * 0.09);
            break;
        }
        case 2: {
            // Mode 2: Card Deck (from 3D Switcher 2)
            angleY = -0.22 * kWheelCurvature;
            transZ = -absT * 110.0 * kWheelCurvature;
            transY = -absT * 14.0;
            scale  = kCardScale * MAX(0.74, 1.0 - absT * 0.11);
            break;
        }
        case 3: {
            // Mode 3: CoverFlow (from 3D Switcher 2)
            CGFloat sign = (clampedT > 0) ? 1.0 : ((clampedT < 0) ? -1.0 : 0.0);
            CGFloat flowFactor = MIN(1.0, absT * 1.4);
            angleY = -sign * flowFactor * (M_PI / 3.4) * kWheelCurvature;
            transZ = -flowFactor * 120.0 * kWheelCurvature;
            scale  = kCardScale * (1.0 - flowFactor * 0.14);
            break;
        }
        case 4: {
            // Mode 4: Inverse CoverFlow (from 3D Switcher 2)
            CGFloat sign = (clampedT > 0) ? 1.0 : ((clampedT < 0) ? -1.0 : 0.0);
            CGFloat flowFactor = MIN(1.0, absT * 1.4);
            angleY = sign * flowFactor * (M_PI / 3.4) * kWheelCurvature;
            transZ = -flowFactor * 120.0 * kWheelCurvature;
            scale  = kCardScale * (1.0 - flowFactor * 0.14);
            break;
        }
        case 5: {
            // Mode 5: Subtler CoverFlow (from 3D Switcher 2)
            angleY = -clampedT * (M_PI / 8.5) * kWheelCurvature;
            transZ = -absT * 45.0 * kWheelCurvature;
            scale  = kCardScale * MAX(0.84, 1.0 - absT * 0.07);
            break;
        }
        case 6:
        default: {
            // Mode 6: 2D Cards (Classic Flat)
            scale = kCardScale;
            break;
        }
    }

    transform = CATransform3DTranslate(transform, 0.0, transY, transZ);
    if (fabs(angleY) > 0.0001) {
        transform = CATransform3DRotate(transform, angleY, 0.0, 1.0, 0.0);
    }
    if (fabs(angleZ) > 0.0001) {
        transform = CATransform3DRotate(transform, angleZ, 0.0, 0.0, 1.0);
    }
    transform = CATransform3DScale(transform, scale, scale, 1.0);

    targetView.layer.transform = transform;

    // Ambient Liquid Glass outer glow shadow on container
    if (kLiquidGlass && kGlowIntensity > 0.01) {
        self.layer.shadowColor = CSGlowColorForIndex(kGlowColorIndex, 1.0).CGColor;
        self.layer.shadowOpacity = (float)(kGlowIntensity * MAX(0.25, 1.0 - absT * 0.45));
        self.layer.shadowRadius = 18.0;
        self.layer.shadowOffset = CGSizeMake(0, 6);
    } else {
        self.layer.shadowOpacity = 0.0;
    }

    // Apply 3D Switcher 2 Icon Effects (fadeIcons, scaleIcons, rollIcons)
    for (UIView *sub in self.subviews) {
        if ([NSStringFromClass([sub class]) containsString:@"Icon"]) {
            sub.alpha = kFadeIcons ? MAX(0.15, 1.0 - absT * 0.65) : 1.0;
            CGAffineTransform iconTx = CGAffineTransformIdentity;
            if (kScaleIcons) {
                CGFloat iScale = MAX(0.65, 1.0 - absT * 0.28);
                iconTx = CGAffineTransformScale(iconTx, iScale, iScale);
            }
            if (kRollIcons) {
                iconTx = CGAffineTransformRotate(iconTx, clampedT * (M_PI / 3.0));
            }
            sub.transform = iconTx;
        }
    }
}

%end

// ============================================================================
// Live Reload Hook on SBFluidSwitcherViewController
// ============================================================================

%hook SBFluidSwitcherViewController

- (void)viewDidLoad {
    %orig;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_cs_refreshVisibleContainers)
                                                 name:@"CSInternalPreferencesDidUpdate"
                                               object:nil];
}

%new
- (void)_cs_refreshVisibleContainers {
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    for (UIView *sub in self.view.subviews) {
        [sub setNeedsLayout];
    }
}

%end

%ctor {
    @autoreleasepool {
        CSLoadPreferences();
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,
            CSReloadCallback,
            (__bridge CFStringRef)kCSReloadNotification,
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
}
