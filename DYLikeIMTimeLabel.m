// DYLikeIMTimeLabel.m — 聊天时间标签：隐藏自带 + 自定义显示 + 颜色
// 移植自 Yuki (YukiHideDYMsgTimeLabel / addTimeLabelToCell:withMessage:)。
// 签名：
//   AWEIMMessageBaseHeaderView - (void)layoutSubviews                      （UIView 标准签名）
//   AWEIMMessageListViewController - (void)tableView:willDisplayCell:forRowAtIndexPath:
//                                                                     （39.8.0 头文件确认）
// 原理：
//   * 隐藏自带：layoutSubviews 后把 timeLabel / timeLabelBgView 设 hidden
//   * 自定义：在 willDisplayCell 时给 cell 加一个 associated 的 UILabel，显示消息时间的
//     智能格式（今天 HH:mm / 昨天 HH:mm / 今年 MM-dd HH:mm / 更早 yyyy-MM-dd）
// 开关：DYLikeHideTimeEnabledKey / DYLikeCustomTimeEnabledKey / DYLikeTimeLabelColorKey，默认关闭。

#import "DYLikeCore.h"
#import <objc/runtime.h>

static const void *kAMZZTimeLabelKey = &kAMZZTimeLabelKey;

// ---------- 颜色 ----------
static UIColor *AMZZTimeLabelColor(void) {
    NSString *name = [[NSUserDefaults standardUserDefaults] stringForKey:DYLikeTimeLabelColorKey];
    if ([name isEqualToString:@"白色"]) return UIColor.whiteColor;
    if ([name isEqualToString:@"黑色"]) return UIColor.blackColor;
    if ([name isEqualToString:@"蓝色"]) return [UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:1.0];
    if ([name isEqualToString:@"红色"]) return [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1.0];
    if ([name isEqualToString:@"灰色"]) return UIColor.grayColor;
    return UIColor.secondaryLabelColor; // 跟随系统（默认）
}

// ---------- 从消息对象取日期（多 selector 防御） ----------
static NSDate *AMZZMessageDate(id message) {
    if (!message) return nil;
    NSArray<NSString *> *sels = @[@"date", @"createTime", @"createdAt", @"msgDate", @"timestamp", @"sendTime"];
    for (NSString *s in sels) {
        SEL sel = NSSelectorFromString(s);
        if ([message respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            id v = [message performSelector:sel];
#pragma clang diagnostic pop
            if ([v isKindOfClass:[NSDate class]]) return v;
            if ([v isKindOfClass:[NSNumber class]]) {
                NSTimeInterval t = [v doubleValue];
                if (t > 1e12) t /= 1000.0; // 毫秒
                return [NSDate dateWithTimeIntervalSince1970:t];
            }
        }
    }
    return nil;
}

// ---------- 智能格式 ----------
static NSString *AMZZFormatDate(NSDate *date) {
    if (!date) return nil;
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDateFormatter *f = [[NSDateFormatter alloc] init];
    if ([cal isDateInToday:date]) {
        f.dateFormat = @"HH:mm";
    } else if ([cal isDateInYesterday:date]) {
        f.dateFormat = @"'昨天' HH:mm";
    } else {
        NSDateComponents *nowC = [cal components:NSCalendarUnitYear fromDate:NSDate.date];
        NSDateComponents *dC = [cal components:NSCalendarUnitYear fromDate:date];
        f.dateFormat = (nowC.year == dC.year) ? @"MM-dd HH:mm" : @"yyyy-MM-dd";
    }
    return [f stringFromDate:date];
}

// ---------- 给 cell 加/刷新自定义时间标签 ----------
static void AMZZAddTimeLabelToCell(UITableViewCell *cell, id message) {
    if (!cell || !message) return;
    NSDate *date = AMZZMessageDate(message);
    NSString *text = AMZZFormatDate(date);
    UILabel *label = objc_getAssociatedObject(cell, kAMZZTimeLabelKey);
    if (!text) {
        label.hidden = YES;
        return;
    }
    if (!label) {
        label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:11];
        label.textAlignment = NSTextAlignmentCenter;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:label];
        [NSLayoutConstraint activateConstraints:@[
            [label.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:4],
            [label.centerXAnchor constraintEqualToAnchor:cell.contentView.centerXAnchor],
        ]];
        objc_setAssociatedObject(cell, kAMZZTimeLabelKey, label, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    label.text = text;
    label.textColor = AMZZTimeLabelColor();
    label.hidden = NO;
}

// ---------- hook: AWEIMMessageBaseHeaderView layoutSubviews → 隐藏自带时间 ----------
static void (*orig_headerLayoutSubviews)(id, SEL) = NULL;
static void amzz_headerLayoutSubviews(id self, SEL _cmd) {
    orig_headerLayoutSubviews(self, _cmd);
    if (!DYLikeIMFeatureEnabled(DYLikeHideTimeEnabledKey)) return;
    for (NSString *s in @[@"timeLabel", @"timeLabelBgView"]) {
        SEL sel = NSSelectorFromString(s);
        if ([self respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            UIView *v = [self performSelector:sel];
#pragma clang diagnostic pop
            if ([v isKindOfClass:[UIView class]]) v.hidden = YES;
        }
    }
}

// ---------- hook: willDisplayCell → 挂自定义时间标签 ----------
static void (*orig_willDisplayCell)(id, SEL, id, id, id) = NULL;
static void amzz_willDisplayCell(id self, SEL _cmd, id tv, id cell, id indexPath) {
    orig_willDisplayCell(self, _cmd, tv, cell, indexPath);
    if (!DYLikeIMFeatureEnabled(DYLikeCustomTimeEnabledKey)) return;
    @try {
        NSInteger row = [(NSIndexPath *)indexPath row];
        id messages = nil;
        if ([self respondsToSelector:@selector(messages)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            messages = [self performSelector:@selector(messages)];
#pragma clang diagnostic pop
        }
        id message = nil;
        if ([messages isKindOfClass:[NSArray class]] && row >= 0 && row < (NSInteger)[(NSArray *)messages count]) {
            message = [(NSArray *)messages objectAtIndex:(NSUInteger)row];
        }
        AMZZAddTimeLabelToCell((UITableViewCell *)cell, message);
    } @catch (NSException *e) {
        NSLog(@"[DYSecondaryConfirmation] time label error: %@", e);
    }
}

void DYLikeIMInstallTimeLabel(void) {
    Class hc = objc_getClass("AWEIMMessageBaseHeaderView");
    if (hc) {
        Method m = class_getInstanceMethod(hc, @selector(layoutSubviews));
        if (m) orig_headerLayoutSubviews = (void (*)(id, SEL))method_setImplementation(m, (IMP)amzz_headerLayoutSubviews);
    }
    Class vc = objc_getClass("AWEIMMessageListViewController");
    if (vc) {
        Method m = class_getInstanceMethod(vc, @selector(tableView:willDisplayCell:forRowAtIndexPath:));
        if (m) orig_willDisplayCell = (void (*)(id, SEL, id, id, id))method_setImplementation(m, (IMP)amzz_willDisplayCell);
    }
    NSLog(@"[DYSecondaryConfirmation] Installed time-label hooks");
}
