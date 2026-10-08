// DYLikeIMStealth.m — 隐身：隐藏在线状态 + 不上报"正在输入"
// 移植自 Yuki (YukiHideDYMsgTimeLabel 体系外)，签名经抖音 39.8.0 头文件确认。
// 原理：Yuki 对这些方法"从不调用原实现"——直接拦截在线状态的上报/拉取。
// 开关：DYLikeStealthEnabledKey，默认关闭。

#import "DYLikeCore.h"
#import <objc/runtime.h>

// ---- AWEIMActiveUserInfo - (BOOL)canShowActiveStatus → NO ----
static BOOL (*orig_canShowActiveStatus)(id, SEL) = NULL;
static BOOL amzz_canShowActiveStatus(id self, SEL _cmd) {
    if (DYLikeIMFeatureEnabled(DYLikeStealthEnabledKey)) return NO;
    return orig_canShowActiveStatus(self, _cmd);
}

// ---- AWEIMActiveUserUploader - (BOOL)checkEnableServerUploadActiveStatus → NO ----
static BOOL (*orig_checkEnableServerUploadActiveStatus)(id, SEL) = NULL;
static BOOL amzz_checkEnableServerUploadActiveStatus(id self, SEL _cmd) {
    if (DYLikeIMFeatureEnabled(DYLikeStealthEnabledKey)) return NO;
    return orig_checkEnableServerUploadActiveStatus(self, _cmd);
}

// ---- AWEIMActiveUserUploader - (void)updateUserActiveStatusWithEntrance:context: → 拦截 ----
static void (*orig_updateUserActiveStatusWithEntrance_context_)(id, SEL, id, id) = NULL;
static void amzz_updateUserActiveStatusWithEntrance_context_(id self, SEL _cmd, id a1, id a2) {
    if (DYLikeIMFeatureEnabled(DYLikeStealthEnabledKey)) return;
    orig_updateUserActiveStatusWithEntrance_context_(self, _cmd, a1, a2);
}

// ---- AWEIMActiveUserUploader - (void)p_updateUserActiveWithContext: → 拦截 ----
static void (*orig_p_updateUserActiveWithContext_)(id, SEL, id) = NULL;
static void amzz_p_updateUserActiveWithContext_(id self, SEL _cmd, id a1) {
    if (DYLikeIMFeatureEnabled(DYLikeStealthEnabledKey)) return;
    orig_p_updateUserActiveWithContext_(self, _cmd, a1);
}

// ---- AWEIMActiveUserUploader - (void)setUpTimerWithContext: → 拦截 ----
static void (*orig_setUpTimerWithContext_)(id, SEL, id) = NULL;
static void amzz_setUpTimerWithContext_(id self, SEL _cmd, id a1) {
    if (DYLikeIMFeatureEnabled(DYLikeStealthEnabledKey)) return;
    orig_setUpTimerWithContext_(self, _cmd, a1);
}

// ---- AWEIMActiveUserNetwork + (id)updateUserActiveStatusWithEntrance:extraParams:context:completion: → nil ----
static id (*orig_network_updateUserActiveStatus)(id, SEL, id, id, id, id) = NULL;
static id amzz_network_updateUserActiveStatus(id self, SEL _cmd, id a1, id a2, id a3, id a4) {
    if (DYLikeIMFeatureEnabled(DYLikeStealthEnabledKey)) return nil;
    return orig_network_updateUserActiveStatus(self, _cmd, a1, a2, a3, a4);
}

// ---- AWEIMActiveUserManager + (BOOL)canPullFriendActiveStatus → NO ----
static BOOL (*orig_canPullFriendActiveStatus)(id, SEL) = NULL;
static BOOL amzz_canPullFriendActiveStatus(id self, SEL _cmd) {
    if (DYLikeIMFeatureEnabled(DYLikeStealthEnabledKey)) return NO;
    return orig_canPullFriendActiveStatus(self, _cmd);
}

// ---- AWEIMActiveUserManager + (void)setWillEnterForegroundBlock:withType:pageIdentifier: → 拦截 ----
static void (*orig_setWillEnterForegroundBlock)(id, SEL, id, unsigned long long, id) = NULL;
static void amzz_setWillEnterForegroundBlock(id self, SEL _cmd, id a1, unsigned long long a2, id a3) {
    if (DYLikeIMFeatureEnabled(DYLikeStealthEnabledKey)) return;
    orig_setWillEnterForegroundBlock(self, _cmd, a1, a2, a3);
}

