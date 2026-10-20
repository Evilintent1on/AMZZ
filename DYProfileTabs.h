#import <Foundation/Foundation.h>

// 我的页分页移除（移植自 DYKiller 的个人主页精简：作品/日常/喜欢/收藏/足迹五项）
// 控制方式：喜欢/收藏可用双击标题切换（作品→收藏、日常→喜欢），五项在设置页都有开关
FOUNDATION_EXPORT NSString *const DYProfileRemovePostTabKey;
FOUNDATION_EXPORT NSString *const DYProfileRemoveDailyTabKey;
FOUNDATION_EXPORT NSString *const DYProfileRemoveLikeTabKey;
FOUNDATION_EXPORT NSString *const DYProfileRemoveFavoriteTabKey;
FOUNDATION_EXPORT NSString *const DYProfileRemoveFootprintTabKey;

// 安装 hook（在 DYInstallHooks 里调用，内部只装一次）
FOUNDATION_EXPORT void DYProfileTabsInstall(void);
// 设置改动后走抖音自己的刷新路径重载分页栏（主线程调用）
FOUNDATION_EXPORT void DYProfileTabsRefresh(void);
