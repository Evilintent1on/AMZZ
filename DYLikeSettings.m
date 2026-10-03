#import "DYLikeSettings.h"
#import "DYLikeCore.h"

@implementation DYLikeSettingsViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    return self;
}

#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"AMZZ";

    // =========================
    // 背景
    // =========================

    self.view.backgroundColor =
        [UIColor colorWithRed:0.075
                        green:0.075
                         blue:0.075
                        alpha:1.0];

    self.tableView.backgroundColor = UIColor.clearColor;

    self.tableView.separatorStyle =
        UITableViewCellSeparatorStyleNone;

    self.tableView.showsVerticalScrollIndicator = NO;

    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }

    // =========================
    // 导航栏
    // =========================

    self.navigationController.navigationBar.prefersLargeTitles = NO;

    self.navigationItem.largeTitleDisplayMode =
        UINavigationItemLargeTitleDisplayModeNever;

    self.navigationController.navigationBar.tintColor =
        UIColor.whiteColor;

    if (@available(iOS 13.0, *)) {

        UINavigationBarAppearance *appearance =
            [[UINavigationBarAppearance alloc] init];

        [appearance configureWithOpaqueBackground];

        appearance.backgroundColor =
            [UIColor colorWithRed:0.075
                            green:0.075
                             blue:0.075
                            alpha:1.0];

        appearance.titleTextAttributes = @{
            NSForegroundColorAttributeName :
                UIColor.whiteColor,

            NSFontAttributeName :
                [UIFont systemFontOfSize:20
                                   weight:UIFontWeightSemibold]
        };

        self.navigationController.navigationBar.standardAppearance =
            appearance;

        self.navigationController.navigationBar.scrollEdgeAppearance =
            appearance;

        self.navigationController.navigationBar.compactAppearance =
            appearance;
    }

    // =========================
    // 返回按钮
    // =========================

    UIButton *backButton =
        [UIButton buttonWithType:UIButtonTypeSystem];

    [backButton setImage:
        [UIImage systemImageNamed:@"chevron.left"]
              forState:UIControlStateNormal];

    backButton.tintColor =
        UIColor.whiteColor;

    backButton.frame =
        CGRectMake(0, 0, 32, 32);

    [backButton addTarget:self
                   action:@selector(closeSettings)
         forControlEvents:UIControlEventTouchUpInside];

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc]
            initWithCustomView:backButton];
}

#pragma mark - Sections

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return DYLikeActionCount;
}

#pragma mark - Section Header

- (NSString *)tableView:(UITableView *)tableView
 titleForHeaderInSection:(NSInteger)section {
    return @"二次确认";
}

- (CGFloat)tableView:(UITableView *)tableView
 heightForHeaderInSection:(NSInteger)section {
    return 50.0;
}

- (UIView *)tableView:(UITableView *)tableView
 viewForHeaderInSection:(NSInteger)section {

    UIView *headerView =
        [[UIView alloc] initWithFrame:CGRectZero];

    headerView.backgroundColor =
        UIColor.clearColor;

    UILabel *label =
        [[UILabel alloc] initWithFrame:CGRectZero];

    label.text = @"二次确认";

    // 左对齐
    label.textAlignment =
        NSTextAlignmentLeft;

    label.textColor =
        [UIColor colorWithWhite:0.62 alpha:1.0];

    label.font =
        [UIFont systemFontOfSize:16
                           weight:UIFontWeightMedium];

    label.translatesAutoresizingMaskIntoConstraints = NO;

    [headerView addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor
            constraintEqualToAnchor:
                headerView.leadingAnchor
                           constant:32.0],

        [label.trailingAnchor
            constraintEqualToAnchor:
                headerView.trailingAnchor
                           constant:-20.0],

        [label.topAnchor
            constraintEqualToAnchor:
                headerView.topAnchor],

        [label.bottomAnchor
            constraintEqualToAnchor:
                headerView.bottomAnchor]
    ]];

    return headerView;
}

#pragma mark - Cells

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *cellIdentifier =
        @"AMZZSettingCell";

    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:
            cellIdentifier];

    if (!cell) {

        cell =
            [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
              reuseIdentifier:cellIdentifier];

        cell.selectionStyle =
            UITableViewCellSelectionStyleNone;

        cell.backgroundColor =
            UIColor.clearColor;
    }

    // =========================
    // AMZZ 原来的功能
    // =========================

    NSArray<NSString *> *titles = @[
        @"点赞二次确认",
        @"收藏二次确认",
        @"关注二次确认",
        @"评论点赞二次确认",
        @"评论点踩二次确认"
    ];

    NSArray<NSString *> *keys = @[
        DYLikeLikeEnabledKey,
        DYLikeFavoriteEnabledKey,
        DYLikeFollowEnabledKey,
        DYLikeCommentLikeEnabledKey,
        DYLikeCommentDislikeEnabledKey
    ];

    NSUInteger index =
        (NSUInteger)indexPath.row;

    // =========================
    // 文字
    // =========================

    cell.textLabel.text =
        titles[index];

    cell.textLabel.textColor =
        UIColor.whiteColor;

    cell.textLabel.font =
        [UIFont systemFontOfSize:17.0];

    cell.textLabel.textAlignment =
        NSTextAlignmentLeft;

    // =========================
    // 原来的 UISwitch
    // =========================

    UISwitch *switchView =
        [[UISwitch alloc] init];

    switchView.on =
        [[NSUserDefaults standardUserDefaults]
            boolForKey:keys[index]];

    switchView.tag =
        (NSInteger)index;

    [switchView addTarget:self
                   action:@selector(switchChanged:)
         forControlEvents:UIControlEventValueChanged];

    /*
     * 不设置颜色、不缩放、不修改尺寸。
     * 保持系统 UISwitch 样式。
     */
    cell.accessoryView =
        switchView;

    return cell;
}