// ---- AWEIMActiveUserManager + (BOOL)canFetchActiveWithGroupSessionID: → NO ----
static BOOL (*orig_canFetchActiveWithGroupSessionID_)(id, SEL, id) = NULL;
static BOOL amzz_canFetchActiveWithGroupSessionID_(id self, SEL _cmd, id a1) {
    if (DYLikeIMFeatureEnabled(DYLikeStealthEnabledKey)) return NO;
    return orig_canFetchActiveWithGroupSessionID_(self, _cmd, a1);
}

// ---- AWEIMActiveUserManager + (BOOL)canFetchActiveWithGroupCon: → NO ----
static BOOL (*orig_canFetchActiveWithGroupCon_)(id, SEL, id) = NULL;
static BOOL amzz_canFetchActiveWithGroupCon_(id self, SEL _cmd, id a1) {
    if (DYLikeIMFeatureEnabled(DYLikeStealthEnabledKey)) return NO;
    return orig_canFetchActiveWithGroupCon_(self, _cmd, a1);
}

// ---- AWEIMInputStateManager - (void)reportInputStateWithText: → 拦截（不报"正在输入"） ----
static void (*orig_reportInputStateWithText_)(id, SEL, id) = NULL;
static void amzz_reportInputStateWithText_(id self, SEL _cmd, id a1) {
    if (DYLikeIMFeatureEnabled(DYLikeStealthEnabledKey)) return;
    orig_reportInputStateWithText_(self, _cmd, a1);
}

static void StealthSwizzleInstance(const char *clsName, SEL sel, IMP rep, void **origSlot) {
    Class cls = objc_getClass(clsName);
    if (!cls) return;
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) return;
    *origSlot = (void *)method_setImplementation(m, rep);
}

static void StealthSwizzleClass(const char *clsName, SEL sel, IMP rep, void **origSlot) {
    Class cls = objc_getClass(clsName);
    if (!cls) return;
    Class meta = object_getClass(cls);
    Method m = class_getInstanceMethod(meta, sel);
    if (!m) return;
    *origSlot = (void *)method_setImplementation(m, rep);
}

void DYLikeIMInstallStealth(void) {
    StealthSwizzleInstance("AWEIMActiveUserInfo", @selector(canShowActiveStatus),
        (IMP)amzz_canShowActiveStatus, (void **)&orig_canShowActiveStatus);
    StealthSwizzleInstance("AWEIMActiveUserUploader", @selector(checkEnableServerUploadActiveStatus),
        (IMP)amzz_checkEnableServerUploadActiveStatus, (void **)&orig_checkEnableServerUploadActiveStatus);
    StealthSwizzleInstance("AWEIMActiveUserUploader", @selector(updateUserActiveStatusWithEntrance:context:),
        (IMP)amzz_updateUserActiveStatusWithEntrance_context_, (void **)&orig_updateUserActiveStatusWithEntrance_context_);
    StealthSwizzleInstance("AWEIMActiveUserUploader", @selector(p_updateUserActiveWithContext:),
        (IMP)amzz_p_updateUserActiveWithContext_, (void **)&orig_p_updateUserActiveWithContext_);
    StealthSwizzleInstance("AWEIMActiveUserUploader", @selector(setUpTimerWithContext:),
        (IMP)amzz_setUpTimerWithContext_, (void **)&orig_setUpTimerWithContext_);
    StealthSwizzleClass("AWEIMActiveUserNetwork",
        @selector(updateUserActiveStatusWithEntrance:extraParams:context:completion:),
        (IMP)amzz_network_updateUserActiveStatus, (void **)&orig_network_updateUserActiveStatus);
    StealthSwizzleClass("AWEIMActiveUserManager", @selector(canPullFriendActiveStatus),
        (IMP)amzz_canPullFriendActiveStatus, (void **)&orig_canPullFriendActiveStatus);
    StealthSwizzleClass("AWEIMActiveUserManager",
        @selector(setWillEnterForegroundBlock:withType:pageIdentifier:),
        (IMP)amzz_setWillEnterForegroundBlock, (void **)&orig_setWillEnterForegroundBlock);
    StealthSwizzleClass("AWEIMActiveUserManager", @selector(canFetchActiveWithGroupSessionID:),
        (IMP)amzz_canFetchActiveWithGroupSessionID_, (void **)&orig_canFetchActiveWithGroupSessionID_);
    StealthSwizzleClass("AWEIMActiveUserManager", @selector(canFetchActiveWithGroupCon:),
        (IMP)amzz_canFetchActiveWithGroupCon_, (void **)&orig_canFetchActiveWithGroupCon_);
    StealthSwizzleInstance("AWEIMInputStateManager", @selector(reportInputStateWithText:),
        (IMP)amzz_reportInputStateWithText_, (void **)&orig_reportInputStateWithText_);
    NSLog(@"[DYSecondaryConfirmation] Installed stealth hooks");
}
