#import <Foundation/Foundation.h>

// 分享面板精简（移植自 DYKiller）：收录作品分享面板出现过的功能按钮，按开关逐个移除
FOUNDATION_EXPORT NSArray<NSDictionary *> *DYShareMenuCatalog(void);
FOUNDATION_EXPORT NSString *DYShareMenuHideKey(NSString *itemID);
/// 收录原始功能行，再按移除开关过滤；空行一并移除，未调整时返回原数组。
FOUNDATION_EXPORT NSArray *DYShareMenuFilter(NSArray *lines);

// 安装 hook（在 DYInstallHooks 里调用，内部只装一次）
FOUNDATION_EXPORT void DYShareMenuInstall(void);
