#import "DYLikeSettings.h"
#import "DYLikeCore.h"

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
        cell = [[UITableViewCell alloc]从报错信息来看，项目原本并没有在 `DYLikeSettingsViewController` 里声明 `tableView` 属性，直接全量覆盖导致了编译失败。

请先**撤销 `DYLikeSettings.m` 的修改（恢复到之前的原始版本）**。要实现将开关颜色改为系统默认，只需要精准找到原始文件里自定义颜色的那几行代码并替换即可。

### 解决办法：全局搜索并修改

请在你的工程中搜索 **`onTintColor`**，找到设置颜色的位置。

#### 1. 原始代码样式（导致红/黄色的代码）
原始代码中通常有类似下面这样的逻辑，给不同的操作设置了特定的 RGB 颜色：

```objc
// ❌ 原始代码里类似这样的结构
if (action == DYLikeActionLike) {
    switchControl.onTintColor = [UIColor colorWithRed:254/255.0 green:44/255.0 blue:85/255.0 alpha:1.0]; // 红色
} else if (action == DYLikeActionFavorite) {
    switchControl.onTintColor = [UIColor colorWithRed:250/255.0 green:166/255.0 blue:26/255.0 alpha:1.0]; // 黄色
}
