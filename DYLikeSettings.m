#import "DYLikeSettings.h"
#import "../Core/DYLikeCore.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

#pragma mark - Settings View Controller

@implementation DYLikeSettingsViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"AMZZ设置";

    /*
     DYYY：
     - 大标题
     - 深色毛玻璃
     - InsetGrouped
     - 无分割线
     */

    [self setupAppearance];
    [self setupBlurEffect];
    [self setupTableView];

    [NSNotificationCenter.defaultCenter addObserver:self
                                             selector:@selector(updateTheme)
                                                 name:DYLikeThemeDidChangeNotification
                                               object:nil];

    [NSNotificationCenter.defaultCenter addObserver:self
                                             selector:@selector(updateTheme)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    [self updateTheme];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.prefersLargeTitles = YES;

    [self updateTheme];
    [self.tableView reloadData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    /*
     DYYY 的毛玻璃覆盖整个页面。
     这里确保旋转/尺寸变化时不会出现空白。
     */

    if (self.blurEffectView) {
        self.blurEffectView.frame = self.view.bounds;
    }

    if (self.overlayView) {
        self.overlayView.frame = self.view.bounds;
    }
}

#pragma mark - Appearance

- (void)setupAppearance {

    UINavigationBar *navigationBar = self.navigationController.navigationBar;

    navigationBar.barTintColor = UIColor.clearColor;
    navigationBar.tintColor = UIColor.whiteColor;

    navigationBar.prefersLargeTitles = YES;

    navigationBar.largeTitleTextAttributes = @{
        NSForegroundColorAttributeName : UIColor.whiteColor
    };

    self.navigationItem.largeTitleDisplayMode =
        UINavigationItemLargeTitleDisplayModeAlways;

    /*
     DYYY 风格：
     不做一个圆形的返回按钮，
     使用系统 chevron。
     */

    UIImage *backImage =
        [UIImage systemImageNamed:@"chevron.left"];

    UIButton *backButton =
        [UIButton buttonWithType:UIButtonTypeSystem];

    [backButton setImage:backImage
                forState:UIControlStateNormal];

    backButton.tintColor = UIColor.whiteColor;

    backButton.frame = CGRectMake(0, 0, 30, 30);

    [backButton addTarget:self
                   action:@selector(closeSettings)
         forControlEvents:UIControlEventTouchUpInside];

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithCustomView:backButton];
}

#pragma mark - Blur

/*
 DYYY 原版就是这一套：
 UIBlurEffectStyleDark
 + Vibrancy
 + 0.3 黑色 Overlay
 */

- (void)setupBlurEffect {

    UIBlurEffect *blurEffect =
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];

    self.blurEffectView =
        [[UIVisualEffectView alloc] initWithEffect:blurEffect];

    self.blurEffectView.frame = self.view.bounds;

    self.blurEffectView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;

    [self.view addSubview:self.blurEffectView];


    UIVibrancyEffect *vibrancyEffect =
        [UIVibrancyEffect effectForBlurEffect:blurEffect];

    self.vibrancyEffectView =
        [[UIVisualEffectView alloc]
            initWithEffect:vibrancyEffect];

    self.vibrancyEffectView.frame =
        self.blurEffectView.bounds;

    self.vibrancyEffectView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;

    [self.blurEffectView.contentView
        addSubview:self.vibrancyEffectView];


    self.overlayView =
        [[UIView alloc] initWithFrame:self.view.bounds];

    self.overlayView.backgroundColor =
        [UIColor colorWithWhite:0 alpha:0.3];

    self.overlayView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;

    [self.view addSubview:self.overlayView];
}

#pragma mark - Table View

- (void)setupTableView {

    /*
     这里完全跟 DYYY 对齐：
     UITableViewStyleInsetGrouped
     */

    self.tableView.backgroundColor =
        UIColor.clearColor;

    self.tableView.separatorStyle =
        UITableViewCellSeparatorStyleNone;

    /*
     DYYY：
     UIEdgeInsetsMake(20, 0, 0, 0)
     */

    self.tableView.contentInset =
        UIEdgeInsetsMake(20, 0, 0, 0);

    self.tableView.sectionHeaderTopPadding = 0;

    self.tableView.showsVerticalScrollIndicator = NO;

    self.tableView.rowHeight = 54.0;

    self.tableView.estimatedRowHeight = 54.0;

    self.tableView.sectionHeaderHeight = 44.0;

    self.tableView.sectionFooterHeight =
        UITableViewAutomaticDimension;
}

#pragma mark - Theme

