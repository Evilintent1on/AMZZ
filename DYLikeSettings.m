#import "DYLikeSettings.h"
#import "../Core/DYLikeCore.h"
#import <objc/runtime.h>

@implementation DYLikeSettingsViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"AMZZ";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.tableView.separatorColor = UIColor.separatorColor;
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateTheme];
    [self.tableView reloadData];
}

- (void)updateTheme {
    UIUserInterfaceStyle style = DYLikeUserInterfaceStyle();
    if (self.overrideUserInterfaceStyle != style) self.overrideUserInterfaceStyle = style;
    UITraitCollection *theme = [UITraitCollection traitCollectionWithUserInterfaceStyle:self.overrideUserInterfaceStyle];
    UINavigationBarAppearance *appearance = [UINavigationBarAppearance new];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = [UIColor.systemGroupedBackgroundColor resolvedColorWithTraitCollection:theme];
    appearance.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor.labelColor resolvedColorWithTraitCollection:theme]};
    self.navigationItem.standardAppearance = appearance;
    self.navigationItem.scrollEdgeAppearance = appearance;
    self.navigationItem.compactAppearance = appearance;
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return DYLikeActionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"功能开关";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"开启后，抖音对应操作会先显示确认弹窗；设置修改后立即生效。";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSArray<NSString *> *titles;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        titles = @[@"启用点赞二次确认", @"启用收藏二次确认", @"启用关注二次确认", @"启用评论点赞二次确认", @"启用评论点踩二次确认"];
    });

    NSUInteger index = (NSUInteger)indexPath.row;
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                    reuseIdentifier:nil];
    cell.textLabel.text = titles[index];
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    cell.textLabel.adjustsFontForContentSizeCategory = YES;
    cell.textLabel.textColor = UIColor.labelColor;
    cell.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    UISwitch *toggle = [UISwitch new];
    toggle.on = DYLikeEnabled((DYLikeActionType)index);
    toggle.tag = (NSInteger)index;
    toggle.accessibilityLabel = titles[index];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
        // 插在原生"账号"分区前面：有插件时跟在所有插件后面，无插件时置顶
        NSUInteger insertIndex = 0;
        for (NSUInteger i = 0; i < sections.count; i++) {
            if ([DYLikeRead(sections[i], @"sectionHeaderTitle") isEqual:@"账号"]) {
                insertIndex = i;
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
