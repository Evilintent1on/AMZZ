#import "DYLikeSettings.h"
#import <UIKit/UIKit.h>

static NSString *const kDYLikeSuiteName = @"com.apple.Preferences";

static BOOL DYLikeReadBool(NSString *key, BOOL defaultValue) {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kDYLikeSuiteName] ?: [NSUserDefaults standardUserDefaults];
    id obj = [defaults objectForKey:key];
    return obj ? [obj boolValue] : defaultValue;
}

static void DYLikeWriteBool(NSString *key, BOOL value) {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kDYLikeSuiteName] ?: [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:key];
    [defaults synchronize];
}

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
    // 使用 iOS 系统原生绿色开关
    switchControl.onTintColor = [UIColor systemGreenColor];
    switchControl.tag = indexPath.row;
    [switchControl addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = switchControl;

    if (indexPath.row == 0) {
        cell.textLabel.text = @"点赞二次确认";
        cell.detailTextLabel.text = @"开启后，双击或点击点赞图标将弹出确认框";
        switchControl.on = DYLikeReadBool(@"DYLikeEnableConfirm", YES);
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"收藏二次确认";
        cell.detailTextLabel.text = @"开启后，点击收藏图标将弹出确认框";
        switchControl.on = DYLikeReadBool(@"DYFavoriteEnableConfirm", YES);
    } else if (indexPath.row == 2) {
        cell.textLabel.text = @"关注二次确认";
        cell.detailTextLabel.text = @"开启后，点击关注按钮将弹出确认框";
        switchControl.on = DYLikeReadBool(@"DYFollowEnableConfirm", YES);
    }

    return cell;
}

#pragma mark - Actions

- (void)switchChanged:(UISwitch *)sender {
    if (sender.tag == 0) {
        DYLikeWriteBool(@"DYLikeEnableConfirm", sender.isOn);
    } else if (sender.tag == 1) {
        DYLikeWriteBool(@"DYFavoriteEnableConfirm", sender.isOn);
    } else if (sender.tag == 2) {
        DYLikeWriteBool(@"DYFollowEnableConfirm", sender.isOn);
    }
}

@end
