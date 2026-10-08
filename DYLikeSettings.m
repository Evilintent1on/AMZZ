#import "DYLikeSettings.h"
#import "../Core/DYLikeCore.h"
#import <objc/runtime.h>

@implementation DYLikeSettingsViewController {
    UIView *_amzzHeader;
    UIImageView *_amzzBackArrow;
    UILabel *_amzzTitleLabel;
}

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 隐藏系统导航栏，用插件自己的头部（完全控制，无玻璃）
    self.navigationController.navigationBarHidden = YES;
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.tableView.separatorColor = UIColor.separatorColor;
    // 关掉系统自动安全区适配，避免和手动 contentInset 叠加导致大空隙
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 58;
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.tableView.sectionFooterHeight = UITableViewAutomaticDimension;
    self.tableView.showsVerticalScrollIndicator = NO;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateTheme)
        name:DYLikeThemeDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateTheme)
        name:UIApplicationDidBecomeActiveNotification object:nil];
    [self updateTheme];
    [self setupAmzzHeader];
}

// 插件自己的头部：返回箭头 + AMZZ 标题，无玻璃
- (void)setupAmzzHeader {
    if (_amzzHeader) return;
    UIView *header = [[UIView alloc] init];
    header.backgroundColor = UIColor.systemGroupedBackgroundColor;
    // 初始 frame，y 会在 layout 和滚动时修正
    header.frame = CGRectMake(0, -100, 100, 100);
    [self.tableView addSubview:header];
    _amzzHeader = header;

    UIImageView *arrow = [[UIImageView alloc] initWithImage:
        [[UIImage systemImageNamed:@"chevron.left"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    arrow.tintColor = UIColor.labelColor;
    arrow.contentMode = UIViewContentModeScaleAspectFit;
    arrow.userInteractionEnabled = YES;
    [arrow addGestureRecognizer:[[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(amzzGoBackTap:)]];
    [header addSubview:arrow];
    _amzzBackArrow = arrow;

    UILabel *title = [[UILabel alloc] init];
    title.text = @"AMZZ";
    title.font = [UIFont boldSystemFontOfSize:17];
    title.textColor = UIColor.labelColor;
    title.textAlignment = NSTextAlignmentCenter;
    [header addSubview:title];
    _amzzTitleLabel = title;

    [self layoutAmzzHeader];
}

// 头部布局：只更新宽高和内部位置，y 由 scrollViewDidScroll 管理
- (void)layoutAmzzHeader {
    if (!_amzzHeader) return;
    CGFloat statusH = self.view.safeAreaInsets.top;
    if (statusH < 20) {
        UIWindow *win = self.view.window;
        if (win) statusH = win.safeAreaInsets.top;
        if (statusH < 20) statusH = 59;
    }
    CGFloat headerH = statusH + 44;
    CGFloat w = self.view.bounds.size.width;
    // 只调宽高，不动 y（避免和 scrollViewDidScroll 打架）
    CGRect f = _amzzHeader.frame;
    f.size.width = w;
    f.size.height = headerH;
    _amzzHeader.frame = f;
    _amzzHeader.backgroundColor = UIColor.systemGroupedBackgroundColor;
    _amzzBackArrow.frame = CGRectMake(14, statusH + 11, 22, 22);
    _amzzTitleLabel.frame = CGRectMake(0, statusH, w, 44);
    // contentInset 只设一次，避免重复设置导致跳动
    UIEdgeInsets current = self.tableView.contentInset;
    if (fabs(current.top - headerH) > 0.5) {
        self.tableView.contentInset = UIEdgeInsetsMake(headerH, 0, 0, 0);
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutAmzzHeader];
}

// 头部跟随滚动固定在顶部
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_amzzHeader) {
        CGRect f = _amzzHeader.frame;
        f.origin.x = scrollView.contentOffset.x;
        f.origin.y = scrollView.contentOffset.y;
        _amzzHeader.frame = f;
        [self.tableView bringSubviewToFront:_amzzHeader];
    }
}

- (void)amzzGoBackTap:(UITapGestureRecognizer *)gesture {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 隐藏系统导航栏，用插件自己的头部
    self.navigationController.navigationBarHidden = YES;
    [self updateTheme];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 初始定位头部 y
    if (_amzzHeader) {
        CGRect f = _amzzHeader.frame;
        f.origin.x = self.tableView.contentOffset.x;
        f.origin.y = self.tableView.contentOffset.y;
        _amzzHeader.frame = f;
        [self.tableView bringSubviewToFront:_amzzHeader];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 恢复系统导航栏，避免影响抖音其他页面
    self.navigationController.navigationBarHidden = NO;
}

- (void)updateTheme {
    UIUserInterfaceStyle style = DYLikeUserInterfaceStyle();
    if (self.overrideUserInterfaceStyle != style) self.overrideUserInterfaceStyle = style;
    // 刷新自定义头部颜色
    if (_amzzHeader) {
        _amzzHeader.backgroundColor = UIColor.systemGroupedBackgroundColor;
        _amzzBackArrow.tintColor = UIColor.labelColor;
        _amzzTitleLabel.textColor = UIColor.labelColor;
    }
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self updateTheme];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return DYLikeUserInterfaceStyle() == UIUserInterfaceStyleDark ? UIStatusBarStyleLightContent : UIStatusBarStyleDarkContent;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) return 12; // 私信增强
    if (section == 2) return 4;  // 其他功能
    return DYLikeActionCount;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] init];
    UILabel *label = [[UILabel alloc] init];
    label.text = section == 1 ? @"私信增强" : (section == 2 ? @"其他功能" : @"二次确认");
    label.font = [UIFont systemFontOfSize:13];
    label.textColor = [UIColor secondaryLabelColor];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20],
        [label.topAnchor constraintEqualToAnchor:header.topAnchor constant:2],
        [label.bottomAnchor constraintEqualToAnchor:header.bottomAnchor constant:-2]
    ]];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    return 22;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 1) return @"私信相关增强功能，全部默认关闭，按需开启；设置修改后立即生效。";
    if (section == 2) return @"“自动消息任务”行点进去可配置定时任务；设置修改后立即生效。";
    return @"开启后，抖音对应操作会先显示确认弹窗；设置修改后立即生效。";
}

