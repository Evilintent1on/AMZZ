// DYLikeIMDice.m — 摇骰子/猜拳
// 移植自 Yuki（骰子猜拳作弊）。签名：
//   TIMXOSendMessage - (void)setContent:(id)            （39.8.0 头文件确认）
//   AWEIMEmoticonInteractivePage - (void)collectionView:didSelectItemAtIndexPath:
//                                                     （标准 UIKit delegate 签名）
// 原理（可还原部分）：拦截 setContent:，若内容字典是摇骰子/猜拳表情（按
// display_name 含"摇骰子"/"猜拳"判断），用 arc4random_uniform 从 url_list
// 里重随机选一个 url，改写后调原实现。Yuki 的反汇编里明确出现了
// arc4random_uniform / url_list / objectAtIndexedSubscript: 的调用链。
// v1 说明：url 与点数的对应关系未知，v1 做"重随机"（避免固定值被识别）。
// 开关：DYLikeDiceEnabledKey，默认关闭。

#import "DYLikeCore.h"
#import <objc/runtime.h>
#import <stdlib.h>

static void (*orig_setContent_)(id, SEL, id) = NULL;
static void amzz_setContent_(id self, SEL _cmd, id content) {
    if (DYLikeIMFeatureEnabled(DYLikeDiceEnabledKey) && [content isKindOfClass:[NSDictionary class]]) {
        @try {
            NSDictionary *d = (NSDictionary *)content;
            NSString *name = d[@"display_name"];
            if (![name isKindOfClass:[NSString class]]) {
                // 再试 resource_type / sticker_type
                id rt = d[@"resource_type"], st = d[@"sticker_type"];
                name = [NSString stringWithFormat:@"%@%@", rt ?: @"", st ?: @""];
            }
            BOOL isDice = [name containsString:@"摇骰子"] || [name containsString:@"骰子"];
            BOOL isGuess = [name containsString:@"猜拳"];
            if (isDice || isGuess) {
                NSArray *urls = d[@"url_list"];
                if ([urls isKindOfClass:[NSArray class]] && urls.count > 1) {
                    uint32_t pick = arc4random_uniform((uint32_t)urls.count);
                    NSMutableDictionary *m = [d mutableCopy];
                    m[@"url"] = urls[pick];
                    NSLog(@"[DYSecondaryConfirmation] dice/guess re-randomized -> index %u/%lu",
                          pick, (unsigned long)urls.count);
                    orig_setContent_(self, _cmd, m);
                    return;
                }
            }
        } @catch (NSException *e) {
            NSLog(@"[DYSecondaryConfirmation] dice error: %@", e);
        }
    }
    orig_setContent_(self, _cmd, content);
}

static void (*orig_didSelectItem_)(id, SEL, id, id) = NULL;
static void amzz_didSelectItem_(id self, SEL _cmd, id cv, id ip) {
    // 透传：选择行为不变，作弊点在 setContent: 拦截
    orig_didSelectItem_(self, _cmd, cv, ip);
}

void DYLikeIMInstallDice(void) {
    Class c1 = objc_getClass("TIMXOSendMessage");
    if (c1) {
        Method m = class_getInstanceMethod(c1, @selector(setContent:));
        if (m) orig_setContent_ = (void (*)(id, SEL, id))method_setImplementation(m, (IMP)amzz_setContent_);
    }
    Class c2 = objc_getClass("AWEIMEmoticonInteractivePage");
    if (c2) {
        Method m = class_getInstanceMethod(c2, @selector(collectionView:didSelectItemAtIndexPath:));
        if (m) orig_didSelectItem_ = (void (*)(id, SEL, id, id))method_setImplementation(m, (IMP)amzz_didSelectItem_);
    }
    NSLog(@"[DYSecondaryConfirmation] Installed dice hooks");
}
