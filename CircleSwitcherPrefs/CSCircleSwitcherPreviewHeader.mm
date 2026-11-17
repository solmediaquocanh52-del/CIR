#import "CSCircleSwitcherPreviewHeader.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

@interface CSCircleSwitcherPreviewHeader ()
@property (nonatomic, strong) NSMutableArray<UIView *> *cardViews;
@property (nonatomic, assign) CGFloat dragOffset;
@end

@implementation CSCircleSwitcherPreviewHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
        self.cardViews = [NSMutableArray array];

        NSArray<NSArray<UIColor *> *> *cardPalettes = @[
            @[[UIColor colorWithRed:0.12 green:0.45 blue:0.98 alpha:1.0], [UIColor colorWithRed:0.20 green:0.80 blue:1.0 alpha:1.0]],
            @[[UIColor colorWithRed:0.42 green:0.24 blue:0.95 alpha:1.0], [UIColor colorWithRed:0.75 green:0.35 blue:1.0 alpha:1.0]],
            @[[UIColor colorWithRed:0.06 green:0.72 blue:0.65 alpha:1.0], [UIColor colorWithRed:0.22 green:0.92 blue:0.72 alpha:1.0]]
        ];

        for (NSInteger i = 0; i < 3; i++) {
            UIView *card = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 74, 108)];
            card.backgroundColor = cardPalettes[i][0];
            card.layer.masksToBounds = NO;

            UILabel *badge = [[UILabel alloc] initWithFrame:CGRectMake(8, 10, 58, 18)];
            badge.text = (i == 1) ? @"Active" : [NSString stringWithFormat:@"App %ld", (long)(i + 1)];
            badge.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightSemibold];
            badge.textColor = [UIColor whiteColor];
            badge.textAlignment = NSTextAlignmentCenter;
            [card addSubview:badge];

            [self addSubview:card];
            [self.cardViews addObject:card];
        }

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];

        [self reloadPreviewFromPreferences];
    }
    return self;
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self];
    if (pan.state == UIGestureRecognizerStateChanged) {
        self.dragOffset = MAX(-0.65, MIN(0.65, translation.x / 160.0));
        [self reloadPreviewFromPreferences];
    } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.72 initialSpringVelocity:0.5 options:0 animations:^{
            self.dragOffset = 0.0;
            [self reloadPreviewFromPreferences];
        } completion:nil];
    }
}

- (UIColor *)glowColorForIndex:(NSInteger)idx alpha:(CGFloat)alpha {
    switch (idx) {
        case 1:  return [UIColor colorWithRed:0.15 green:0.55 blue:1.00 alpha:alpha];
        case 2:  return [UIColor colorWithRed:0.68 green:0.35 blue:1.00 alpha:alpha];
        case 3:  return [UIColor colorWithRed:0.15 green:0.90 blue:0.65 alpha:alpha];
        case 4:  return [UIColor colorWithWhite:1.00 alpha:alpha];
        case 0:
        default: return [UIColor colorWithRed:0.25 green:0.85 blue:1.00 alpha:alpha];
    }
}

- (void)reloadPreviewFromPreferences {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.vn.circleswitcher"];
    [defaults synchronize];
    NSDictionary *prefs = [defaults dictionaryRepresentation];

    NSInteger mode = prefs[@"layoutMode"] ? [prefs[@"layoutMode"] integerValue] : 0;
    BOOL circleMorph = prefs[@"circleMorph"] ? [prefs[@"circleMorph"] boolValue] : YES;
    CGFloat radius = prefs[@"circleRadius"] ? [prefs[@"circleRadius"] floatValue] : 110.0f;
    CGFloat curvature = prefs[@"wheelCurvature"] ? [prefs[@"wheelCurvature"] floatValue] : 1.0f;
    BOOL glass = prefs[@"liquidGlass"] ? [prefs[@"liquidGlass"] boolValue] : YES;
    CGFloat glow = prefs[@"glowIntensity"] ? [prefs[@"glowIntensity"] floatValue] : 0.45f;
    NSInteger glowIdx = prefs[@"glowColorIndex"] ? [prefs[@"glowColorIndex"] integerValue] : 0;

    CGFloat w = self.bounds.size.width > 0 ? self.bounds.size.width : 350.0;
    CGFloat h = self.bounds.size.height > 0 ? self.bounds.size.height : 150.0;

    CGFloat cardW = circleMorph ? 84.0 : 72.0;
    CGFloat cardH = circleMorph ? 84.0 : 108.0;
    CGFloat effectiveRadius = circleMorph ? MIN(cardW * 0.5, radius * 0.42) : 14.0;

    for (NSInteger i = 0; i < (NSInteger)self.cardViews.count; i++) {
        UIView *card = self.cardViews[i];
        CGFloat baseT = (i - 1) * 0.65 + self.dragOffset;
        CGFloat absT = fabs(baseT);

        card.bounds = CGRectMake(0, 0, cardW, cardH);
        card.center = CGPointMake(w * 0.5 + baseT * 96.0, h * 0.52);
        card.layer.cornerRadius = effectiveRadius;

        if (glass && glow > 0.01) {
            card.layer.borderWidth = 1.6;
            card.layer.borderColor = [self glowColorForIndex:glowIdx alpha:0.85].CGColor;
            card.layer.shadowColor = [self glowColorForIndex:glowIdx alpha:1.0].CGColor;
            card.layer.shadowOpacity = (float)(glow * 0.75);
            card.layer.shadowRadius = 12.0;
            card.layer.shadowOffset = CGSizeMake(0, 4);
        } else {
            card.layer.borderWidth = 0.0;
            card.layer.shadowOpacity = 0.0;
        }

        CATransform3D tx = CATransform3DIdentity;
        tx.m34 = -1.0 / 600.0;
        CGFloat angleY = 0.0;
        CGFloat transY = 0.0;
        CGFloat scale = 1.0 - absT * 0.14;

        if (mode == 0) {
            angleY = -baseT * (M_PI / 5.0) * curvature;
            transY = (absT * absT) * 18.0 * curvature;
        } else if (mode == 3) {
            CGFloat sign = (baseT > 0) ? 1.0 : ((baseT < 0) ? -1.0 : 0.0);
            angleY = -sign * (M_PI / 3.6) * curvature;
        } else if (mode == 4) {
            CGFloat sign = (baseT > 0) ? 1.0 : ((baseT < 0) ? -1.0 : 0.0);
            angleY = sign * (M_PI / 3.6) * curvature;
        } else if (mode != 6) {
            angleY = -baseT * (M_PI / 7.0) * curvature;
        }

        tx = CATransform3DTranslate(tx, 0, transY, -absT * 45.0);
        tx = CATransform3DRotate(tx, angleY, 0, 1, 0);
        tx = CATransform3DScale(tx, scale, scale, 1.0);
        card.layer.transform = tx;
    }
}

@end