void DYLikeIMOpenAutoMsgConfig(UIViewController *from);

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSArray<NSString *> *titles;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        titles = @[@"启用点赞二次确认", @"启用收藏二次确认", @"启用关注二次确认", @"启用评论点赞二次确认", @"启用评论点踩二次确认"];
    });
    // 私信增强：10 个开关 + 2 个点选行
    static NSArray<NSString *> *imTitles;
    static NSArray<NSString *> *imKeys;
    static dispatch_once_t imToken;
    dispatch_once(&imToken, ^{
        imTitles = @[@"启用私信防撤回", @"启用语音自动转文字", @"隐身：隐藏在线状态", @"启用语音转发",
                     @"阅后即焚防销毁", @"左滑引用回复", @"隐藏聊天自带时间", @"显示自定义时间标签",
                     @"摇骰子/猜拳", @"自定义语音时长"];
        imKeys = @[DYLikeAntiRecallEnabledKey, DYLikeVoiceTranslateEnabledKey, DYLikeStealthEnabledKey,
                   DYLikeAudioShareEnabledKey, DYLikeWatchOnceEnabledKey, DYLikeSwipeQuoteEnabledKey,
                   DYLikeHideTimeEnabledKey, DYLikeCustomTimeEnabledKey,
                   DYLikeDiceEnabledKey, DYLikeAudioDurationEnabledKey];
    });
    // 其他功能
    static NSArray<NSString *> *miscTitles;
    static NSArray<NSString *> *miscKeys;
    static dispatch_once_t miscToken;
    dispatch_once(&miscToken, ^{
        miscTitles = @[@"长按“消息”标已读", @"长按“我”切换账号", @"作品显示发布时间", @"自动消息任务"];
        miscKeys = @[DYLikeTabBarMarkReadEnabledKey, DYLikeTabBarSwitchAccountEnabledKey,
                     DYLikePublishDateEnabledKey, DYLikeAutoMsgEnabledKey];
    });

    // 点选行：时间标签颜色 / 语音时长
    if (indexPath.section == 1 && (indexPath.row == 8 || indexPath.row == 11)) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                                        reuseIdentifier:nil];
        cell.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
        cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        cell.textLabel.textColor = UIColor.labelColor;
        if (indexPath.row == 8) {
            cell.textLabel.text = @"时间标签颜色";
            cell.detailTextLabel.text = [[NSUserDefaults standardUserDefaults]
                stringForKey:DYLikeTimeLabelColorKey] ?: @"跟随系统";
        } else {
            cell.textLabel.text = @"语音时长";
            NSString *sec = [[NSUserDefaults standardUserDefaults]
                stringForKey:DYLikeAudioDurationSecKey] ?: @"15";
            cell.detailTextLabel.text = [sec isEqualToString:@"5~15"] ? @"随机5~15秒"
                : [NSString stringWithFormat:@"%@秒", sec];
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                    reuseIdentifier:nil];
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    cell.textLabel.adjustsFontForContentSizeCategory = YES;
    cell.textLabel.textColor = UIColor.labelColor;
    cell.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    UISwitch *toggle = [UISwitch new];
    [toggle addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];

    if (indexPath.section == 1) {
        // 私信增强开关行（row 8/11 是点选行，已在上面返回）
        // 映射：row0-7→0-7，row9→8(骰子)，row10→9(时长开关)
        NSInteger mapped = indexPath.row <= 7 ? indexPath.row : indexPath.row - 1;
        cell.textLabel.text = imTitles[mapped];
        NSString *key = imKeys[mapped];
        toggle.on = [key isEqualToString:DYLikeAntiRecallEnabledKey]
            ? DYLikeAntiRecallEnabled() : DYLikeIMFeatureEnabled(key);
        toggle.tag = 1000 + mapped;
        toggle.accessibilityLabel = imTitles[mapped];
    } else if (indexPath.section == 2) {
        NSUInteger index = (NSUInteger)indexPath.row;
        cell.textLabel.text = miscTitles[index];
        toggle.on = DYLikeIMFeatureEnabled(miscKeys[index]);
        toggle.tag = 1100 + (NSInteger)index;
        toggle.accessibilityLabel = miscTitles[index];
        if (index == 3) {
            // 自动消息任务：开关 + 点行进配置
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            // 开关放 accessoryView 会挤掉箭头，改放 contentView 右侧由 toggleChanged 处理
        }
    } else {
        NSUInteger index = (NSUInteger)indexPath.row;
        cell.textLabel.text = titles[index];
        toggle.on = DYLikeEnabled((DYLikeActionType)index);
        toggle.tag = (NSInteger)index;
        toggle.accessibilityLabel = titles[index];
    }
    cell.accessoryView = toggle;
    return cell;
}

