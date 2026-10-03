#import "DYLikeSettings.h"
#import "DYLikeCore.h"
#import <objc/runtime.h>

@interface DYLikeSettingsViewController ()
@property (nonatomic, strong) UIVisualEffectView *blurEffectView;
@property (nonatomic, strong) UIView *overlayView;
@end

@implementation DYLikeSettingsViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"AMZZ";

    [self setupAppearance];
    [self setupBackground];
    [self setupTableView];
}

#pragma mark - Appearance

- (void)setupAppearance {
    UINavigationBar *bar = self.navigationController.navigationBar;

    bar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode =
        UINavigationItemLargeTitleDisplayModeAlways;

    bar.tintColor = UIColor.whiteColor;

    bar.largeTitleTextAttributes = @{
        NSForegroundColorAttributeName : UIColor.whiteColor
    };

    bar.titleTextAttributes = @{
        NSForegroundColorAttributeName : UIColor.whiteColor
    };

    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance =
            [[UINavigationBarAppearance alloc] init];

        [appearance configureWithTransparentBackground];

        appearance.backgroundColor =
            [UIColor colorWithWhite:0.05 alpha:0.85];

        appearance.largeTitleTextAttributes = @{
            NSForegroundColorAttributeName : UIColor.whiteColor
        };

        appearance.titleTextAttributes = @{
            NSForegroundColorAttributeName : UIColor.whiteColor
        };

        bar.standardAppearance = appearance;
        bar.scrollEdgeAppearance = appearance;
        bar.compactAppearance = appearance;
    }
}

#pragma mark - Background

- (void)setupBackground {
    UIBlurEffect *blur =
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];

    self.blurEffectView =
        [[UIVisualEffectView alloc] initWithEffect:blur];

    self.blurEffectView.frame = self.view.bounds;
    self.blurEffectView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;

    [self.view insertSubview:self.blurEffectView atIndex:0];

    self.overlayView =
        [[UIView alloc] initWithFrame:self.view.bounds];

    self.overlayView.backgroundColor =
        [UIColor colorWithWhite:0 alpha:0.25];

    self.overlayView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;

    [self.view insertSubview:self.overlayView atIndex:1];
}

#pragma mark - Table View

- (void)setupTableView {
    self.tableView.backgroundColor = UIColor.clearColor;

    self.tableView.separatorStyle =
        UITableViewCellSeparatorStyleNone;

    self.tableView.contentInset =
        UIEdgeInsetsMake(20, 0, 0, 0);

    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }

    self.tableView.showsVerticalScrollIndicator = NO;
}

#pragma mark - Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return DYLikeActionCount;
}

- (NSString *)tableView:(UITableView *)tableView
 titleForHeaderInSection:(NSInteger)section {
    return @"二次确认";
}

- (CGFloat)tableView:(UITableView *)tableView
 heightForHeaderInSection:(NSInteger)section {
    return 44.0;
}

#pragma mark - Header

- (UIView *)tableView:(UITableView *)tableView
 viewForHeaderInSection:(NSInteger)section {

    UIView *header =
        [[UIView alloc] initWithFrame:CGRectZero];

    UILabel *label =
        [[UILabel alloc] initWithFrame:CGRectZero];

    label.text = @"二次确认";
    label.textColor = UIColor.whiteColor;
    label.font =
        [UIFont systemFontOfSize:16
                           weight:UIFontWeightMedium];

    label.translatesAutoresizingMaskIntoConstraints = NO;

    [header addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor
            constraintEqualToAnchor:header.leadingAnchor
                           constant:15],

        [label.trailingAnchor
            constraintEqualToAnchor:header.trailingAnchor
                           constant:-15],

        [label.centerYAnchor
            constraintEqualToAnchor:header.centerYAnchor]
    ]];

    return header;
}

