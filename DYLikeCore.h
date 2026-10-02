#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DYLikeActionType) {
    DYLikeActionLike,
    DYLikeActionFavorite,
    DYLikeActionFollow,
    DYLikeActionCommentLike,
    DYLikeActionCommentDislike,
    DYLikeActionCount,
};

typedef NS_ENUM(NSUInteger, DYLikeIntent) {
    DYLikeIntentToggle,
    DYLikeIntentAdd,
    DYLikeIntentRemove,
};

FOUNDATION_EXPORT NSString *const DYLikeVersion;
FOUNDATION_EXPORT NSString *const DYLikeRepositoryURL;
FOUNDATION_EXPORT NSString *const DYLikeAuthor;
FOUNDATION_EXPORT NSString *const DYLikeLikeEnabledKey;
FOUNDATION_EXPORT NSString *const DYLikeFavoriteEnabledKey;
FOUNDATION_EXPORT NSString *const DYLikeFollowEnabledKey;
FOUNDATION_EXPORT NSString *const DYLikeCommentLikeEnabledKey;
FOUNDATION_EXPORT NSString *const DYLikeCommentDislikeEnabledKey;
FOUNDATION_EXPORT NSNotificationName const DYLikeThemeDidChangeNotification;

FOUNDATION_EXPORT void DYLikeEnsureDefaults(void);
FOUNDATION_EXPORT BOOL DYLikeEnabled(DYLikeActionType action);
FOUNDATION_EXPORT BOOL DYLikeIsReplaying(DYLikeActionType action);
FOUNDATION_EXPORT id DYLikeRead(id object, NSString *key);
FOUNDATION_EXPORT UIWindow *DYLikeActiveWindow(void);
FOUNDATION_EXPORT UIColor *DYLikeAccent(DYLikeActionType action);
FOUNDATION_EXPORT UIUserInterfaceStyle DYLikeUserInterfaceStyle(void);
FOUNDATION_EXPORT void DYLikeInstallThemeHooks(void);

// DYYY 风格主题色
FOUNDATION_EXPORT UIColor *DYLikeBgColor(void);
FOUNDATION_EXPORT UIColor *DYLikeCellColor(void);
FOUNDATION_EXPORT UIColor *DYLikeTextColor(void);
FOUNDATION_EXPORT UIColor *DYLikeSubTextColor(void);
FOUNDATION_EXPORT UIColor *DYLikeSeparatorColor(void);
// DYYY 风格 12pt 圆角卡片背景
static inline UIView *DYLikeRoundedCardBg(NSInteger rows, NSInteger row, UIColor *color) {
    UIView *bg = [[UIView alloc] init];
    bg.backgroundColor = color;
    bg.layer.cornerRadius = 10;
    bg.layer.masksToBounds = YES;
    if (rows == 1) {
        bg.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    } else if (row == 0) {
        bg.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    } else if (row == rows - 1) {
        bg.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    } else {
        bg.layer.cornerRadius = 0;
    }
    return bg;
}

// 根据开关和操作状态显示确认弹窗，确认后执行对应操作。
FOUNDATION_EXPORT void DYLikeGuard(DYLikeActionType action, DYLikeIntent intent,
                                  id owner, id subject, dispatch_block_t operation,
                                  dispatch_block_t cancellation, dispatch_block_t confirmedUnfollow);