- (void)toggleChanged:(UISwitch *)toggle {
    if (toggle.tag >= 1100 && toggle.tag < 1200) {
        static NSArray<NSString *> *miscKeys2;
        static dispatch_once_t t;
        dispatch_once(&t, ^{
            miscKeys2 = @[DYLikeTabBarMarkReadEnabledKey, DYLikeTabBarSwitchAccountEnabledKey,
                          DYLikePublishDateEnabledKey, DYLikeAutoMsgEnabledKey];
        });
        NSInteger i = toggle.tag - 1100;
        if (i >= 0 && i < (NSInteger)miscKeys2.count)
            [NSUserDefaults.standardUserDefaults setBool:toggle.isOn forKey:miscKeys2[i]];
        return;
    }
    if (toggle.tag >= 1000 && toggle.tag < 1100) {
        static NSArray<NSString *> *imKeys2;
        static dispatch_once_t t2;
        dispatch_once(&t2, ^{
            imKeys2 = @[DYLikeAntiRecallEnabledKey, DYLikeVoiceTranslateEnabledKey, DYLikeStealthEnabledKey,
                        DYLikeAudioShareEnabledKey, DYLikeWatchOnceEnabledKey, DYLikeSwipeQuoteEnabledKey,
                        DYLikeHideTimeEnabledKey, DYLikeCustomTimeEnabledKey,
                        DYLikeDiceEnabledKey, DYLikeAudioDurationEnabledKey];
        });
        NSInteger i = toggle.tag - 1000;
        if (i >= 0 && i < (NSInteger)imKeys2.count)
            [NSUserDefaults.standardUserDefaults setBool:toggle.isOn forKey:imKeys2[i]];
        return;
    }
    if (toggle.tag < 0 || (NSUInteger)toggle.tag >= DYLikeActionCount) return;
    NSArray<NSString *> *keys = @[DYLikeLikeEnabledKey, DYLikeFavoriteEnabledKey, DYLikeFollowEnabledKey,
        DYLikeCommentLikeEnabledKey, DYLikeCommentDislikeEnabledKey];
    [NSUserDefaults.standardUserDefaults setBool:toggle.isOn forKey:keys[(NSUInteger)toggle.tag]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1 && indexPath.row == 8) {
        // 时间标签颜色循环
        NSArray<NSString *> *presets = @[@"跟随系统", @"灰色", @"白色", @"黑色", @"蓝色", @"红色"];
        NSString *cur = [[NSUserDefaults standardUserDefaults] stringForKey:DYLikeTimeLabelColorKey] ?: @"跟随系统";
        NSUInteger i = [presets indexOfObject:cur];
        NSString *next = presets[(i + 1) % presets.count];
        [[NSUserDefaults standardUserDefaults] setObject:next forKey:DYLikeTimeLabelColorKey];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    } else if (indexPath.section == 1 && indexPath.row == 11) {
        // 语音时长循环
        NSArray<NSString *> *presets = @[@"10", @"15", @"30", @"60", @"5~15"];
        NSString *cur = [[NSUserDefaults standardUserDefaults] stringForKey:DYLikeAudioDurationSecKey] ?: @"15";
        NSUInteger i = [presets indexOfObject:cur];
        NSString *next = presets[(i + 1) % presets.count];
        [[NSUserDefaults standardUserDefaults] setObject:next forKey:DYLikeAudioDurationSecKey];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    } else if (indexPath.section == 2 && indexPath.row == 3) {
        // 自动消息任务配置
        DYLikeIMOpenAutoMsgConfig(self);
    }
}

- (void)closeSettings {
    [self dismissViewControllerAnimated:YES completion:nil];
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
            // 无返回按钮，顶部只保留 AMZZ
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
