#import "DYLikeSettings.h"
#import "../Core/DYLikeCore.h"
#import "../HideFriends/HFConstants.h"
#import "../HideFriends/HFBlacklistViewController.h"
#import <objc/runtime.h>

// 主题自适应：跟随抖音浅色/深色
static BOOL DYLikeIsLightTheme(void) {
    return DYLikeUserInterfaceStyle() == UIUserInterfaceStyleLight;
}
static UIColor *DYLikeBgColor(void) {
    return DYLikeIsLightTheme() ? UIColor.systemGroupedBackgroundColor :
        [UIColor colorWithRed:0.05 green:0.05 blue:0.06 alpha:1.0];
}
static UIColor *DYLikeCellColor(void) {
    return DYLikeIsLightTheme() ? UIColor.secondarySystemGroupedBackgroundColor :
        [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
}
static UIColor *DYLikeTextColor(void) {
    return DYLikeIsLightTheme() ? UIColor.labelColor : UIColor.whiteColor;
}
static UIColor *DYLikeSubTextColor(void) {
    return DYLikeIsLightTheme() ? UIColor.secondaryLabelColor : [UIColor colorWithWhite:0.6 alpha:1.0];
}
static UIColor *DYLikeSeparatorColor(void) {
    return DYLikeIsLightTheme() ? UIColor.separatorColor : [UIColor colorWithWhite:1.0 alpha:0.08];
}

@implementation DYLikeSettingsViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"AMZZ";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.tableView.rowHeight = 56;
    self.tableView.sectionHeaderHeight = 36;
    self.tableView.showsVerticalScrollIndicator = NO;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applyTheme)
        name:DYLikeThemeDidChangeNotification object:nil];
    [self applyTheme];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyTheme];
    [self.tableView reloadData];
}

- (void)applyTheme {
    BOOL light = DYLikeIsLightTheme();
    self.view.backgroundColor = DYLikeBgColor();
    self.tableView.backgroundColor = DYLikeBgColor();
    self.tableView.separatorColor = DYLikeSeparatorColor();
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = DYLikeBgColor();
    appearance.titleTextAttributes = @{NSForegroundColorAttributeName: DYLikeTextColor()};
    self.navigationItem.standardAppearance = appearance;
    self.navigationItem.scrollEdgeAppearance = appearance;
    self.navigationItem.compactAppearance = appearance;
    self.navigationController.navigationBar.tintColor = DYLikeTextColor();
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return DYLikeIsLightTheme() ? UIStatusBarStyleDarkContent : UIStatusBarStyleLightContent;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"功能";
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:UITableViewHeaderFooterView.class]) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        header.textLabel.textColor = DYLikeSubTextColor();
        header.textLabel.font = [UIFont systemFontOfSize:13];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"AMZZMainCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.textLabel.textColor = DYLikeTextColor();
    cell.backgroundColor = DYLikeCellColor();
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    NSString *iconName = indexPath.row == 0 ? @"checkmark.circle" : @"person.2.circle";
    UIImage *icon = [UIImage systemImageNamed:iconName];
    cell.imageView.image = icon;
    cell.imageView.tintColor = DYLikeTextColor();
    cell.textLabel.text = indexPath.row == 0 ? @"二次确认" : @"抖音密友";
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 0) {
        DYConfirmViewController *vc = [[DYConfirmViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        DYCloseFriendsViewController *vc = [[DYCloseFriendsViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)closeSettings {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

#pragma mark - 二次确认子页面

@implementation DYConfirmViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"二次确认";
    [self applyTheme];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyTheme];
    [self.tableView reloadData];
}

- (void)applyTheme {
    self.view.backgroundColor = DYLikeBgColor();
    self.tableView.backgroundColor = DYLikeBgColor();
    self.tableView.separatorColor = DYLikeSeparatorColor();
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 2; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 3 : 2;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"点赞" : @"互动";
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 1) return @"开启后，抖音对应操作会先显示确认弹窗；设置修改后立即生效。";
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:UITableViewHeaderFooterView.class]) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        header.textLabel.textColor = DYLikeSubTextColor();
        header.textLabel.font = [UIFont systemFontOfSize:13];
    }
}
- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:UITableViewHeaderFooterView.class]) {
        UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
        footer.textLabel.textColor = DYLikeSubTextColor();
        footer.textLabel.font = [UIFont systemFontOfSize:13];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // section 0: 点赞(0) 评论点赞(3) 评论点踩(4)；section 1: 收藏(1) 关注(2)
    static NSArray<NSString *> *titles;
    static NSArray<NSNumber *> *indexMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        titles = @[@"启用点赞二次确认", @"启用收藏二次确认", @"启用关注二次确认", @"启用评论点赞二次确认", @"启用评论点踩二次确认"];
        indexMap = @[@0, @3, @4, @1, @2];
    });
    NSUInteger mapped = [indexMap[(NSUInteger)(indexPath.section * 3 + indexPath.row)] unsignedIntegerValue];
    NSUInteger index = mapped;
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.text = titles[index];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.textLabel.textColor = DYLikeTextColor();
    cell.backgroundColor = DYLikeCellColor();
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UISwitch *toggle = [UISwitch new];
    toggle.on = DYLikeEnabled((DYLikeActionType)index);
    toggle.tag = (NSInteger)index;
    [toggle addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = toggle;
    return cell;
}

- (void)toggleChanged:(UISwitch *)toggle {
    if (toggle.tag < 0 || (NSUInteger)toggle.tag >= DYLikeActionCount) return;
    NSArray<NSString *> *keys = @[DYLikeLikeEnabledKey, DYLikeFavoriteEnabledKey, DYLikeFollowEnabledKey,
        DYLikeCommentLikeEnabledKey, DYLikeCommentDislikeEnabledKey];
    [NSUserDefaults.standardUserDefaults setBool:toggle.isOn forKey:keys[(NSUInteger)toggle.tag]];
}

@end

#pragma mark - 抖音密友子页面

@implementation DYCloseFriendsViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"抖音密友";
    [self applyTheme];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyTheme];
    [self.tableView reloadData];
}

- (void)applyTheme {
    self.view.backgroundColor = DYLikeBgColor();
    self.tableView.backgroundColor = DYLikeBgColor();
    self.tableView.separatorColor = DYLikeSeparatorColor();
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 2; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 1; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"隐藏设置" : @"黑名单";
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:UITableViewHeaderFooterView.class]) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        header.textLabel.textColor = DYLikeSubTextColor();
        header.textLabel.font = [UIFont systemFontOfSize:13];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.textLabel.textColor = DYLikeTextColor();
    cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
    cell.detailTextLabel.textColor = DYLikeSubTextColor();
    cell.backgroundColor = DYLikeCellColor();
    if (indexPath.section == 0) {
        cell.textLabel.text = @"隐藏好友";
        cell.detailTextLabel.text = @"开启后隐藏黑名单好友相关内容";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UISwitch *toggle = [UISwitch new];
        toggle.on = HFGetBool(HF_KEY_HIDE_ALL_FRIENDS);
        [toggle addTarget:self action:@selector(hfToggleChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggle;
    } else {
        cell.textLabel.text = @"添加好友";
        cell.detailTextLabel.text = @"添加或移除要隐藏的好友";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (void)hfToggleChanged:(UISwitch *)toggle {
    HFSetBool(HF_KEY_HIDE_ALL_FRIENDS, toggle.isOn);
    [[NSNotificationCenter defaultCenter] postNotificationName:HF_SETTINGS_DID_CHANGE_NOTIFICATION object:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        HFBlacklistViewController *vc = [[HFBlacklistViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
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
