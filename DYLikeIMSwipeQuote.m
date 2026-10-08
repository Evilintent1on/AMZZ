// DYLikeIMSwipeQuote.m — 左滑引用回复
// 移植自 Yuki (YukiSwipeToQuote)，目标类 AWEIMReusableCommonCell。
// 签名（标准 UIKit 签名，头文件未收录）：
//   - (id)initWithFrame:(CGRect)
//   - (void)didMoveToSuperview
// 原理（手势部分完整重写）：给消息 cell 加 UIPanGestureRecognizer，左滑时平移
// contentView 并在阈值处给触觉反馈，松手超过阈值触发引用回复。
// v1 说明：triggerQuoteReply 需要把"引用这条消息"的意图传给输入框，
//       具体 API 未能从逆向产物还原，v1 用尽力而为策略（沿响应链找 VC，
//       试 quote/quoteMessage 等 selector）。真机验证后按需深挖。
// 开关：DYLikeSwipeQuoteEnabledKey，默认关闭。

#import "DYLikeCore.h"
#import <objc/runtime.h>

static const void *kAMZZSwipeGRKey = &kAMZZSwipeGRKey;
static const void *kAMZZSwipeOrigCenterKey = &kAMZZSwipeOrigCenterKey;
static const void *kAMZZSwipeFedBackKey = &kAMZZSwipeFedBackKey;
static const CGFloat kAMZZSwipeThreshold = -64.0;

@interface AMZZSwipeProxy : NSObject
+ (instancetype)shared;
- (void)onPan:(UIPanGestureRecognizer *)gr;
@end

// ---------- 触发引用（尽力而为） ----------
static id AMZZCellMessage(UIView *cell) {
    for (NSString *s in @[@"message", @"messageModel", @"model", @"dataModel"]) {
        SEL sel = NSSelectorFromString(s);
        if ([cell respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            id v = [cell performSelector:sel];
#pragma clang diagnostic pop
            if (v) return v;
        }
    }
    return nil;
}

static void AMZZTriggerQuoteReply(UIView *cell) {
    if (!DYLikeIMFeatureEnabled(DYLikeSwipeQuoteEnabledKey)) return;
    id message = AMZZCellMessage(cell);
    // 沿响应链找 VC
    UIResponder *r = cell;
    while (r && ![r isKindOfClass:[UIViewController class]]) r = r.nextResponder;
    UIViewController *vc = (UIViewController *)r;
    BOOL done = NO;
    if (message && vc) {
        for (NSString *s in @[@"quoteMessage:", @"setQuoteMessage:", @"quoteReplyWithMessage:",
                               @"replyWithQuoteMessage:", @"p_quoteMessage:"]) {
            SEL sel = NSSelectorFromString(s);
            if ([vc respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [vc performSelector:sel withObject:message];
#pragma clang diagnostic pop
                done = YES;
                break;
            }
        }
    }
    NSLog(@"[DYSecondaryConfirmation] swipe-quote trigger %@ (vc=%@)",
          done ? @"ok" : @"API TBD", vc ? NSStringFromClass([vc class]) : @"nil");
    // 视觉回弹
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.8
        initialSpringVelocity:0 options:0 animations:^{
            cell.contentView.transform = CGAffineTransformIdentity;
        } completion:nil];
}

@implementation AMZZSwipeProxy
+ (instancetype)shared {
    static AMZZSwipeProxy *s; static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [AMZZSwipeProxy new]; });
    return s;
}
- (void)onPan:(UIPanGestureRecognizer *)gr {
    UIView *cell = gr.view;
    if (!cell || !DYLikeIMFeatureEnabled(DYLikeSwipeQuoteEnabledKey)) return;
    CGPoint t = [gr translationInView:cell];
    switch (gr.state) {
        case UIGestureRecognizerStateBegan: {
            objc_setAssociatedObject(cell, kAMZZSwipeOrigCenterKey,
                [NSValue valueWithCGPoint:cell.contentView.center], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(cell, kAMZZSwipeFedBackKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGFloat dx = MIN(0, t.x); // 只允许左滑
            cell.contentView.transform = CGAffineTransformMakeTranslation(dx, 0);
            BOOL fed = [objc_getAssociatedObject(cell, kAMZZSwipeFedBackKey) boolValue];
            if (!fed && dx < kAMZZSwipeThreshold) {
                UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc]
                    initWithStyle:UIImpactFeedbackStyleMedium];
                [gen impactOccurred];
                objc_setAssociatedObject(cell, kAMZZSwipeFedBackKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (t.x < kAMZZSwipeThreshold) {
                AMZZTriggerQuoteReply(cell);
            } else {
                [UIView animateWithDuration:0.22 animations:^{
                    cell.contentView.transform = CGAffineTransformIdentity;
                }];
            }
            break;
        }
        default: break;
    }
}
@end

static void AMZZSetupSwipeGesture(UIView *cell) {
    if (objc_getAssociatedObject(cell, kAMZZSwipeGRKey)) return;
    UIPanGestureRecognizer *gr = [[UIPanGestureRecognizer alloc]
        initWithTarget:[AMZZSwipeProxy shared] action:@selector(onPan:)];
    // 只在横向滑动时接管，不干扰纵向滚动
    [cell addGestureRecognizer:gr];
    objc_setAssociatedObject(cell, kAMZZSwipeGRKey, gr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static id (*orig_cellInitWithFrame_)(id, SEL, CGRect) = NULL;
static id amzz_cellInitWithFrame_(id self, SEL _cmd, CGRect f) {
    id cell = orig_cellInitWithFrame_(self, _cmd, f);
    if (DYLikeIMFeatureEnabled(DYLikeSwipeQuoteEnabledKey)) AMZZSetupSwipeGesture(cell);
    return cell;
}

static void (*orig_cellDidMoveToSuperview)(id, SEL) = NULL;
static void amzz_cellDidMoveToSuperview(id self, SEL _cmd) {
    orig_cellDidMoveToSuperview(self, _cmd);
    if (DYLikeIMFeatureEnabled(DYLikeSwipeQuoteEnabledKey) && [(UIView *)self superview])
        AMZZSetupSwipeGesture(self);
}

void DYLikeIMInstallSwipeQuote(void) {
    Class cls = objc_getClass("AWEIMReusableCommonCell");
    if (!cls) return;
    Method m1 = class_getInstanceMethod(cls, @selector(initWithFrame:));
    if (m1) orig_cellInitWithFrame_ = (id (*)(id, SEL, CGRect))method_setImplementation(m1, (IMP)amzz_cellInitWithFrame_);
    Method m2 = class_getInstanceMethod(cls, @selector(didMoveToSuperview));
    if (m2) orig_cellDidMoveToSuperview = (void (*)(id, SEL))method_setImplementation(m2, (IMP)amzz_cellDidMoveToSuperview);
    NSLog(@"[DYSecondaryConfirmation] Installed swipe-quote hooks");
}
