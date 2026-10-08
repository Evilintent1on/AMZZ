// DYLikeIMVoiceTranslate.m — 语音自动转文字
// 移植自 Yuki (YukiEnableAutoTranslateAudio)。
// 签名（39.8.0 头文件确认）：
//   AWEIMMessageListViewController - (void)tableView:willDisplayCell:forRowAtIndexPath:
//   AWEIMMessageListViewController - (void)viewWillDisappear:(BOOL)
//   AWEIMMessageListViewController - (void)dealloc
// 原理（可还原部分）：cell 展示后延迟触发检查，递归在可见 cell 里找未播放的语音视图，
// 触发其自带的转文字入口；viewWillDisappear/dealloc 时取消 timer。
// v1 说明：Yuki 触发转文字的具体调用点未能从逆向产物完整还原，v1 用尽力而为策略：
//   在语音视图内找标题含"转文字"的按钮并点击，或调 translate/transcribe 类 selector；
//   找不到时跳过并打日志。真机验证后按需继续深挖。
// 注意：本文件也 hook willDisplayCell，与 DYLikeIMTimeLabel.m 的同名 hook 形成调用链，
//      method_setImplementation 天然支持链式，无冲突。
// 开关：DYLikeVoiceTranslateEnabledKey，默认关闭。

#import "DYLikeCore.h"
#import <objc/runtime.h>

static const void *kAMZZVTHandledKey = &kAMZZVTHandledKey; // cell -> @YES（已处理过）
static const void *kAMZZVTTimerKey = &kAMZZVTTimerKey;     // vc -> NSTimer

// ---------- 递归找语音视图 ----------
static void AMZZFindAudioViews(UIView *view, NSMutableArray *out) {
    if (!view) return;
    NSString *clsName = NSStringFromClass([view class]);
    if ([clsName rangeOfString:@"Audio" options:NSCaseInsensitiveSearch].location != NSNotFound &&
        [clsName rangeOfString:@"Message" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        [out addObject:view];
    }
    for (UIView *sub in view.subviews) AMZZFindAudioViews(sub, out);
}

// ---------- 尝试触发单个语音视图的转文字 ----------
static BOOL AMZZTriggerTranslate(UIView *audioView) {
    // 策略1：找标题含"转文字"的按钮并点击
    __block UIButton *btn = nil;
    NSMutableArray *stack = [NSMutableArray arrayWithObject:audioView];
    while (stack.count && !btn) {
        UIView *v = [stack lastObject]; [stack removeLastObject];
        if ([v isKindOfClass:[UIButton class]]) {
            NSString *t = [(UIButton *)v titleForState:UIControlStateNormal] ?: @"";
            if ([t containsString:@"转文字"] || [t containsString:@"翻译"]) { btn = (UIButton *)v; break; }
        }
        [stack addObjectsFromArray:v.subviews];
    }
    if (btn && btn.enabled && !btn.hidden) {
        [btn sendActionsForControlEvents:UIControlEventTouchUpInside];
        return YES;
    }
    // 策略2：直接调 translate 类方法
    for (NSString *s in @[@"startTranslate", @"translate", @"transcribe", @"startTranscribe",
                          @"p_startTranslate", @"translateAudioToText"]) {
        SEL sel = NSSelectorFromString(s);
        if ([audioView respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [audioView performSelector:sel];
#pragma clang diagnostic pop
            return YES;
        }
    }
    return NO;
}

// ---------- 扫描可见 cell ----------
static void AMZZScanAndTranslate(id vc) {
    if (!DYLikeIMFeatureEnabled(DYLikeVoiceTranslateEnabledKey)) return;
    UITableView *tv = nil;
    @try {
        if ([vc isKindOfClass:[UIViewController class]]) {
            for (UIView *v in [(UIViewController *)vc view].subviews) {
                if ([v isKindOfClass:[UITableView class]]) { tv = (UITableView *)v; break; }
            }
        }
        if (!tv) return;
        for (UITableViewCell *cell in tv.visibleCells) {
            if ([objc_getAssociatedObject(cell, kAMZZVTHandledKey) boolValue]) continue;
            NSMutableArray *audios = [NSMutableArray array];
            AMZZFindAudioViews(cell.contentView, audios);
            BOOL did = NO;
            for (UIView *av in audios) {
                if (AMZZTriggerTranslate(av)) { did = YES; break; }
            }
            if (did) objc_setAssociatedObject(cell, kAMZZVTHandledKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    } @catch (NSException *e) {
        NSLog(@"[DYSecondaryConfirmation] voice-translate scan error: %@", e);
    }
}

static void AMZZCancelTimer(id vc) {
    NSTimer *t = objc_getAssociatedObject(vc, kAMZZVTTimerKey);
    [t invalidate];
    objc_setAssociatedObject(vc, kAMZZVTTimerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void AMZZScheduleCheck(id vc) {
    if (!DYLikeIMFeatureEnabled(DYLikeVoiceTranslateEnabledKey)) return;
    AMZZCancelTimer(vc);
    __weak id weakVC = vc;
    NSTimer *t = [NSTimer scheduledTimerWithTimeInterval:1.5 repeats:NO block:^(NSTimer * _Nonnull timer) {
        AMZZScanAndTranslate(weakVC);
    }];
    objc_setAssociatedObject(vc, kAMZZVTTimerKey, t, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// ---------- hooks ----------
static void (*orig_vt_willDisplayCell)(id, SEL, id, id, id) = NULL;
static void amzz_vt_willDisplayCell(id self, SEL _cmd, id tv, id cell, id ip) {
    orig_vt_willDisplayCell(self, _cmd, tv, cell, ip);
    AMZZScheduleCheck(self);
}

static void (*orig_vt_viewWillDisappear_)(id, SEL, BOOL) = NULL;
static void amzz_vt_viewWillDisappear_(id self, SEL _cmd, BOOL a) {
    AMZZCancelTimer(self);
    orig_vt_viewWillDisappear_(self, _cmd, a);
}

static void (*orig_vt_dealloc)(id, SEL) = NULL;
static void amzz_vt_dealloc(id self, SEL _cmd) {
    AMZZCancelTimer(self);
    orig_vt_dealloc(self, _cmd);
}

void DYLikeIMInstallVoiceTranslate(void) {
    Class cls = objc_getClass("AWEIMMessageListViewController");
    if (!cls) return;
    Method m1 = class_getInstanceMethod(cls, @selector(tableView:willDisplayCell:forRowAtIndexPath:));
    if (m1) orig_vt_willDisplayCell = (void (*)(id, SEL, id, id, id))method_setImplementation(m1, (IMP)amzz_vt_willDisplayCell);
    Method m2 = class_getInstanceMethod(cls, @selector(viewWillDisappear:));
    if (m2) orig_vt_viewWillDisappear_ = (void (*)(id, SEL, BOOL))method_setImplementation(m2, (IMP)amzz_vt_viewWillDisappear_);
    Method m3 = class_getInstanceMethod(cls, @selector(dealloc));
    if (m3) orig_vt_dealloc = (void (*)(id, SEL))method_setImplementation(m3, (IMP)amzz_vt_dealloc);
    NSLog(@"[DYSecondaryConfirmation] Installed voice-translate hooks");
}
