// DYLikeIMAudioShare.m — 语音消息转发
// 移植自 Yuki (YukiEnableAudioShare)，签名：
//   AWEIMAudioMessage - (BOOL)isSupportForward            （头文件未收录，按命名推断）
//   AWEIMAudioMessage - (id)supportMessageMenuTypeList    （39.8.0 头文件确认）
// 原理：Yuki 让 isSupportForward 始终返回 YES，并在菜单类型列表里追加转发项。
// v1 说明：追加到菜单列表的具体对象值未能从逆向产物还原，v1 只做 isSupportForward→YES；
//       若真机验证转发入口未出现，再继续深挖菜单项标识。
// 开关：DYLikeAudioShareEnabledKey，默认关闭。

#import "DYLikeCore.h"
#import <objc/runtime.h>

static BOOL (*orig_isSupportForward)(id, SEL) = NULL;
static BOOL amzz_isSupportForward(id self, SEL _cmd) {
    if (DYLikeIMFeatureEnabled(DYLikeAudioShareEnabledKey)) return YES;
    return orig_isSupportForward(self, _cmd);
}

static id (*orig_supportMessageMenuTypeList)(id, SEL) = NULL;
static id amzz_supportMessageMenuTypeList(id self, SEL _cmd) {
    // v1：透传原实现（见文件头注释）
    return orig_supportMessageMenuTypeList(self, _cmd);
}

void DYLikeIMInstallAudioShare(void) {
    Class cls = objc_getClass("AWEIMAudioMessage");
    if (!cls) return;
    Method m1 = class_getInstanceMethod(cls, @selector(isSupportForward));
    if (m1) orig_isSupportForward = (BOOL (*)(id, SEL))method_setImplementation(m1, (IMP)amzz_isSupportForward);
    Method m2 = class_getInstanceMethod(cls, @selector(supportMessageMenuTypeList));
    if (m2) orig_supportMessageMenuTypeList = (id (*)(id, SEL))method_setImplementation(m2, (IMP)amzz_supportMessageMenuTypeList);
    NSLog(@"[DYSecondaryConfirmation] Installed audio-share hooks");
}
