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
FOUNDATION_EXPORT NSString *const DYLikeAntiRecallEnabledKey;
FOUNDATION_EXPORT NSNotificationName const DYLikeThemeDidChangeNotification;

// 私信增强 (Yuki 功能移植)
FOUNDATION_EXPORT NSString *const DYLikeVoiceTranslateEnabledKey;      // 语音自动转文字
FOUNDATION_EXPORT NSString *const DYLikeStealthEnabledKey;             // 隐身：隐藏在线状态
FOUNDATION_EXPORT NSString *const DYLikeAudioShareEnabledKey;          // 语音转发
FOUNDATION_EXPORT NSString *const DYLikeWatchOnceEnabledKey;           // 阅后即焚防销毁
FOUNDATION_EXPORT NSString *const DYLikeSwipeQuoteEnabledKey;          // 左滑引用
FOUNDATION_EXPORT NSString *const DYLikeHideTimeEnabledKey;            // 隐藏聊天自带时间
FOUNDATION_EXPORT NSString *const DYLikeCustomTimeEnabledKey;          // 显示自定义时间标签
FOUNDATION_EXPORT NSString *const DYLikeTimeLabelColorKey;             // 时间标签颜色
FOUNDATION_EXPORT NSString *const DYLikeDiceEnabledKey;                // 摇骰子/猜拳
FOUNDATION_EXPORT NSString *const DYLikeAudioDurationEnabledKey;      // 自定义语音时长
FOUNDATION_EXPORT NSString *const DYLikeAudioDurationSecKey;         // 语音时长配置（"10" 或 "5~15"）
FOUNDATION_EXPORT NSString *const DYLikeTabBarMarkReadEnabledKey;     // 长按"消息"标已读
FOUNDATION_EXPORT NSString *const DYLikeTabBarSwitchAccountEnabledKey; // 长按"我"切换账号
FOUNDATION_EXPORT NSString *const DYLikePublishDateEnabledKey;        // 作品显示发布时间
FOUNDATION_EXPORT NSString *const DYLikeAutoMsgEnabledKey;            // 自动消息任务

FOUNDATION_EXPORT void DYLikeEnsureDefaults(void);
FOUNDATION_EXPORT BOOL DYLikeEnabled(DYLikeActionType action);
FOUNDATION_EXPORT BOOL DYLikeAntiRecallEnabled(void);
FOUNDATION_EXPORT BOOL DYLikeIMFeatureEnabled(NSString *key);
FOUNDATION_EXPORT BOOL DYLikeIsReplaying(DYLikeActionType action);
FOUNDATION_EXPORT id DYLikeRead(id object, NSString *key);
FOUNDATION_EXPORT UIWindow *DYLikeActiveWindow(void);
FOUNDATION_EXPORT UIColor *DYLikeAccent(DYLikeActionType action);
FOUNDATION_EXPORT UIUserInterfaceStyle DYLikeUserInterfaceStyle(void);
FOUNDATION_EXPORT void DYLikeInstallThemeHooks(void);

// 根据开关和操作状态显示确认弹窗，确认后执行对应操作。
FOUNDATION_EXPORT void DYLikeGuard(DYLikeActionType action, DYLikeIntent intent,
                                  id owner, id subject, dispatch_block_t operation,
                                  dispatch_block_t cancellation, dispatch_block_t confirmedUnfollow);
