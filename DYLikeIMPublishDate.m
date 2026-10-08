// DYLikeIMPublishDate.m — 作品显示发布时间
// 移植自 Yuki（publishDateLabel），签名经 39.8.0 头文件确认：
//   AWEUserWorkCollectionViewComponentCell - (id)initWithFrame:(CGRect)
//   AWEUserWorkCollectionViewComponentCell - (void)configWithViewModel:(id)
// 原理：configWithViewModel: 时从 viewModel 取发布时间，加一个 associated 的小标签
// 显示在 cell 左上角。取不到日期时标签隐藏，不影响原布局。
// 开关：DYLikePublishDateEnabledKey，默认关闭。

#import "DYLikeCore.h"
#import <objc/runtime.h>

static const void *kAMZZPublishDateLabelKey = &kAMZZPublishDateLabelKey;

static NSDate *AMZZPublishDateFromViewModel(id vm) {
    if (!vm) return nil;
    NSArray<NSString *> *sels = @[@"publishTime", @"createTime", @"createDate", @"date", @"publishDate", @"ctime"];
    for (NSString *s in sels) {
        SEL sel = NSSelectorFromString(s);
        if ([vm respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            id v = [vm performSelector:sel];
#pragma clang diagnostic pop
            if ([v isKindOfClass:[NSDate class]]) return v;
            if ([v isKindOfClass:[NSNumber class]]) {
                NSTimeInterval t = [v doubleValue];
                if (t > 1e12) t /= 1000.0;
                if (t > 1e9) return [NSDate dateWithTimeIntervalSince1970:t];
            } else if ([v isKindOfClass:[NSString class]] && [(NSString *)v length] > 0) {
                // 已经是格式化好的字符串，直接用
                return nil; // 标记：用字符串分支
            }
        }
    }
    return nil;
}

static NSString *AMZZPublishDateString(id vm) {
    if (!vm) return nil;
    // 先试字符串型
    for (NSString *s in @[@"publishTimeString", @"createTimeString", @"dateString"]) {
        SEL sel = NSSelectorFromString(s);
        if ([vm respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            id v = [vm performSelector:sel];
#pragma clang diagnostic pop
            if ([v isKindOfClass:[NSString class]] && [(NSString *)v length] > 0) return v;
        }
    }
    NSDate *d = AMZZPublishDateFromViewModel(vm);
    if (!d) return nil;
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    if ([cal isDateInToday:d]) {
        // 今天的显示"xx小时前"
        NSTimeInterval delta = -[d timeIntervalSinceNow];
        if (delta < 3600) return [NSString stringWithFormat:@"%ld分钟前", (long)(delta / 60)];
        return [NSString stringWithFormat:@"%ld小时前", (long)(delta / 3600)];
    }
    NSDateComponents *nowC = [cal components:NSCalendarUnitYear fromDate:NSDate.date];
    NSDateComponents *dC = [cal components:NSCalendarUnitYear fromDate:d];
    f.dateFormat = (nowC.year == dC.year) ? @"MM-dd" : @"yyyy-MM-dd";
    return [f stringFromDate:d];
}

static void (*orig_configWithViewModel_)(id, SEL, id) = NULL;
static void amzz_configWithViewModel_(id self, SEL _cmd, id vm) {
    orig_configWithViewModel_(self, _cmd, vm);
    UILabel *label = objc_getAssociatedObject(self, kAMZZPublishDateLabelKey);
    if (!DYLikeIMFeatureEnabled(DYLikePublishDateEnabledKey)) {
        if (label) label.hidden = YES;
        return;
    }
    NSString *text = AMZZPublishDateString(vm);
    if (!text) {
        if (label) label.hidden = YES;
        return;
    }
    if (!label) {
        label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:10];
        label.textColor = UIColor.secondaryLabelColor;
        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
        label.layer.cornerRadius = 4;
        label.clipsToBounds = YES;
        label.textAlignment = NSTextAlignmentCenter;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [(UIView *)self addSubview:label];
        [NSLayoutConstraint activateConstraints:@[
            [label.leadingAnchor constraintEqualToAnchor:[(UIView *)self leadingAnchor] constant:6],
            [label.topAnchor constraintEqualToAnchor:[(UIView *)self topAnchor] constant:6],
        ]];
        objc_setAssociatedObject(self, kAMZZPublishDateLabelKey, label, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    label.text = [NSString stringWithFormat:@" %@ ", text];
    label.hidden = NO;
}

void DYLikeIMInstallPublishDate(void) {
    Class cls = objc_getClass("AWEUserWorkCollectionViewComponentCell");
    if (!cls) return;
    Method m = class_getInstanceMethod(cls, @selector(configWithViewModel:));
    if (m) orig_configWithViewModel_ = (void *)method_setImplementation(m, (IMP)amzz_configWithViewModel_);
    NSLog(@"[DYSecondaryConfirmation] Installed publish-date hook");
}
