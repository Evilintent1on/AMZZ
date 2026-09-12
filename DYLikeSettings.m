#import "DYLikeSettings.h"
#import "DYLikeCore.h"
#import <UIKit/UIKit.h>

static NSString *const kDYLikePreferenceDomain = @"com.apple.Preferences";
static NSString *const kDYLikeEnabledLikeKey = @"DYLikeEnabled_Like";
static NSString *const kDYLikeEnabledFavoriteKey = @"DYLikeEnabled_Favorite";
static NSString *const kDYLikeEnabledFollowKey = @"DYLikeEnabled_Follow";

static BOOL DYLikeReadBool(NSString *key, BOOL defaultValue) {
    Boolean keyExists = false;
    Boolean value = CFPreferencesGetAppBooleanValue((__bridge CFStringRef)key, (__bridge CFStringRef)kDYLikePreferenceDomain, &keyExists);
    return keyExists ? (BOOL)value : defaultValue;
}

static void DYLikeWriteBool(NSString *key, BOOL value) {
    CFPreferencesSetAppValue((__bridge CFStringRef)key, value ? kCFBooleanTrue : kCFBooleanFalse, (__bridge CFStringRef)kDYLikePreferenceDomain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)kDYLikePreferenceDomain);
}

BOOL DYLikeIsLikeConfirmationEnabled(void) {
    return DYLikeReadBool(kDYLikeEnabledLikeKey, YES);
}

BOOL DYLikeIsFavoriteConfirmationEnabled(void) {
    return DYLikeReadBool(kDYLikeEnabledFavoriteKey, YES);
}

BOOL DYLikeIsFollowConfirmationEnabled(void) {
    return DYLikeReadBool(kDYLikeEnabledFollowKey, YES);
}

void DYLikeSetLikeConfirmationEnabled(BOOL enabled) {
    DYLikeWriteBool(kDYLikeEnabledLikeKey, enabled);
}

void DYLikeSetFavoriteConfirmationEnabled(BOOL enabled) {
    DYLikeWriteBool(kDYLikeEnabledFavoriteKey, enabled);
}

void DYLikeSetFollowConfirmationEnabled(BOOL enabled) {
    DYLikeWriteBool(kDYLikeEnabledFollowKey, enabled);
}

@interface DYLikeSettingsViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong) UITableView *tableView;
@end

@implementation DYLikeSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"DYLike 设置";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"功能开关";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"开启后，抖音对应操作会先显示确认弹窗；设置修改后立即生效。";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"DYLikeSettingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableView问题出在之前直接全量覆盖文件时，破坏了原作者在 `DYLikeSettings.h` 或 `DYLikeCore.h` 中定义的原生函数名和结构。

为了让你无需反复测试，这里提供**最小化精准修改方法**。由于你原有的代码结构能成功编译，你**不需要替换整个文件**，只需改动 `DYLikeSettings.m` 里的 **2 行代码**（或直接删除自定义颜色逻辑）。

---

### 精准修改指引

请在你的 **`DYLikeSettings.m`** 中定位到控制开关颜色的位置（在文件中搜索 `onTintColor`）：

#### 1. 找到原始代码中类似下面的逻辑（原作者给开关设置颜色的地方）：

```objc
// ❌ 原始代码中将点赞设为红/收藏设为黄/关注设为灰色的部分
if (...) {
    switchView.onTintColor = [UIColor colorWithRed:...]; 
} else if (...) {
    switchView.onTintColor = [UIColor colorWithRed:...]; 
}
