// DYLikeIMWatchOnce.m — 阅后即焚防销毁
// 移植自 Yuki (YukiPreventWatchOnceDestroy)，签名经抖音 39.8.0 头文件确认。
// 原理：Yuki 对这些方法"从不调用原实现"——
//   * isReadingWatchOnceMessage: → 始终返回 YES（假装正在看，不触发销毁）
//   * watchOnceMediaLoopTimes → 返回大次数（媒体循环播放）
//   * markMessageWatchOnceAlreadyConsume:... → 直接返回（不标记为已消费）
//   * watchEnd → 返回 NO（假装没看完）
// 开关：DYLikeWatchOnceEnabledKey，默认关闭。

#import "DYLikeCore.h"
#import <objc/runtime.h>

static BOOL (*orig_isReadingWatchOnceMessage_)(id, SEL, id) = NULL;
static BOOL amzz_isReadingWatchOnceMessage_(id self, SEL _cmd, id a1) {
    if (DYLikeIMFeatureEnabled(DYLikeWatchOnceEnabledKey)) return YES;
    return orig_isReadingWatchOnceMessage_(self, _cmd, a1);
}

static int (*orig_watchOnceMediaLoopTimes)(id, SEL) = NULL;
static int amzz_watchOnceMediaLoopTimes(id self, SEL _cmd) {
    if (DYLikeIMFeatureEnabled(DYLikeWatchOnceEnabledKey)) return 9999;
    return orig_watchOnceMediaLoopTimes(self, _cmd);
}

static void (*orig_markMessageWatchOnceAlreadyConsume)(id, SEL, id, id, id) = NULL;
static void amzz_markMessageWatchOnceAlreadyConsume(id self, SEL _cmd, id a1, id a2, id a3) {
    if (DYLikeIMFeatureEnabled(DYLikeWatchOnceEnabledKey)) return;
    orig_markMessageWatchOnceAlreadyConsume(self, _cmd, a1, a2, a3);
}

static BOOL (*orig_watchEnd)(id, SEL) = NULL;
static BOOL amzz_watchEnd(id self, SEL _cmd) {
    if (DYLikeIMFeatureEnabled(DYLikeWatchOnceEnabledKey)) return NO;
    return orig_watchEnd(self, _cmd);
}

static void WOSwizzle(const char *clsName, SEL sel, IMP rep, void **origSlot) {
    Class cls = objc_getClass(clsName);
    if (!cls) return;
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) return;
    *origSlot = (void *)method_setImplementation(m, rep);
}

void DYLikeIMInstallWatchOnce(void) {
    WOSwizzle("AWEIMWatchOnceMessageManager", @selector(isReadingWatchOnceMessage:),
        (IMP)amzz_isReadingWatchOnceMessage_, (void **)&orig_isReadingWatchOnceMessage_);
    WOSwizzle("AWEIMWatchOnceMessageManager", @selector(watchOnceMediaLoopTimes),
        (IMP)amzz_watchOnceMediaLoopTimes, (void **)&orig_watchOnceMediaLoopTimes);
    WOSwizzle("AWEIMWatchOnceDataManager",
        @selector(markMessageWatchOnceAlreadyConsume:messageArray:complete:),
        (IMP)amzz_markMessageWatchOnceAlreadyConsume, (void **)&orig_markMessageWatchOnceAlreadyConsume);
    // image / video 共用同一个 replacement（签名都是 - (BOOL)watchEnd）
    Method mi = class_getInstanceMethod(objc_getClass("AWEIMWatchOnceImageMessage"), @selector(watchEnd));
    if (mi) orig_watchEnd = (BOOL (*)(id, SEL))method_setImplementation(mi, (IMP)amzz_watchEnd);
    Method mv = class_getInstanceMethod(objc_getClass("AWEIMWatchOnceVideoMessage"), @selector(watchEnd));
    if (mv) method_setImplementation(mv, (IMP)amzz_watchEnd);
    NSLog(@"[DYSecondaryConfirmation] Installed watch-once hooks");
}