#pragma mark - Cells

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *identifier = @"DYLikeSettingsCell";

    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:identifier];

    if (!cell) {
        cell =
            [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
              reuseIdentifier:identifier];

        cell.selectionStyle =
            UITableViewCellSelectionStyleNone;

        cell.textLabel.font =
            [UIFont systemFontOfSize:17];

        cell.textLabel.translatesAutoresizingMaskIntoConstraints = NO;

        [cell.textLabel.leadingAnchor
            constraintEqualToAnchor:cell.contentView.leadingAnchor
                           constant:16].active = YES;

        [cell.textLabel.centerYAnchor
            constraintEqualToAnchor:cell.contentView.centerYAnchor].active = YES;
    }

    NSArray<NSString *> *titles = @[
        @"点赞二次确认",
        @"收藏二次确认",
        @"关注二次确认",
        @"评论点赞二次确认",
        @"评论点踩二次确认"
    ];

    NSUInteger index = (NSUInteger)indexPath.row;

    cell.textLabel.text = titles[index];
    cell.textLabel.textColor = UIColor.whiteColor;

    UISwitch *toggle = [[UISwitch alloc] init];

    toggle.on = DYLikeEnabled((DYLikeActionType)index);
    toggle.tag = (NSInteger)index;

    [toggle addTarget:self
               action:@selector(toggleChanged:)
     forControlEvents:UIControlEventValueChanged];

    cell.accessoryView = toggle;

    /*
     * DYYY 风格的半透明卡片
     */
    cell.backgroundColor =
        [UIColor colorWithWhite:1.0 alpha:0.10];

    cell.backgroundView = nil;

    return cell;
}

#pragma mark - Rounded Cell

- (void)tableView:(UITableView *)tableView
 willDisplayCell:(UITableViewCell *)cell
 forRowAtIndexPath:(NSIndexPath *)indexPath {

    /*
     * 左右留出空间，接近 DYYY 的卡片布局
     */
    CGFloat inset = 16.0;

    CGRect frame = cell.frame;
    frame.origin.x = inset;
    frame.size.width -= inset * 2.0;
    cell.frame = frame;

    NSInteger rows =
        [tableView numberOfRowsInSection:indexPath.section];

    if (rows > 1 && indexPath.row == rows - 1) {

        cell.layer.cornerRadius = 10.0;
        cell.layer.masksToBounds = YES;

        cell.layer.maskedCorners =
            kCALayerMinXMaxYCorner |
            kCALayerMaxXMaxYCorner;

    } else {
        cell.layer.cornerRadius = 0.0;
        cell.layer.masksToBounds = NO;
    }
}

#pragma mark - Switch

- (void)toggleChanged:(UISwitch *)toggle {

    if (toggle.tag < 0 ||
        toggle.tag >= DYLikeActionCount) {
        return;
    }

    NSArray<NSString *> *keys = @[
        DYLikeLikeEnabledKey,
        DYLikeFavoriteEnabledKey,
        DYLikeFollowEnabledKey,
        DYLikeCommentLikeEnabledKey,
        DYLikeCommentDislikeEnabledKey
    ];

    NSString *key =
        keys[(NSUInteger)toggle.tag];

    [[NSUserDefaults standardUserDefaults]
        setBool:toggle.isOn
        forKey:key];

    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Footer

- (NSString *)tableView:(UITableView *)tableView
 titleForFooterInSection:(NSInteger)section {

    return @"开启后，抖音对应操作会先显示确认弹窗。";
}

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

    }
}

@end

static UIViewController *DYLikeTop(UIViewController *controller) {
    if (controller.presentedViewController && !controller.presentedViewController.isBeingDismissed) {
        return DYLikeTop(controller.presentedViewController);
    }
    if ([controller isKindOfClass:UINavigationController.class]) {
        return DYLikeTop(((UINavigationController *)controller).visibleViewController);
    }
    if ([controller isKindOfClass:UITabBarController.class]) {
        return DYLikeTop(((UITabBarController *)controller).selectedViewController);
    }
    return controller;
}

void DYLikeOpenSettings(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = DYLikeActiveWindow();
        UIViewController *top = DYLikeTop(window.rootViewController);
        if (!top || [top isKindOfClass:DYLikeSettingsViewController.class]) return;

        DYLikeSettingsViewController *settings = [DYLikeSettingsViewController new];
        settings.overrideUserInterfaceStyle = DYLikeUserInterfaceStyle();
        if (top.navigationController) {
            [top.navigationController pushViewController:settings animated:YES];
        } else {
            UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:settings];
            settings.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                initWithBarButtonSystemItem:UIBarButtonSystemItemClose target:settings action:@selector(closeSettings)];
            [top presentViewController:navigation animated:YES completion:nil];
        }
    });
}

