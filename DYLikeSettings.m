#import "DYLikeSettings.h"
#import "DYLikeCore.h"
#import <objc/runtime.h>

@interface DYLikeSettingsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation DYLikeSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 全屏黑色背景
    self.view.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.10 alpha:1.0];

    // 隐藏系统导航栏，使用自定义 Header
    self.navigationController.navigationBarHidden = YES;

    [self setupHeaderView];
    [self setupTableView];

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateTheme)
        name:DYLikeThemeDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateTheme)
        name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    [self.tableView reloadData];
}

- (void)setupHeaderView {
    UIView *headerView = [UIView new];
    headerView.translatesAutoresizingMaskIntoConstraints = NO;
    headerView.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.10 alpha:1.0];
    [self.view addSubview:headerView];

    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    backButton.translatesAutoresizingMaskIntoConstraints = NO;
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
    UIImage *backIcon = [UIImage systemImageNamed:@"chevron.left" withConfiguration:config];
    [backButton setImage:backIcon forState:UIControlStateNormal];
    [backButton setTintColor:UIColor.whiteColor];
    [backButton addTarget:self action:@selector(handleBack) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:backButton];

    UILabel *titleLabel = [UILabel new];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"AMZZ";
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:titleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [headerView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [headerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [headerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [headerView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:44],

        [backButton.leadingAnchor constraintEqualToAnchor:headerView.leadingAnchor constant:12],
        [backButton.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor constant:-8],
        [backButton.widthAnchor constraintEqualToConstant:32],
        [backButton.heightAnchor constraintEqualToConstant:32],

        [titleLabel.centerXAnchor constraintEqualToAnchor:headerView.centerXAnchor],
        [titleLabel.centerYAnchor constraintEqualToAnchor:backButton.centerYAnchor]
    ]];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 64;
    self.tableView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:44],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)handleBack {
    if (self.navigationController && self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)updateTheme {
    UIUserInterfaceStyle style = DYLikeUserInterfaceStyle();
    if (self.overrideUserInterfaceStyle != style) self.overrideUserInterfaceStyle = style;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark - TableView Delegate & DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return DYLikeActionCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSArray<NSString *> *titles;
    static NSArray<NSString *> *subtitles;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        titles = @[
            @"启用点赞二次确认",
            @"启用收藏二次确认",
            @"启用关注二次确认",
            @"启用评论点赞二次确认",
            @"启用评论点踩二次确认"
        ];
        subtitles = @[
            @"开启后防误触点赞视频",
            @"开启后防误触收藏视频",
            @"开启后防误触关注博主",
            @"开启后防误触点赞评论",
            @"开启后防误触点踩评论"
        ];
    });

    NSUInteger index = (NSUInteger)indexPath.row;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AMZZDarkCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"AMZZDarkCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = UIColor.whiteColor;
        cell.textLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        cell.backgroundColor = [UIColor clearColor];
    }

    cell.textLabel.text = titles[index];
    cell.detailTextLabel.text = subtitles[index];

    UISwitch *toggle = [UISwitch new];
    toggle.onTintColor = [UIColor colorWithRed:0.20 green:0.78 blue:0.35 alpha:1.0];
    toggle.on = DYLikeEnabled((DYLikeActionType)index);
    toggle.tag = (NSInteger)index;
    [toggle addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = toggle;

    cell.backgroundView = nil;
    for (UIView *v in [cell.contentView.subviews copy]) {
        if (v.tag == 999) [v removeFromSuperview];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger numberOfRows = [tableView numberOfRowsInSection:indexPath.section];
    CGFloat margin = 16.0;
    CGRect bounds = CGRectMake(margin, 0, cell.bounds.size.width - margin * 2, cell.bounds.size.height);

    UIRectCorner corners = 0;
    if (numberOfRows == 1) {
        corners = UIRectCornerAllCorners;
    } else if (indexPath.row == 0) {
        corners = UIRectCornerTopLeft | UIRectCornerTopRight;
    } else if (indexPath.row == numberOfRows - 1) {
        corners = UIRectCornerBottomLeft | UIRectCornerBottomRight;
    }

    CAShapeLayer *layer = [CAShapeLayer layer];
    UIBezierPath *path = (corners != 0) ? [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:corners cornerRadii:CGSizeMake(16, 16)] : [UIBezierPath bezierPathWithRect:bounds];

    layer.path = path.CGPath;
    layer.fillColor = [UIColor colorWithRed:0.13 green:0.14 blue:0.17 alpha:1.0].CGColor;

    UIView *bgView = [[UIView alloc] initWithFrame:cell.bounds];
    [bgView.layer insertSublayer:layer atIndex:0];
    bgView.backgroundColor = UIColor.clearColor;
    cell.backgroundView = bgView;

    if (indexPath.row < numberOfRows - 1) {
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(margin + 16, cell.bounds.size.height - 0.5, cell.bounds.size.width - (margin * 2) - 16, 0.5)];
        line.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.06];
        line.tag = 999;
        line.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [cell.contentView addSubview:line];
    }
}

- (void)toggleChanged:(UISwitch *)toggle {
    if (toggle.tag < 0 || (NSUInteger)toggle.tag >= DYLikeActionCount) return;
    NSArray<NSString *> *keys = @[DYLikeLikeEnabledKey, DYLikeFavoriteEnabledKey, DYLikeFollowEnabledKey,
        DYLikeCommentLikeEnabledKey, DYLikeCommentDislikeEnabledKey];
    [NSUserDefaults.standardUserDefaults setBool:toggle.isOn forKey:keys[(NSUInteger)toggle.tag]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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

        UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:settings];
        navigation.modalPresentationStyle = UIModalPresentationFullScreen;
        [top presentViewController:navigation animated:YES completion:nil];
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