- (void)updateTheme {

    UIUserInterfaceStyle style =
        DYLikeUserInterfaceStyle();

    self.overrideUserInterfaceStyle = style;

    /*
     DYYY 是深色 UI，
     但 AMZZ 仍然保留你的主题系统。
     */

    self.tableView.backgroundColor =
        UIColor.clearColor;

    self.tableView.separatorStyle =
        UITableViewCellSeparatorStyleNone;

    UINavigationBarAppearance *appearance =
        [UINavigationBarAppearance new];

    /*
     不给导航栏单独刷一块实色，
     让下面的毛玻璃透出来。
     */

    [appearance configureWithTransparentBackground];

    appearance.backgroundColor =
        UIColor.clearColor;

    appearance.titleTextAttributes = @{
        NSForegroundColorAttributeName :
            DYLikeTextColor()
    };

    appearance.largeTitleTextAttributes = @{
        NSForegroundColorAttributeName :
            DYLikeTextColor()
    };

    self.navigationItem.standardAppearance =
        appearance;

    self.navigationItem.scrollEdgeAppearance =
        appearance;

    self.navigationItem.compactAppearance =
        appearance;

    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)traitCollectionDidChange:
    (UITraitCollection *)previousTraitCollection {

    [super traitCollectionDidChange:
        previousTraitCollection];

    [self updateTheme];
}

- (UIStatusBarStyle)preferredStatusBarStyle {

    return UIStatusBarStyleLightContent;
}

#pragma mark - Section

