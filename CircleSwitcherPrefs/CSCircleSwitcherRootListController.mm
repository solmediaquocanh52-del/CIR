#import "CSCircleSwitcherRootListController.h"
#import "CSCircleSwitcherPreviewHeader.h"
#import "CSCircleSwitcherEasterEgg.h"
#import <spawn.h>

extern char **environ;

@interface CSCircleSwitcherRootListController ()
@property (nonatomic, strong) CSCircleSwitcherPreviewHeader *previewHeader;
@end

@implementation CSCircleSwitcherRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    UIImage *heartImg = [UIImage imageNamed:@"heart" inBundle:bundle compatibleWithTraitCollection:nil];
    UIBarButtonItem *shareBtn = [[UIBarButtonItem alloc] initWithImage:heartImg
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(shareTweak)];
    self.navigationItem.rightBarButtonItem = shareBtn;

    // Interactive 3D Live Preview Header + Hidden Pull-Down Easter Egg (from 3D Switcher 2)
    UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 165)];
    self.previewHeader = [[CSCircleSwitcherPreviewHeader alloc] initWithFrame:CGRectMake(0, 5, self.view.bounds.size.width, 155)];
    self.previewHeader.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [headerContainer addSubview:self.previewHeader];

    UIButton *secretBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    secretBtn.frame = CGRectMake(0, -140, self.view.bounds.size.width, 40);
    secretBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [secretBtn setTitle:@"CircleSwitcher Secret" forState:UIControlStateNormal];
    [secretBtn addTarget:self action:@selector(openEasterEgg) forControlEvents:UIControlEventTouchUpInside];
    [headerContainer addSubview:secretBtn];

    self.table.tableHeaderView = headerContainer;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [super setPreferenceValue:value specifier:specifier];

    NSString *key = [specifier propertyForKey:@"key"];
    if (key) {
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.vn.circleswitcher"];
        [defaults setObject:value forKey:key];
        [defaults synchronize];
    }

    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.vn.circleswitcher/ReloadPrefs"),
        NULL,
        NULL,
        YES
    );

    [self.previewHeader reloadPreviewFromPreferences];
}

// ============================================================================
// One-Tap Presets
// ============================================================================

- (void)applyBatchPreferences:(NSDictionary *)values {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.vn.circleswitcher"];
    for (NSString *k in values) {
        [defaults setObject:values[k] forKey:k];
    }
    [defaults synchronize];

    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.vn.circleswitcher/ReloadPrefs"),
        NULL,
        NULL,
        YES
    );

    [self reloadSpecifiers];
    [self.previewHeader reloadPreviewFromPreferences];
}

- (void)applyLiquidCirclePreset:(id)sender {
    [self applyBatchPreferences:@{
        @"enabled": @YES,
        @"layoutMode": @0,
        @"circleMorph": @YES,
        @"circleRadius": @115.0,
        @"wheelCurvature": @1.05,
        @"cardScale": @0.88,
        @"liquidGlass": @YES,
        @"glowIntensity": @0.55,
        @"glowColorIndex": @0,
        @"fadeIcons": @YES,
        @"scaleIcons": @YES,
        @"rollIcons": @NO
    }];
}

- (void)applyCoverFlowPreset:(id)sender {
    [self applyBatchPreferences:@{
        @"enabled": @YES,
        @"layoutMode": @3,
        @"circleMorph": @NO,
        @"circleRadius": @28.0,
        @"wheelCurvature": @1.15,
        @"cardScale": @0.86,
        @"liquidGlass": @YES,
        @"glowIntensity": @0.35,
        @"glowColorIndex": @1,
        @"fadeIcons": @YES,
        @"scaleIcons": @YES,
        @"rollIcons": @YES
    }];
}

- (void)applyMinimalDeckPreset:(id)sender {
    [self applyBatchPreferences:@{
        @"enabled": @YES,
        @"layoutMode": @2,
        @"circleMorph": @YES,
        @"circleRadius": @42.0,
        @"wheelCurvature": @0.85,
        @"cardScale": @0.90,
        @"liquidGlass": @NO,
        @"glowIntensity": @0.0,
        @"fadeIcons": @YES,
        @"scaleIcons": @NO,
        @"rollIcons": @NO
    }];
}

// ============================================================================
// Actions: Respring, Share, Easter Egg
// ============================================================================

- (void)respring:(id)sender {
    UIAlertController *confirm = [UIAlertController alertControllerWithTitle:@"Respring SpringBoard?"
                                                                     message:@"Most settings update live, or you can respring to refresh all switcher views."
                                                              preferredStyle:UIAlertControllerStyleAlert];
    [confirm addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [confirm addAction:[UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        pid_t pid;
        const char *rootlessKill = "/var/jb/usr/bin/killall";
        const char *rootfulKill  = "/usr/bin/killall";
        const char *binPath = (access(rootlessKill, X_OK) == 0) ? rootlessKill : rootfulKill;
        const char *args[] = {"killall", "-9", "SpringBoard", NULL};
        posix_spawn(&pid, binPath, NULL, NULL, (char * const *)args, environ);
    }]];
    [self presentViewController:confirm animated:YES completion:nil];
}

- (void)shareTweak {
    NSString *text = @"Loving #CircleSwitcher 2.0.0 — 3D Circular Wheel & Liquid Glass App Switcher for iOS!";
    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:@[text] applicationActivities:nil];
    vc.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)openEasterEgg {
    CSCircleSwitcherEasterEggController *ee = [[CSCircleSwitcherEasterEggController alloc] init];
    [self.navigationController pushViewController:ee animated:YES];
}

@end
