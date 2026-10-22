// DYGlassTabBar.m — 液态玻璃底栏（路线 C），已接入 AMZZ，未真机验证
//
// 来源：Una159/DYYY 的 DYYYLiquidGlass.xm（玻璃底栏半截），按 AMZZ 惯例改写：
//   - Logos %hook → 运行时 class_replaceMethod（同 DYProfileTabsInstall 的写法）
//   - DYYYGetBool(@"DYYYEnableLiquidGlass") → NSUserDefaults boolForKey:DYGlassTabBarEnabledKey
//   - 进度条流光半截没搬（跟玻璃需求无关，要的话原文件另有一半可加）
//
// 关键特性（和 DYKiller 路线的本质区别）：
//   胶囊宽度 = 底栏自身 bounds 左右各缩 12pt，是固定值，不随按钮数量变化。
//   所以“移除按钮后玻璃变短”在这个做法里天然不存在——不需要量按钮、不需要算宽。

#import "DYGlassTabBar.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

NSString *const DYGlassTabBarEnabledKey = @"DYGlassTabBarEnabled";

static const NSInteger kDYGlassTag = 0xD1A55;

typedef void (*DYLayoutSubviewsIMP)(id, SEL);
static DYLayoutSubviewsIMP DYOrigTabBarLayoutSubviews = NULL;

static UIVisualEffectView *DYGlassMakeView(void) {
    UIVisualEffect *fx = nil;
    // iOS 26+ 才有 UIGlassEffect，运行时取类，旧 SDK 也能编译
    Class glassCls = NSClassFromString(@"UIGlassEffect");
    if (glassCls) {
        id obj = [[glassCls alloc] init];
        if ([obj isKindOfClass:[UIVisualEffect class]]) {
            fx = obj;
            if ([obj respondsToSelector:NSSelectorFromString(@"setInteractive:")]) {
                [obj setValue:@YES forKey:@"interactive"];
            }
        }
    }
    if (!fx) {
        // iOS 26 以下退回毛玻璃
        fx = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
    }
    UIVisualEffectView *v = [[UIVisualEffectView alloc] initWithEffect:fx];
    v.userInteractionEnabled = NO;
    v.clipsToBounds = YES;
    v.tag = kDYGlassTag;
    return v;
}

static void DYGlassTabBarLayoutSubviews(id self, SEL _cmd) {
    if (DYOrigTabBarLayoutSubviews) DYOrigTabBarLayoutSubviews(self, _cmd);

    UIView *bar = (UIView *)self;
    UIView *old = [bar viewWithTag:kDYGlassTag];

    if (![NSUserDefaults.standardUserDefaults boolForKey:DYGlassTabBarEnabledKey]) {
        [old removeFromSuperview];
        return;
    }

    UIVisualEffectView *glass = (UIVisualEffectView *)old;
    if (!glass) {
        glass = DYGlassMakeView();
        [bar insertSubview:glass atIndex:0];
    }

    // 悬浮胶囊：左右各留 12，上下各留 6；底部安全区由原底栏高度承担
    CGRect frame = CGRectInset(bar.bounds, 12, 6);
    CGFloat safeBottom = bar.safeAreaInsets.bottom;
    frame.size.height = MAX(44, frame.size.height - safeBottom);
    glass.frame = frame;
    glass.layer.cornerRadius = frame.size.height / 2.0;
    if (@available(iOS 13.0, *)) {
        glass.layer.cornerCurve = kCACornerCurveContinuous;
    }
    [bar sendSubviewToBack:glass];

    // 隐藏原底栏背景，避免和玻璃叠在一起
    Class barBg = NSClassFromString(@"_UIBarBackground");
    for (UIView *sub in bar.subviews) {
        if (sub == glass) continue;
        if (barBg && [sub isKindOfClass:barBg]) {
            sub.hidden = YES;
        }
    }
}

void DYGlassTabBarInstall(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class barClass = NSClassFromString(@"AWENormalModeTabBar");
        if (!barClass) return;
        Method m = class_getInstanceMethod(barClass, @selector(layoutSubviews));
        if (!m) return;
        DYOrigTabBarLayoutSubviews = (DYLayoutSubviewsIMP)method_getImplementation(m);
        class_replaceMethod(barClass, @selector(layoutSubviews),
                            (IMP)DYGlassTabBarLayoutSubviews,
                            method_getTypeEncoding(m));
    });
}

// 注：本文件只负责玻璃本身（长度固定）。“剩余按钮自动摊开”不在此文件内，AMZZ 目前也没有移除底栏按钮的功能。
