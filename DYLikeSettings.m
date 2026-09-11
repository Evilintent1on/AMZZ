#import "DYLikeSettings.h"
#import <UIKit/UIKit.h>

// 声明配置读取与写入 C 函数
FOUNDATION_EXPORT BOOL DYLikeGetBoolPref(NSString *key, BOOL defaultValue);
FOUNDATION_EXPORT void DYLikeSetBoolPref(NSString *key, BOOL value);

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
    // 使用 iOS 系统原生绿色
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
