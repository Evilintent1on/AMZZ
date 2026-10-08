// DYLikeIMAutoMsg.m — 自动消息任务
// 移植自 Yuki（定时群发）。逆向文案佐证的功能：
//   "每天首次启动抖音将向列表中的会话发送消息" / "向左滑动可以删除对应任务" /
//   "发送内容" / "从好友列表中选择生效会话"
// v1 说明：任务管理 UI（增/删/开关）与每日触发器为完整实现；
//       真正的"发消息到指定会话" API 未能从逆向产物还原，发送函数为尽力而为版本
//       （尝试 TIMX 系发送链路，失败则打日志）。待 dsh 继续逆向发送 API 后补完。
// 存储：NSUserDefaults[DYLikeAutoMsgTasksKey] = @[ @{@"content":..., @"conv":..., @"on":@YES} ]
// 开关：DYLikeAutoMsgEnabledKey，默认关闭。

#import "DYLikeCore.h"
#import <objc/runtime.h>

static NSString *const kTasksKey = @"DYLikeAutoMsgTasks";
static NSString *const kLastRunKey = @"DYLikeAutoMsgLastRun";

// ---------- 任务存取 ----------
static NSMutableArray *AMZZLoadTasks(void) {
    NSArray *a = [[NSUserDefaults standardUserDefaults] arrayForKey:kTasksKey];
    return a ? [a mutableCopy] : [NSMutableArray array];
}
static void AMZZSaveTasks(NSArray *tasks) {
    [[NSUserDefaults standardUserDefaults] setObject:tasks forKey:kTasksKey];
}

// ---------- 发送（尽力而为，v1 未闭环） ----------
static BOOL AMZZSendTextToConversation(NSString *text, NSString *convID) {
    if (text.length == 0 || convID.length == 0) return NO;
    @try {
        // 尝试1：经 TIMXOSendMessage 构造消息（setContent: 签名已确认）
        Class sendMsgCls = objc_getClass("TIMXOSendMessage");
        NSLog(@"[DYSecondaryConfirmation] automsg send: TIMXOSendMessage %@, send API TBD (text=%@ conv=%@)",
              sendMsgCls ? @"found" : @"missing", text, convID);
        // v1：发送链路待 dsh 逆向补完，这里只记录意图
        return NO;
    } @catch (NSException *e) {
        NSLog(@"[DYSecondaryConfirmation] automsg send error: %@", e);
        return NO;
    }
}

// ---------- 每日触发 ----------
static void AMZZCheckDaily(id _self) {
    if (!DYLikeIMFeatureEnabled(DYLikeAutoMsgEnabledKey)) return;
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDate *now = NSDate.date;
    NSDate *last = [[NSUserDefaults standardUserDefaults] objectForKey:kLastRunKey];
    if (last && [cal isDate:last inSameDayAsDate:now]) return; // 今天已跑过
    [[NSUserDefaults standardUserDefaults] setObject:now forKey:kLastRunKey];
    NSArray *tasks = AMZZLoadTasks();
    for (NSDictionary *t in tasks) {
        if (![t[@"on"] boolValue]) continue;
        AMZZSendTextToConversation(t[@"content"], t[@"conv"]);
    }
    NSLog(@"[DYSecondaryConfirmation] automsg daily check done (%lu tasks)", (unsigned long)tasks.count);
}

// ---------- 任务列表 UI ----------
@interface AMZZAutoMsgVC : UITableViewController
@end
@implementation AMZZAutoMsgVC {
    NSMutableArray *_tasks;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"自动消息任务";
    _tasks = AMZZLoadTasks();
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                     target:self action:@selector(addTask)];
    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                     target:self action:@selector(close)];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"c"];
}
- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return _tasks.count; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [t dequeueReusableCellWithIdentifier:@"c" forIndexPath:ip];
    NSDictionary *task = _tasks[ip.row];
    c.textLabel.text = task[@"content"];
    c.detailTextLabel.text = [NSString stringWithFormat:@"会话:%@ %@", task[@"conv"],
                              [task[@"on"] boolValue] ? @"·开" : @"·关"];
    c.textLabel.font = [UIFont systemFontOfSize:15];
    return c;
}
- (BOOL)tableView:(UITableView *)t canEditRowAtIndexPath:(NSIndexPath *)ip { return YES; }
- (void)tableView:(UITableView *)t commitEditingStyle:(UITableViewCellEditingStyle)s
    forRowAtIndexPath:(NSIndexPath *)ip {
    if (s == UITableViewCellEditingStyleDelete) {
        [_tasks removeObjectAtIndex:ip.row];
        AMZZSaveTasks(_tasks);
        [t deleteRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}
- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip {
    // 点一行切换开关
    NSMutableDictionary *task = [_tasks[ip.row] mutableCopy];
    task[@"on"] = @(![task[@"on"] boolValue]);
    _tasks[ip.row] = task;
    AMZZSaveTasks(_tasks);
    [t reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationNone];
    [t deselectRowAtIndexPath:ip animated:YES];
}
- (void)addTask {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"新建任务"
        message:@"每天首次启动抖音时，向指定会话发送内容" preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField *tf){ tf.placeholder = @"发送内容"; }];
    [ac addTextFieldWithConfigurationHandler:^(UITextField *tf){ tf.placeholder = @"会话 ID"; }];
    [ac addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) ws = self;
    [ac addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *a) {
            NSString *content = ac.textFields[0].text, *conv = ac.textFields[1].text;
            if (content.length == 0 || conv.length == 0) return;
            [ws->_tasks addObject:@{@"content":content, @"conv":conv, @"on":@YES}];
            AMZZSaveTasks(ws->_tasks);
            [ws.tableView reloadData];
        }]];
    [self presentViewController:ac animated:YES completion:nil];
}
@end

// 供设置页调用：弹出任务配置页
void DYLikeIMOpenAutoMsgConfig(UIViewController *from) {
    AMZZAutoMsgVC *vc = [AMZZAutoMsgVC new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [from presentViewController:nav animated:YES completion:nil];
}

void DYLikeIMInstallAutoMsg(void) {
    // 每天首次进前台时检查
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
        object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
            AMZZCheckDaily(nil);
        }];
    NSLog(@"[DYSecondaryConfirmation] Installed auto-msg scheduler");
}
