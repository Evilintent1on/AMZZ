#import "DYLikeSettings.h"
#import <UIKit/UIKit.h>

static NSString *const kDYLikeSuiteName = @"com.apple.Preferences";

// 使用 extern "C" 确保导出符号与 DYLikeHooks.m 匹配
#ifdef __cplusplus
extern "C" {
#endif

FOUNDATION_EXPORT BOOL DYLikeGetBoolPref(NSString *key, BOOL defaultValue) {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kDYLikeSuiteName] ?: [NSUserDefaults standardUserDefaults];
    id obj = [defaults objectForKey:key];
    return obj ? [obj boolValue] : defaultValue;
}

FOUNDATION_EXPORT void DYLikeSetBoolPref(NSString *key, BOOL value) {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kDYLikeSuiteName] ?: [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:key];
    [defaults synchronize];
}

FOUNDATION_EXPORT void DYLikeInstallSettingsHook(void) {
    // 保持空实现，提供给外部 Hook 初始化调用
}

#ifdef __cplusplus
}
#endif

@implementation DYLikeSettingsViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"二次确认设置";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                             target:self
                             action:@selector(dismissSelf)];
}

- (void)dismissSelf {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TableView Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"DYLikeSettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    UISwitch *switchControl = [UISwitch new];
    switchControl.onTintColor = [UIColor systemGreenColor];
    switchControl.tag = indexPath.row;
    [switchControl addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = switchControl;

    if (indexPath.row == 0) {
        cell.textLabel.text = @"点赞二次确认";
        cell.detailTextLabel.text = @"开启后，双击或点击点赞图标将弹出确认框";
        switchControl.on = DYLikeGetBoolPref(@"DYLikeEnableConfirm", YES);
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"收藏二次确认";
        cell.detailTextLabel.text = @"开启后，点击收藏图标将弹出确认框";
        switchControl.on = DYLikeGetBoolPref(@"DYFavoriteEnableConfirm", YES);
    } else if (indexPath.row == 2) {
        cell.textLabel.text = @"关注二次确认";
        cell.detailTextLabel.text = @"开启后，点击关注按钮将弹出确认框";
        switchControl.on = DYLikeGetBoolPref(@"DYFollowEnableConfirm", YES);
    }

    return cell;
}

#pragma mark - Actions

- (void)switchChanged:(UISwitch *)sender {
    if (sender.tag == 0) {
        DYLikeSetBoolPref(@"DYLikeEnableConfirm", sender.isOn);
    } else if (sender.tag == 1) {
        DYLikeSetBoolPref(@"DYFavoriteEnableConfirm", sender.isOn);
    } else if (sender.tag == 2) {
        DYLikeSetBoolPref(@"DYFollowEnableConfirm", sender.isOn);
    }
}

@end
