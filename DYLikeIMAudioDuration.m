// DYLikeIMAudioDuration.m — 自定义语音时长
// 移植自 Yuki (YukiEnableCustomAudioDuration / YukiCustomAudioMsgSec)。
// 签名：AWEIMAudioMessageRecorder
//   - (void)audioRecorderDidFinishRecording:(id)successfully:(BOOL)action:(unsigned long long)
//   （39.8.0 头文件确认）
// 原理：录音结束时读配置字符串（"10" 或 "5~15" 形式），解析出秒数后调
// setCurrentTime: 改写录音时长；范围形式用 rand 取随机值。
// 开关：DYLikeAudioDurationEnabledKey；时长：DYLikeAudioDurationSecKey，默认关闭。

#import "DYLikeCore.h"
#import <objc/runtime.h>
#import <stdlib.h>

static long AMZZParseDurationSec(NSString *cfg) {
    if (![cfg isKindOfClass:[NSString class]] || cfg.length == 0) return 0;
    NSCharacterSet *sep = [NSCharacterSet characterSetWithCharactersInString:@"～~"];
    if ([cfg rangeOfCharacterFromSet:sep].location != NSNotFound) {
        NSArray<NSString *> *parts = [cfg componentsSeparatedByCharactersInSet:sep];
        long lo = [[parts firstObject] integerValue];
        long hi = parts.count > 1 ? [[parts objectAtIndex:1] integerValue] : lo;
        if (lo <= 0 || hi < lo) return 0;
        if (hi == lo) return lo;
        return lo + (rand() % (hi - lo + 1));
    }
    long v = [cfg integerValue];
    return v > 0 ? v : 0;
}

static void (*orig_audioRecorderDidFinish)(id, SEL, id, BOOL, unsigned long long) = NULL;
static void amzz_audioRecorderDidFinish(id self, SEL _cmd, id r, BOOL ok, unsigned long long action) {
    orig_audioRecorderDidFinish(self, _cmd, r, ok, action);
    if (!ok || !DYLikeIMFeatureEnabled(DYLikeAudioDurationEnabledKey)) return;
    NSString *cfg = [[NSUserDefaults standardUserDefaults] stringForKey:DYLikeAudioDurationSecKey];
    long sec = AMZZParseDurationSec(cfg);
    if (sec <= 0) return;
    @try {
        // 在 self 或参数 r 上找 setCurrentTime:
        id target = nil;
        if ([self respondsToSelector:@selector(setCurrentTime:)]) target = self;
        else if ([r respondsToSelector:@selector(setCurrentTime:)]) target = r;
        if (target) {
            // setCurrentTime: 可能是 NSTimeInterval(double) 或 long，按 double 调
            ((void (*)(id, SEL, double))objc_msgSend)(target, @selector(setCurrentTime:), (double)sec);
            NSLog(@"[DYSecondaryConfirmation] audio duration set to %ld s", sec);
        }
    } @catch (NSException *e) {
        NSLog(@"[DYSecondaryConfirmation] audio duration error: %@", e);
    }
}

void DYLikeIMInstallAudioDuration(void) {
    Class cls = objc_getClass("AWEIMAudioMessageRecorder");
    if (!cls) return;
    Method m = class_getInstanceMethod(cls, @selector(audioRecorderDidFinishRecording:successfully:action:));
    if (m) orig_audioRecorderDidFinish = (void (*)(id, SEL, id, BOOL, unsigned long long))method_setImplementation(m, (IMP)amzz_audioRecorderDidFinish);
    NSLog(@"[DYSecondaryConfirmation] Installed audio-duration hook");
}
