#import "DYLikeSettings.h"
#import "DYLikeCore.h"
#import <objc/runtime.h>

@implementation DYLikeSettingsViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"AMZZ";

    // 深色背景（Yuki 风格）
    self.view.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;

    // 导航栏：深色 + 白色标题
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
        appearance.titleTextAttributes = @{
            NSForegroundColorAttributeName: [UIColor whiteColor],
            NSFontAttributeName: [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold]
        };
        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
        self.navigationController.navigationBar.compactAppearance = appearance;
    }

    // 返回按钮：白色箭头
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [backButton setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
    backButton.tintColor = [UIColor whiteColor];
    backButton.frame = CGRectMake(0, 0, 32, 32);
    [backButton addTarget:self action:@selector(closeSettings) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
}

- (void)closeSettings {
    if (self.navigationController && self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Data

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 5; }
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath { return 56; }

// 分区头：灰色小字左对齐（Yuki 风格）
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section { return 44; }
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] init];
    header.backgroundColor = [UIColor clearColor];
    UILabel *label = [[UILabel alloc] init];
    label.text = @"二次确认";
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:32],
        [label.centerYAnchor constraintEqualToAnchor:header.centerYAnchor]
    ]];
    return header;
}

// 底部留白
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section { return 30; }
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footer = [[UIView alloc] init];
    footer.backgroundColor = [UIColor clearColor];
    return footer;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"AMZZCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    NSArray *titles = @[@"点赞二次确认", @"收藏二次确认", @"关注二次确认", @"评论点赞二次确认", @"评论点踩二次确认"];
    NSArray *keys = @[DYLikeLikeEnabledKey, DYLikeFavoriteEnabledKey, DYLikeFollowEnabledKey,
                      DYLikeCommentLikeEnabledKey, DYLikeCommentDislikeEnabledKey];

    NSUInteger idx = (NSUInteger)indexPath.row;
    cell.textLabel.text = titles[idx];
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    cell.textLabel.textColor = [UIColor whiteColor];

    // 卡片背景
    cell.backgroundColor = [UIColor colorWithRed:0.17 green:0.17 blue:0.18 alpha:1.0];

    // 开关
    UISwitch *sw = [[UISwitch alloc] init];
    sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:keys[idx]];
    // 默认开启
    if (![[NSUserDefaults standardUserDefaults] objectForKey:keys[idx]]) sw.on = YES;
    sw.tag = (NSInteger)idx;
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;

    return cell;
}

// 卡片圆角 + 左右边距（Yuki 风格）
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat inset = 16;
    CGRect frame = cell.frame;
    frame.origin.x = inset;
    frame.size.width = tableView.bounds.size.width - inset * 2;
    cell.frame = frame;

    NSInteger rows = [tableView numberOfRowsInSection:indexPath.section];
    cell.layer.masksToBounds = YES;
    if (rows == 1) {
        cell.layer.cornerRadius = 14;
        cell.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    } else if (indexPath.row == 0) {
        cell.layer.cornerRadius = 14;
        cell.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    } else if (indexPath.row == rows - 1) {
        cell.layer.cornerRadius = 14;
        cell.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    } else {
        cell.layer.cornerRadius = 0;
        cell.layer.maskedCorners = 0;
    }

    // 分隔线（除了最后一行）
    UIView *oldLine = [cell.contentView viewWithTag:9999];
    [oldLine removeFromSuperview];
    if (indexPath.row < rows - 1) {
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(16, 55.5, cell.bounds.size.width - 32, 0.5)];
        line.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
        line.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        line.tag = 9999;
        [cell.contentView addSubview:line];
    }
}

- (void)switchChanged:(UISwitch *)sw {
    NSArray *keys = @[DYLikeLikeEnabledKey, DYLikeFavoriteEnabledKey, DYLikeFollowEnabledKey,
                      DYLikeCommentLikeEnabledKey, DYLikeCommentDislikeEnabledKey];
    if (sw.tag >= 0 && sw.tag < (NSInteger)keys.count) {
        [[NSUserDefaults standardUserDefaults] setBool:sw.isOn forKey:keys[(NSUInteger)sw.tag]];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle { return UIStatusBarStyleLightContent; }

@end

// 设置入口
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
    SEL selector = NSSelectorFromString(@"sectionDataArray");
    Method method = class_getInstanceMethod(cls, selector);
    if (!method || !itemClass) return;
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