static BOOL DYLikeSet(id object, NSString *key, id value) {
    @try {
        [object setValue:value forKey:key];
        return YES;
    } @catch (__unused NSException *exception) {
        return NO;
    }
}

// 仅在抖音设置主页显示插件入口。
static BOOL DYLikeIsMainSettingsPage(id owner, NSArray *sections) {
    id controller = DYLikeRead(owner, @"controllerDelegate");
    Class settingsClass = NSClassFromString(@"AWESettingsTableViewController");
    if (controller && settingsClass && ![controller isKindOfClass:settingsClass]) return NO;
    for (id section in sections) {
        if ([DYLikeRead(section, @"sectionHeaderTitle") isEqual:@"账号"]) return YES;
    }
    return NO;
}

void DYLikeInstallSettingsHook(void) {
    static BOOL installed;
    if (installed) return;
    Class cls = NSClassFromString(@"AWESettingsViewModel");
    Class itemClass = NSClassFromString(@"AWESettingItemModel");
    Class sectionClass = NSClassFromString(@"AWESettingSectionModel");
    SEL selector = NSSelectorFromString(@"sectionDataArray");
    Method method = class_getInstanceMethod(cls, selector);
    if (!method || !itemClass || !sectionClass) return;
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(method)];
    if (signature.numberOfArguments != 2 || signature.methodReturnType[0] != '@') return;

    IMP original = method_getImplementation(method);
    IMP replacement = imp_implementationWithBlock(^id(id owner) {
        id value = ((id (*)(id, SEL))original)(owner, selector);
        if (![value isKindOfClass:NSArray.class]) return value;
        if (!DYLikeIsMainSettingsPage(owner, value)) return value;
        for (id section in value) {
            id items = DYLikeRead(section, @"itemArray");
            if (![items isKindOfClass:NSArray.class]) continue;
            for (id item in items) {
                if ([DYLikeRead(item, @"identifier") isEqual:@"DYSecondaryConfirmation.Settings"]) return value;
            }
        }

        id item = [itemClass new];
        BOOL valid = DYLikeSet(item, @"identifier", @"DYSecondaryConfirmation.Settings");
        valid &= DYLikeSet(item, @"title", @"AMZZ");
        valid &= DYLikeSet(item, @"cellType", @26);
        valid &= DYLikeSet(item, @"cellTappedBlock", ^{ DYLikeOpenSettings(); });
        DYLikeSet(item, @"detail", DYLikeVersion);
        DYLikeSet(item, @"isEnable", @YES);
        DYLikeSet(item, @"colorStyle", @2);
        DYLikeSet(item, @"svgIconImageName", @"ic_gearsimplify_outlined_20");
        DYLikeSet(item, @"specificIconImage", [UIImage systemImageNamed:@"checkmark.circle.fill"]);

        id section = [sectionClass new];
        valid &= DYLikeSet(section, @"itemArray", @[item]);
        DYLikeSet(section, @"sectionHeaderTitle", @"AMZZ");
        DYLikeSet(section, @"sectionHeaderHeight", @40);
        if (!valid) return value;
        NSMutableArray *sections = [value mutableCopy];
        // 有插件（"账号"不在第一位）就放第二位，没插件就置顶
        NSUInteger insertIndex = 0;
        for (NSUInteger i = 0; i < sections.count; i++) {
            if ([DYLikeRead(sections[i], @"sectionHeaderTitle") isEqual:@"账号"]) {
                insertIndex = (i > 0) ? 1 : 0;
                break;
            }
        }
        if (insertIndex > sections.count) insertIndex = sections.count;
        [sections insertObject:section atIndex:insertIndex];
        return sections;
    });
    class_replaceMethod(cls, selector, replacement, method_getTypeEncoding(method));
    installed = YES;
}
