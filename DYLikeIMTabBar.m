// DYLikeIMTabBar.m — TabBar 长按：长按"消息"标已读 / 长按"我"切换账号
// 移植自 Yuki (YukiEnableLongPressMarkAsRead / YukiEnableLongPresQuickSwitchAccount)。
// 签名：AWENormalModeTabBar - (void)layoutSubviews（39.8.0 头文件确认）。
// 原理（可还原部分）：layoutSubviews 时遍历 subviews，找到
// AWENormalModeTabBarGeneralButton，按 accessibilityLabel 区分"消息"/"我"按钮，
// 用 associated object 去重后各加一个 UILongPressGestureRecognizer。
// v1 说明：两个长按动作的具体实现（标已读 / 切账号）未能从逆向产物完整还原，
//       handler 为尽力而为版本：尝试调用 IM 的标已读算子 / 账号切换入口，
//       找不到时静默失败并打日志。真机验证后按需继续深挖。
// 开关：DYLikeTabBarMarkReadEnabledKey / DYLikeTabBarSwitchAccountEnabledKey，默认关闭。

#import "DYLikeCore.h"
#import <objc/runtime.h>

static const void *kAMZZTabBarMarkReadGRKey = &kAMZZTabBarMarkReadGRKey;
static const void *kAMZZTabBarSwitchGRKey = &kAMZZTabBarSwitchGRKey;

// 前向声明（AMZZTabBarProxy 的方法会调用它们，定义在下方）
static void AMZZHandleLongPressMarkAsRead(UILongPressGestureRecognizer *gr);
static void AMZZHandleLongPressQuickSwitch(UILongPressGestureRecognizer *gr);

// 手势中转：UILongPressGestureRecognizer 需要 OC target，这里用单例中转到 C 函数
@interface AMZZTabBarProxy : NSObject
+ (instancetype)shared;
- (void)onMarkRead:(UILongPressGestureRecognizer *)gr;
- (void)onQuickSwitch:(UILongPressGestureRecognizer *)gr;
@end
@implementation AMZZTabBarProxy
+ (instancetype)shared {
    static AMZZTabBarProxy *s; static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [AMZZTabBarProxy new]; });
    return s;
}
- (void)onMarkRead:(UILongPressGestureRecognizer *)gr { AMZZHandleLongPressMarkAsRead(gr); }
- (void)onQuickSwitch:(UILongPressGestureRecognizer *)gr { AMZZHandleLongPressQuickSwitch(gr); }
@end

// ---------- 长按"消息" → 标已读（尽力而为） ----------
static void AMZZHandleLongPressMarkAsRead(UILongPressGestureRecognizer *gr) {
    if (gr.state != UIGestureRecognizerStateBegan) return;
    if (!DYLikeIMFeatureEnabled(DYLikeTabBarMarkReadEnabledKey)) return;
    @try {
        // 尝试：找会话列表并标已读。先试 TIMXMessageMarkAsReadOperator
        Class opCls = objc_getClass("TIMXMessageMarkAsReadOperator");
        id op = nil;
        if (opCls && [opCls respondsToSelector:@selector(sharedInstance)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            op = [opCls performSelector:@selector(sharedInstance)];
#pragma clang diagnostic pop
        }
        if (op) {
            NSLog(@"[DYSecondaryConfirmation] mark-as-read: operator found, conversation list API TBD");
        } else {
            NSLog(@"[DYSecondaryConfirmation] mark-as-read: operator not found");
        }
        // v1：若上面拿不到会话，动作暂不执行（待深挖会话列表 API）
    } @catch (NSException *e) {
        NSLog(@"[DYSecondaryConfirmation] mark-as-read error: %@", e);
    }
}

// ---------- 长按"我" → 切换账号（尽力而为） ----------
static void AMZZHandleLongPressQuickSwitch(UILongPressGestureRecognizer *gr) {
    if (gr.state != UIGestureRecognizerStateBegan) return;
    if (!DYLikeIMFeatureEnabled(DYLikeTabBarSwitchAccountEnabledKey)) return;
    @try {
        // 尝试：找账号管理器的切换入口
        Class mgrCls = objc_getClass("TIMXCurrentUserManager");
        NSLog(@"[DYSecondaryConfirmation] quick-switch: account manager %@, switch UI API TBD",
              mgrCls ? @"found" : @"not found");
        // v1：账号切换需要 Yuki 的自定义 UI（未逆向），暂不执行
    } @catch (NSException *e) {
        NSLog(@"[DYSecondaryConfirmation] quick-switch error: %@", e);
    }
}

static void (*orig_tabBarLayoutSubviews)(id, SEL) = NULL;
static void amzz_tabBarLayoutSubviews(id self, SEL _cmd) {
    orig_tabBarLayoutSubviews(self, _cmd);
    BOOL wantRead = DYLikeIMFeatureEnabled(DYLikeTabBarMarkReadEnabledKey);
    BOOL wantSwitch = DYLikeIMFeatureEnabled(DYLikeTabBarSwitchAccountEnabledKey);
    if (!wantRead && !wantSwitch) return;

    Class btnCls = objc_getClass("AWENormalModeTabBarGeneralButton");
    if (!btnCls) return;
    for (UIView *sub in [(UIView *)self subviews]) {
        if (![sub isKindOfClass:btnCls]) continue;
        NSString *label = sub.accessibilityLabel ?: @"";
        if (wantRead && [label containsString:@"消息"]) {
            if (!objc_getAssociatedObject(sub, kAMZZTabBarMarkReadGRKey)) {
                UILongPressGestureRecognizer *gr = [[UILongPressGestureRecognizer alloc]
                    initWithTarget:[AMZZTabBarProxy shared] action:@selector(onMarkRead:)];
                gr.minimumPressDuration = 0.6;
                [sub addGestureRecognizer:gr];
                objc_setAssociatedObject(sub, kAMZZTabBarMarkReadGRKey, gr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        } else if (wantSwitch && [label isEqualToString:@"我"]) {
            if (!objc_getAssociatedObject(sub, kAMZZTabBarSwitchGRKey)) {
                UILongPressGestureRecognizer *gr = [[UILongPressGestureRecognizer alloc]
                    initWithTarget:[AMZZTabBarProxy shared] action:@selector(onQuickSwitch:)];
                gr.minimumPressDuration = 0.6;
                [sub addGestureRecognizer:gr];
                objc_setAssociatedObject(sub, kAMZZTabBarSwitchGRKey, gr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
}

void DYLikeIMInstallTabBar(void) {
    Class cls = objc_getClass("AWENormalModeTabBar");
    if (!cls) return;
    Method m = class_getInstanceMethod(cls, @selector(layoutSubviews));
    if (m) orig_tabBarLayoutSubviews = (void (*)(id, SEL))method_setImplementation(m, (IMP)amzz_tabBarLayoutSubviews);
    NSLog(@"[DYSecondaryConfirmation] Installed tab-bar hooks");
}
