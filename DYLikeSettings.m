#import "DYLikeSettings.h"
#import "DYLikeCore.h"
#import <objc/runtime.h>

@interface DYLikeSettingsViewController ()
@property (nonatomic, strong) UIVisualEffectView *blurEffectView;
@property (nonatomic, strong) UIVisualEffectView *vibrancyEffectView;
@end

@implementation DYLikeSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"AMZZ";
    [self setupAppearance];
    [self setupBlurEffect];
    [self setupTableView];
}

#pragma mark - DYYY UI 移植

- (void)setupAppearance {
    // DYYY 风格：透明导航栏 + 白色大标题
    self.navigationController.navigationBar.barTintColor = [UIColor clearColor];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.largeTitleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
}

- (void)setupBlurEffect {
    // DYYY 风格：深色毛玻璃背景
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.blurEffectView.frame = self.view.bounds;
    self.blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.blurEffectView];

    UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
    self.vibrancyEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
    self.vibrancyEffectView.frame = self.blurEffectView.bounds;
    self.vibrancyEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.blurEffectView.contentView addSubview:self.vibrancyEffectView];

    UIView *overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
    overlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:overlayView];
}

- (void)setupTableView {
    // DYYY 风格：InsetGrouped + 透明背景 + 无分隔线
    // 注意：initWithStyle 在 init 里已指定，这里只配置
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
}

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    return self;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"二次确认";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"DYLikeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        // DYYY 风格：cell 透明背景，靠 InsetGrouped 系统卡片
        cell.backgroundColor = [UIColor clearColor];
    }

    NSArray *titles = @[@"点赞二次确认", @"关注二次确认", @"收藏二次确认", @"评论点赞二次确认", @"评论点踩二次确认"];
    NSArray *keys = @[DYLikeLikeEnabledKey, DYLikeFollowEnabledKey, DYLikeFavoriteEnabledKey, DYLikeCommentLikeEnabledKey, DYLikeCommentDislikeEnabledKey];

    NSUInteger idx = (NSUInteger)indexPath.row;
    cell.textLabel.text = titles[idx];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    UISwitch *sw = [[UISwitch alloc] init];
    sw.on = [NSUserDefaults.standardUserDefaults boolForKey:keys[idx]];
    // 默认 YES（首次未设置时）
    if (![NSUserDefaults.standardUserDefaults objectForKey:keys[idx]]) sw.on = YES;
    sw.tag = idx;
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;

    return cell;
}

- (void)switchChanged:(UISwitch *)sw {
    NSArray *keys = @[DYLikeLikeEnabledKey, DYLikeFollowEnabledKey, DYLikeFavoriteEnabledKey, DYLikeCommentLikeEnabledKey, DYLikeCommentDislikeEnabledKey];
    [NSUserDefaults.standardUserDefaults setBool:sw.isOn forKey:keys[sw.tag]];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"开启后，抖音对应操作会先显示确认弹窗。";
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