- (NSInteger)numberOfSectionsInTableView:
    (UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:
    (UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {

    return DYLikeActionCount;
}

- (CGFloat)tableView:
    (UITableView *)tableView
    heightForHeaderInSection:(NSInteger)section {

    return 44.0;
}

- (UIView *)tableView:
    (UITableView *)tableView
    viewForHeaderInSection:(NSInteger)section {

    /*
     DYYY 风格 Header：
     15pt 左边距
     16pt 字体
     Medium
     */

    UIView *headerView =
        [[UIView alloc]
            initWithFrame:CGRectMake(
                0,
                0,
                tableView.bounds.size.width,
                44)];

    headerView.backgroundColor =
        UIColor.clearColor;


    UILabel *titleLabel =
        [[UILabel alloc]
            initWithFrame:CGRectMake(
                15,
                0,
                tableView.bounds.size.width - 50,
                44)];

    titleLabel.text = @"二次确认";

    titleLabel.textColor =
        UIColor.whiteColor;

    titleLabel.font =
        [UIFont systemFontOfSize:16
                           weight:UIFontWeightMedium];

    [headerView addSubview:titleLabel];


    /*
     DYYY Header 右边的 chevron。
     AMZZ 没有折叠功能，所以固定 down。
     */

    UIImageView *arrowImageView =
        [[UIImageView alloc]
            initWithFrame:CGRectMake(
                tableView.bounds.size.width - 35,
                15,
                14,
                14)];

    arrowImageView.image =
        [UIImage systemImageNamed:@"chevron.down"];

    arrowImageView.tintColor =
        UIColor.lightGrayColor;

    arrowImageView.contentMode =
        UIViewContentModeScaleAspectFit;

    [headerView addSubview:arrowImageView];

    return headerView;
}

#pragma mark - Footer

- (NSString *)tableView:
    (UITableView *)tableView
    titleForFooterInSection:(NSInteger)section {

    return
        @"开启后，抖音对应操作会先显示确认弹窗；设置修改后立即生效。";
}

#pragma mark - Cell

- (UITableViewCell *)tableView:
    (UITableView *)tableView
    cellForRowAtIndexPath:
        (NSIndexPath *)indexPath {

    static NSString *identifier =
        @"AMZZSettingCell";

    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:
            identifier];

    if (!cell) {

        cell =
            [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:identifier];

        /*
         DYYY：
         textLabel 自己控制位置
         */

        cell.textLabel.translatesAutoresizingMaskIntoConstraints =
            NO;

        [NSLayoutConstraint activateConstraints:@[
            [cell.textLabel.leadingAnchor
                constraintEqualToAnchor:
                    cell.contentView.leadingAnchor
                constant:16],

            [cell.textLabel.centerYAnchor
                constraintEqualToAnchor:
                    cell.contentView.centerYAnchor]
        ]];

        /*
         DYYY 的选中背景。
         */

        UIView *selectedBackgroundView =
            [[UIView alloc] init];

        selectedBackgroundView.backgroundColor =
            [UIColor colorWithRed:84 / 255.0
                            green:84 / 255.0
                             blue:84 / 255.0
                            alpha:1.0];

        cell.selectedBackgroundView =
            selectedBackgroundView;
    }


    NSArray<NSString *> *titles = @[
        @"启用点赞二次确认",
        @"启用收藏二次确认",
        @"启用关注二次确认",
        @"启用评论点赞二次确认",
        @"启用评论点踩二次确认"
    ];

    NSUInteger index =
        (NSUInteger)indexPath.row;

    NSString *title =
        titles[index];


    cell.textLabel.text = title;

    cell.textLabel.font =
        [UIFont systemFontOfSize:17];

    cell.textLabel.textColor =
        UIColor.whiteColor;

    cell.selectionStyle =
        UITableViewCellSelectionStyleNone;


    /*
     DYYY 核心：
     cell 本身是透明的，
     backgroundView 才负责卡片背景。
     */

    cell.backgroundColor =
        UIColor.clearColor;


    /*
     这一点很重要：
     不再使用 DYLikeRoundedCardBg()。
     DYYY 是直接对 cell 的 layer 做圆角。
     */

    cell.backgroundView = nil;


    /*
     DYYY 的卡片颜色：
     white alpha 0.1
     */

    UIView *backgroundView =
        [[UIView alloc] init];

    backgroundView.backgroundColor =
        [UIColor colorWithWhite:1.0 alpha:0.1];

    cell.backgroundView =
        backgroundView;


    /*
     最后一行做底部圆角。
     */

    NSInteger rows =
        [self tableView:tableView
        numberOfRowsInSection:indexPath.section];

    if (indexPath.row == rows - 1) {

        cell.layer.cornerRadius = 10.0;

        cell.layer.maskedCorners =
            kCALayerMinXMaxYCorner |
            kCALayerMaxXMaxYCorner;

        cell.layer.masksToBounds = YES;

    } else {

        cell.layer.cornerRadius = 0;

        cell.layer.maskedCorners = 0;

        cell.layer.masksToBounds = NO;
    }


    /*
     AMZZ 保留原来的开关。
     */

    UISwitch *switchView =
        [[UISwitch alloc] init];

    switchView.on =
        DYLikeEnabled((DYLikeActionType)index);

    switchView.tag =
        (NSInteger)index;

    switchView.onTintColor =
        nil;

    switchView.enabled = YES;

    [switchView addTarget:self
                   action:@selector(toggleChanged:)
         forControlEvents:UIControlEventValueChanged];

    cell.accessoryView =
        switchView;


    return cell;
}

#pragma mark - Cell Inset

- (void)tableView:
    (UITableView *)tableView
    willDisplayCell:
        (UITableViewCell *)cell
    forRowAtIndexPath:
        (NSIndexPath *)indexPath {

    /*
     DYYY：
     左右各 16pt。
     */

    CGFloat inset = 16.0;

    cell.contentView.frame =
        UIEdgeInsetsInsetRect(
            cell.contentView.frame,
            UIEdgeInsetsMake(
                0,
                inset,
                0,
                inset));
}

#pragma mark - Toggle

- (void)toggleChanged:(UISwitch *)toggle {

    if (toggle.tag < 0 ||
        (NSUInteger)toggle.tag >= DYLikeActionCount) {

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

    /*
     立即同步，避免部分情况下设置页返回后状态没刷新。
     */

    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Selection

- (void)tableView:
    (UITableView *)tableView
    didSelectRowAtIndexPath:
        (NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
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

#pragma mark - Dealloc

- (void)dealloc {

    [NSNotificationCenter.defaultCenter
        removeObserver:self];
}

@end


#pragma mark - Top View Controller

static UIViewController *DYLikeTop(
    UIViewController *controller) {

    if (controller.presentedViewController &&
        !controller.presentedViewController.isBeingDismissed) {

        return DYLikeTop(
            controller.presentedViewController);
    }

    if ([controller
            isKindOfClass:UINavigationController.class]) {

        return DYLikeTop(
            ((UINavigationController *)controller)
                .visibleViewController);
    }

    if ([controller
            isKindOfClass:UITabBarController.class]) {

        return DYLikeTop(
            ((UITabBarController *)controller)
                .selectedViewController);
    }

    return controller;
}


#pragma mark - Open Settings

void DYLikeOpenSettings(void) {

    dispatch_async(dispatch_get_main_queue(), ^{

        UIWindow *window =
            DYLikeActiveWindow();

        UIViewController *top =
            DYLikeTop(window.rootViewController);

        if (!top ||
            [top isKindOfClass:
                DYLikeSettingsViewController.class]) {

            return;
        }


        DYLikeSettingsViewController *settings =
            [DYLikeSettingsViewController new];

        settings.overrideUserInterfaceStyle =
            DYLikeUserInterfaceStyle();


        if (top.navigationController) {

            [top.navigationController
                pushViewController:settings
                animated:YES];

        } else {

            UINavigationController *navigation =
                [[UINavigationController alloc]
                    initWithRootViewController:settings];

            [top presentViewController:navigation
                              animated:YES
                            completion:nil];
        }
    });
}


#pragma mark - KVC Helper

static BOOL DYLikeSet(
    id object,
    NSString *key,
    id value) {

    @try {

        [object setValue:value forKey:key];

        return YES;

    } @catch (__unused NSException *exception) {

        return NO;
    }
}


#pragma mark - Main Settings Detection

static BOOL DYLikeIsMainSettingsPage(
    id owner,
    NSArray *sections) {

    id controller =
        DYLikeRead(owner, @"controllerDelegate");

    Class settingsClass =
        NSClassFromString(
            @"AWESettingsTableViewController");

    if (controller &&
        settingsClass &&
        ![controller isKindOfClass:settingsClass]) {

        return NO;
    }

    for (id section in sections) {

        if ([DYLikeRead(
                section,
                @"sectionHeaderTitle")
            isEqual:@"账号"]) {

            return YES;
        }
    }

    return NO;
}


#pragma mark - Install Douyin Settings Hook

void DYLikeInstallSettingsHook(void) {

    static BOOL installed;

    if (installed) return;


    Class cls =
        NSClassFromString(@"AWESettingsViewModel");

    Class itemClass =
        NSClassFromString(@"AWESettingItemModel");

    Class sectionClass =
        NSClassFromString(@"AWESettingSectionModel");

    SEL selector =
        NSSelectorFromString(@"sectionDataArray");

    Method method =
        class_getInstanceMethod(
            cls,
            selector);

    if (!method ||
        !itemClass ||
        !sectionClass) {

        return;
    }


    NSMethodSignature *signature =
        [NSMethodSignature
            signatureWithObjCTypes:
                method_getTypeEncoding(method)];

    if (signature.numberOfArguments != 2 ||
        signature.methodReturnType[0] != '@') {

        return;
    }


    IMP original =
        method_getImplementation(method);


    IMP replacement =
        imp_implementationWithBlock(^id(id owner) {

        id value =
            ((id (*)(id, SEL))original)(
                owner,
                selector);

        if (![value isKindOfClass:NSArray.class]) {
            return value;
        }

        if (!DYLikeIsMainSettingsPage(owner, value)) {
            return value;
        }


        /*
         防止重复插入。
         */

        for (id section in value) {

            id items =
                DYLikeRead(section, @"itemArray");

            if (![items isKindOfClass:NSArray.class]) {
                continue;
            }

            for (id item in items) {

                if ([DYLikeRead(
                        item,
                        @"identifier")
                    isEqual:
                        @"DYSecondaryConfirmation.Settings"]) {

                    return value;
                }
            }
        }


        id item =
            [itemClass new];

        BOOL valid = YES;


        valid &= DYLikeSet(
            item,
            @"identifier",
            @"DYSecondaryConfirmation.Settings");

        valid &= DYLikeSet(
            item,
            @"title",
            @"AMZZ");

        valid &= DYLikeSet(
            item,
            @"cellType",
            @26);

        valid &= DYLikeSet(
            item,
            @"cellTappedBlock",
            ^{
                DYLikeOpenSettings();
            });

        DYLikeSet(
            item,
            @"detail",
            DYLikeVersion);

        DYLikeSet(
            item,
            @"isEnable",
            @YES);

        DYLikeSet(
            item,
            @"colorStyle",
            @2);

        DYLikeSet(
            item,
            @"svgIconImageName",
            @"ic_gearsimplify_outlined_20");

        DYLikeSet(
            item,
            @"specificIconImage",
            [UIImage
                systemImageNamed:
                    @"checkmark.circle.fill"]);


        id section =
            [sectionClass new];

        valid &= DYLikeSet(
            section,
            @"itemArray",
            @[item]);

        DYLikeSet(
            section,
            @"sectionHeaderTitle",
            @"AMZZ");

        DYLikeSet(
            section,
            @"sectionHeaderHeight",
            @40);


        if (!valid) {
            return value;
        }


        NSMutableArray *sections =
            [value mutableCopy];


        /*
         保留你原来的插入位置逻辑：
         有“账号”就放第二位，
         没有就放第一位。
         */

        NSUInteger insertIndex = 0;

        for (NSUInteger i = 0;
             i < sections.count;
             i++) {

            if ([DYLikeRead(
                    sections[i],
                    @"sectionHeaderTitle")
                isEqual:@"账号"]) {

                insertIndex =
                    (i > 0) ? 1 : 0;

                break;
            }
        }

        if (insertIndex > sections.count) {
            insertIndex = sections.count;
        }

        [sections insertObject:section
                       atIndex:insertIndex];

        return sections;
    });


    class_replaceMethod(
        cls,
        selector,
        replacement,
        method_getTypeEncoding(method));

    installed = YES;
}