#pragma mark - Card Style

- (void)tableView:(UITableView *)tableView
 willDisplayCell:(UITableViewCell *)cell
 forRowAtIndexPath:(NSIndexPath *)indexPath {

    // =========================
    // DYYY 卡片左右留白
    // =========================

    CGRect frame =
        cell.frame;

    frame.origin.x = 16.0;
    frame.size.width -= 32.0;

    cell.frame = frame;

    // =========================
    // DYYY 卡片颜色
    // =========================

    cell.backgroundColor =
        [UIColor colorWithRed:0.14
                        green:0.14
                         blue:0.14
                        alpha:1.0];

    cell.layer.masksToBounds = YES;

    NSInteger rows =
        [tableView numberOfRowsInSection:
            indexPath.section];

    // =========================
    // 圆角
    // =========================

    if (rows == 1) {

        cell.layer.cornerRadius = 18.0;

        cell.layer.maskedCorners =
            kCALayerMinXMinYCorner |
            kCALayerMaxXMinYCorner |
            kCALayerMinXMaxYCorner |
            kCALayerMaxXMaxYCorner;

    } else if (indexPath.row == 0) {

        cell.layer.cornerRadius = 18.0;

        cell.layer.maskedCorners =
            kCALayerMinXMinYCorner |
            kCALayerMaxXMinYCorner;

    } else if (indexPath.row == rows - 1) {

        cell.layer.cornerRadius = 18.0;

        cell.layer.maskedCorners =
            kCALayerMinXMaxYCorner |
            kCALayerMaxXMaxYCorner;

    } else {

        cell.layer.cornerRadius = 0.0;

        cell.layer.maskedCorners = 0;
    }

    // =========================
    // 卡片内部细分割线
    // =========================

    // 先清理旧分割线（cell 重用）
    UIView *oldLine = [cell.contentView viewWithTag:9999];
    [oldLine removeFromSuperview];

    if (indexPath.row < rows - 1) {

        UIView *line =
            [[UIView alloc]
                initWithFrame:
                    CGRectMake(
                        20.0,
                        cell.bounds.size.height - 1.0,
                        cell.bounds.size.width - 40.0,
                        1.0
                    )];

        line.backgroundColor =
            [UIColor colorWithWhite:1.0
                              alpha:0.07];

        line.autoresizingMask =
            UIViewAutoresizingFlexibleWidth |
            UIViewAutoresizingFlexibleTopMargin;

        line.tag = 9999;

        [cell.contentView addSubview:line];
    }
}

#pragma mark - Switch

- (void)switchChanged:(UISwitch *)switchView {

    NSArray<NSString *> *keys = @[
        DYLikeLikeEnabledKey,
        DYLikeFavoriteEnabledKey,
        DYLikeFollowEnabledKey,
        DYLikeCommentLikeEnabledKey,
        DYLikeCommentDislikeEnabledKey
    ];

    NSInteger index =
        switchView.tag;

    if (index < 0 ||
        index >= (NSInteger)keys.count) {
        return;
    }

    [[NSUserDefaults standardUserDefaults]
        setBool:switchView.isOn
        forKey:keys[(NSUInteger)index]];

    [[NSUserDefaults standardUserDefaults]
        synchronize];
}

#pragma mark - Footer

- (NSString *)tableView:(UITableView *)tableView
 titleForFooterInSection:(NSInteger)section {

    return @"开启后，抖音对应操作会先显示确认弹窗。";
}

#pragma mark - Close

- (void)closeSettings {

    if (self.navigationController &&
        self.navigationController.viewControllers.count > 1) {

        [self.navigationController
            popViewControllerAnimated:YES];

    } else {

        [self dismissViewControllerAnimated:YES
                                 completion:nil];
    }
}

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle {

    return UIStatusBarStyleLightContent;
}

@end

#import <objc/runtime.h>

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
        DYLikeSettingsViewController *vc = [DYLikeSettingsViewController new];
        // 独立呈现，不 push 进抖音导航栈，避免透明叠加
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [top presentViewController:nav animated:YES completion:nil];
    });
}

static BOOL DYLikeSet(id object, NSString *key, id value) {
    @try { [object setValue:value forKey:key]; return YES; }
    @catch (__unused NSException *e) { return NO; }
}

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
        NSMutableArray *sections = [value mutableCopy];
        for (id section in sections) {
            id items = DYLikeRead(section, @"itemArray");
            if (![items isKindOfClass:NSArray.class]) continue;
            for (id item in (NSArray *)items) {
                if ([DYLikeRead(item, @"title") isEqual:@"AMZZ"]) return value;
            }
        }
        id targetSection = nil;
        for (id section in sections) {
            id items = DYLikeRead(section, @"itemArray");
            if ([items isKindOfClass:NSArray.class] && [(NSArray *)items count] > 0) { targetSection = section; break; }
        }
        if (!targetSection) return value;
        id item = [[itemClass alloc] init];
        BOOL valid = YES;
        valid &= DYLikeSet(item, @"title", @"AMZZ");
        valid &= DYLikeSet(item, @"cellTappedBlock", ^{ DYLikeOpenSettings(); });
        if (valid) {
            id existingItems = DYLikeRead(targetSection, @"itemArray");
            NSMutableArray *items = existingItems ? [existingItems mutableCopy] : [[NSMutableArray alloc] init];
            [items addObject:item];
            DYLikeSet(targetSection, @"itemArray", items);
        }
        return sections;
    });
    class_replaceMethod(cls, selector, replacement, method_getTypeEncoding(method));
    installed = YES;
}
