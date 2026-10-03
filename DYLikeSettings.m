#import <UIKit/UIKit.h>
#import "DYLikeSettings.h"
#import "DYLikeCore.h"
#import <objc/runtime.h>

@interface DYLikeSettingsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSArray *sections;
@end

@implementation DYLikeSettingsViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // 全局暗色背景
    self.view.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.10 alpha:1.0];

    [self setupHeaderView];
    [self setupTableView];
    [self loadSettingsData];
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

    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:headerView.bottomAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)setupTableView {
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.showsVerticalScrollIndicator = NO;
}

- (void)handleBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loadSettingsData {
    self.sections = @[
        @{
            @"title": @"二次确认",
            @"items": @[
                @{ @"title": @"点赞二次确认", @"subtitle": @"防止误触点赞", @"key": DYLikeLikeEnabledKey },
                @{ @"title": @"收藏二次确认", @"subtitle": @"防止误触收藏视频", @"key": DYLikeFavoriteEnabledKey },
                @{ @"title": @"关注二次确认", @"subtitle": @"防止误触关注博主", @"key": DYLikeFollowEnabledKey },
                @{ @"title": @"评论点赞二次确认", @"subtitle": @"防止误触点赞评论", @"key": DYLikeCommentLikeEnabledKey },
                @{ @"title": @"评论点踩二次确认", @"subtitle": @"防止误触点踩评论", @"key": DYLikeCommentDislikeEnabledKey }
            ]
        }
    ];
    [self.tableView reloadData];
}

#pragma mark - TableView Delegate & DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *items = self.sections[section][@"items"];
    return items.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] init];
    header.backgroundColor = [UIColor clearColor];
    UILabel *label = [[UILabel alloc] init];
    label.text = self.sections[section][@"title"];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"AMZZCardCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = UIColor.whiteColor;
        cell.textLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        cell.backgroundColor = [UIColor clearColor];
    }

    NSDictionary *item = self.sections[indexPath.section][@"items"][indexPath.row];
    cell.textLabel.text = item[@"title"];
    cell.detailTextLabel.text = item[@"subtitle"];

    UISwitch *sw = [UISwitch new];
    sw.onTintColor = [UIColor colorWithRed:0.20 green:0.78 blue:0.35 alpha:1.0];
    NSString *key = item[@"key"];
    sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    if (![[NSUserDefaults standardUserDefaults] objectForKey:key]) sw.on = YES;
    sw.tag = indexPath.row;
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;

    // 清理重用
    cell.backgroundView = nil;
    for (UIView *v in [cell.contentView.subviews copy]) {
        if (v.tag == 9999) [v removeFromSuperview];
    }

    return cell;
}

- (void)switchChanged:(UISwitch *)sender {
    NSArray *items = self.sections[0][@"items"];
    if (sender.tag >= 0 && sender.tag < (NSInteger)items.count) {
        NSString *key = items[(NSUInteger)sender.tag][@"key"];
        [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

// 绘制外卡片大圆角与内边距
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
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(margin + 16, cell.bounds.size.height - 0.5, cell.bounds.size.width - (margin * 2) - 32, 0.5)];
        line.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.06];
        line.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        line.tag = 9999;
        [cell.contentView addSubview:line];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64.0;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

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
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [top presentViewController:vc animated:YES completion:nil];
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
