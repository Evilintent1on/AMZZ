#import <Foundation/Foundation.h>

// 液态玻璃底栏（移植路线 C 的草稿：Una159 DYYY 的 DYYYLiquidGlass.xm 玻璃半截，
// 改写为 AMZZ 惯例的运行时 swizzle；原版是 Logos %hook 写法）
// 开关：设置页加一行 UISwitch 读写 DYGlassTabBarEnabledKey 即可
FOUNDATION_EXPORT NSString *const DYGlassTabBarEnabledKey;

// 安装 hook（在 DYInstallHooks 里调 DYProfileTabsInstall() 的位置加一行 DYGlassTabBarInstall();，内部只装一次）
FOUNDATION_EXPORT void DYGlassTabBarInstall(void);
