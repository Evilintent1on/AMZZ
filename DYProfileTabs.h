#import <Foundation/Foundation.h>

// 我的页分页移除（移植自 DYKiller 的个人主页精简，仅喜欢/收藏两项）
// 控制方式：双击「作品」标题切换收藏分页、双击「日常」标题切换喜欢分页；设置页有同样的两个开关
FOUNDATION_EXPORT NSString *const DYProfileRemoveLikeTabKey;
FOUNDATION_EXPORT NSString *const DYProfileRemoveFavoriteTabKey;

// 安装 hook（在 DYInstallHooks 里调用，内部只装一次）
FOUNDATION_EXPORT void DYProfileTabsInstall(void);
// 设置改动后走抖音自己的刷新路径重载分页栏（主线程调用）
FOUNDATION_EXPORT void DYProfileTabsRefresh(void);
