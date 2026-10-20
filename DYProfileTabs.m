//
//  DYProfileTabs.m
//  AMZZ
//
//  我的页分页移除：移植自 DYKiller 的个人主页精简（DKProfileCleanTabs），只保留喜欢/收藏两项。
//  控制方式（用户定）：双击分页标题切换，设置页里也有同样的两个开关——
//   - 双击「作品」标题 → 移除/恢复「收藏」分页
//   - 双击「日常」标题 → 移除/恢复「喜欢」分页
//
//  移除实现（与原版一致）：
//   - AWEUserProfileTabHelper.tabArray 懒构建并缓存（同时写 _numOfTab），分页标题由它生成。
//     自己主页上，在原实现返回后按 profileTabType（喜欢 2 / 收藏 16）去掉开启移除的分页，
//     并把结果写回 _tabArray / _numOfTab，其余读取都看到同一份数组。两项都移除时保留原数组。
//   - 状态翻转后走抖音自己的刷新路径：updateUser:shouldRefreshTab:YES 清空缓存，
//     p_updateTabView 比较新旧数组、变化时重载分页栏与页面。
//   - AMZZ 的 hook 都是运行时替换，这里同样用 class_replaceMethod，不依赖 Logos。
//
//  双击识别：在自己主页的分页栏容器上挂双击手势（不拦截单击），落点必须命中
//  「作品」或「收藏」标题视图的框内才触发；分页栏重建后自动重新定位补挂。
//

#import "DYProfileTabs.h"
#import "DYLikeCore.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <string.h>

NSString *const DYProfileRemovePostTabKey = @"DYLikeRemovePostTab";
NSString *const DYProfileRemoveDailyTabKey = @"DYLikeRemoveDailyTab";
NSString *const DYProfileRemoveLikeTabKey = @"DYLikeRemoveLikeTab";
NSString *const DYProfileRemoveFavoriteTabKey = @"DYLikeRemoveFavoriteTab";
NSString *const DYProfileRemoveFootprintTabKey = @"DYLikeRemoveFootprintTab";

// 抖音个人主页分页相关类，仅声明用到的接口（分页类型：作品 0 / 喜欢 2 / 收藏 16 / 日常 38 / 足迹 46）
@interface AWEUserProfileTabModel : NSObject
@property (nonatomic, assign) NSInteger profileTabType;
@end

@interface AWEUserProfileTabHelper : NSObject
- (NSArray<AWEUserProfileTabModel *> *)tabArray;
- (BOOL)p_isCurrentUser;
- (id)user;
- (void)updateUser:(id)user shouldRefreshTab:(BOOL)shouldRefreshTab;
@end

@interface AWEUIOrchestrationHomeComponent : NSObject
- (AWEUserProfileTabHelper *)tabHelper;
- (void)p_updateTabView;
@end

// 弱表（自己主页的分页编排组件），只在主线程读写。
static NSHashTable *DYProfileTabComponents;

static BOOL DYProfileTabRemoved(id tab) {
    if (![tab respondsToSelector:@selector(profileTabType)]) return NO;
    NSInteger type = [(AWEUserProfileTabModel *)tab profileTabType];
    NSString *key = nil;
    switch (type) {
        case 0:  key = DYProfileRemovePostTabKey; break;      // 作品
        case 38: key = DYProfileRemoveDailyTabKey; break;     // 日常
        case 2:  key = DYProfileRemoveLikeTabKey; break;      // 喜欢
        case 16: key = DYProfileRemoveFavoriteTabKey; break;  // 收藏
        case 46: key = DYProfileRemoveFootprintTabKey; break; // 足迹
        default: break;
    }
    return key && [NSUserDefaults.standardUserDefaults boolForKey:key];
}

static BOOL DYProfileTabHelperMine(AWEUserProfileTabHelper *helper) {
    return helper && [helper respondsToSelector:@selector(p_isCurrentUser)] && [helper p_isCurrentUser];
}

// 把过滤后的数组写回 _tabArray，分页数量写回 _numOfTab；ivar 不存在或类型不符时不写。
static void DYProfileTabStore(AWEUserProfileTabHelper *helper, NSArray *tabs) {
    Class cls = object_getClass(helper);
    Ivar array = class_getInstanceVariable(cls, "_tabArray");
    Ivar count = class_getInstanceVariable(cls, "_numOfTab");
    if (!array || !count) return;
    const char *arrayType = ivar_getTypeEncoding(array), *countType = ivar_getTypeEncoding(count);
    if (!arrayType || arrayType[0] != '@' || !countType || strcmp(countType, @encode(NSInteger)) != 0) return;
    object_setIvarWithStrongDefault(helper, array, tabs);
    *(NSInteger *)((uint8_t *)(__bridge void *)helper + ivar_getOffset(count)) = (NSInteger)tabs.count;
}

static NSArray *DYProfileTabFilter(AWEUserProfileTabHelper *helper, NSArray *tabs) {
    NSMutableArray *kept = [NSMutableArray arrayWithCapacity:tabs.count];
    for (id tab in tabs) {
        if (!DYProfileTabRemoved(tab)) [kept addObject:tab];
    }
    if (kept.count == tabs.count) return tabs;
    if (!kept.count) return tabs; // 全部移除时保留原数组（与原版一致）
    NSArray *filtered = [kept copy];
    DYProfileTabStore(helper, filtered);
    return filtered;
}

void DYProfileTabsRefresh(void) {
    for (AWEUIOrchestrationHomeComponent *component in DYProfileTabComponents.allObjects) {
        AWEUserProfileTabHelper *helper = [component respondsToSelector:@selector(tabHelper)] ? [component tabHelper] : nil;
        if (!DYProfileTabHelperMine(helper) || ![helper respondsToSelector:@selector(user)] ||
            ![helper respondsToSelector:@selector(updateUser:shouldRefreshTab:)] ||
            ![component respondsToSelector:@selector(p_updateTabView)]) continue;
        id user = [helper user];
        if (!user) continue;
        [helper updateUser:user shouldRefreshTab:YES];
        [component p_updateTabView];
    }
}

#pragma mark - 双击分页标题切换

static NSArray<NSString *> *DYTabKeywords(void) {
    return @[@"作品", @"喜欢", @"收藏", @"日常", @"足迹"];
}

// 视图上显示的文字（label / button / 无障碍标签）
static NSString *DYViewText(UIView *view) {
    NSString *text = nil;
    if ([view isKindOfClass:UILabel.class]) text = [(UILabel *)view text];
    else if ([view isKindOfClass:UIButton.class]) text = [(UIButton *)view titleForState:UIControlStateNormal];
    if (!text.length) text = view.accessibilityLabel;
    return text;
}

// 文字是否就是某个分页标题（允许后面跟空格+数字，如「收藏 3」）
static NSString *DYMatchedKeyword(UIView *view) {
    NSString *text = [DYViewText(view) stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (!text.length) return nil;
    for (NSString *keyword in DYTabKeywords()) {
        if ([text isEqualToString:keyword]) return keyword;
        if ([text hasPrefix:keyword] && text.length > keyword.length) {
            unichar next = [text characterAtIndex:keyword.length];
            if (next == ' ' || (next >= '0' && next <= '9')) return keyword;
        }
    }
    return nil;
}

static void DYCollectTitleViews(UIView *view, NSMutableArray<UIView *> *views, NSMutableArray<NSString *> *keywords) {
    if (view.hidden || view.alpha < 0.01) return;
    NSString *keyword = DYMatchedKeyword(view);
    if (keyword) {
        [views addObject:view];
        [keywords addObject:keyword];
    }
    for (UIView *sub in view.subviews) DYCollectTitleViews(sub, views, keywords);
}

// 在 root 里找分页栏容器：含至少 2 个分页标题、且是条状（高 <= 64）的最浅祖先。
static UIView *DYFindTabBarContainer(UIView *root) {
    if (!root) return nil;
    NSMutableArray<UIView *> *views = [NSMutableArray array];
    NSMutableArray<NSString *> *keywords = [NSMutableArray array];
    DYCollectTitleViews(root, views, keywords);
    if (views.count < 2) return nil;
    UIView *ancestor = views.firstObject.superview;
    while (ancestor && ancestor != root.superview) {
        NSUInteger inside = 0;
        for (UIView *v in views) if ([v isDescendantOfView:ancestor]) inside++;
        if (inside >= 2 && ancestor.bounds.size.height <= 64.0) return ancestor;
        ancestor = ancestor.superview;
    }
    return nil;
}

static UIView *DYComponentRootView(AWEUIOrchestrationHomeComponent *component) {
    if ([component respondsToSelector:@selector(view)]) {
        id view = [component valueForKey:@"view"];
        if ([view isKindOfClass:UIView.class]) return view;
    }
    return DYLikeActiveWindow();
}

@interface DYTabGestureHandler : NSObject
+ (instancetype)shared;
- (void)dyHandleDoubleTap:(UITapGestureRecognizer *)tap;
@end

static void DYAttachTabGesture(UIView *root);

@implementation DYTabGestureHandler

+ (instancetype)shared {
    static DYTabGestureHandler *handler;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ handler = [DYTabGestureHandler new]; });
    return handler;
}

- (void)dyHandleDoubleTap:(UITapGestureRecognizer *)tap {
    if (tap.state != UIGestureRecognizerStateRecognized) return;
    UIView *container = tap.view;
    CGPoint point = [tap locationInView:container];
    NSMutableArray<UIView *> *views = [NSMutableArray array];
    NSMutableArray<NSString *> *keywords = [NSMutableArray array];
    DYCollectTitleViews(container, views, keywords);
    NSString *hit = nil;
    for (NSUInteger i = 0; i < views.count; i++) {
        CGRect frame = [views[i] convertRect:views[i].bounds toView:container];
        if (CGRectContainsPoint(frame, point)) { hit = keywords[i]; break; }
    }
    NSString *key = nil;
    if ([hit isEqualToString:@"作品"]) key = DYProfileRemoveFavoriteTabKey;      // 双击作品 → 切换收藏
    else if ([hit isEqualToString:@"日常"]) key = DYProfileRemoveLikeTabKey;     // 双击日常 → 切换喜欢
    if (!key) return;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setBool:![defaults boolForKey:key] forKey:key];
    DYProfileTabsRefresh();
    // 分页栏会被刷新重建，稍后重新定位补挂手势
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (AWEUIOrchestrationHomeComponent *component in DYProfileTabComponents.allObjects) {
            DYAttachTabGesture(DYComponentRootView(component));
        }
    });
}

@end

static const void *DYTabGestureAttachedKey = &DYTabGestureAttachedKey;

static void DYAttachTabGesture(UIView *root) {
    UIView *container = DYFindTabBarContainer(root);
    if (!container || objc_getAssociatedObject(container, DYTabGestureAttachedKey)) return;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:DYTabGestureHandler.shared
                                                                          action:@selector(dyHandleDoubleTap:)];
    tap.numberOfTapsRequired = 2;
    tap.cancelsTouchesInView = NO; // 不影响单击切分页
    [container addGestureRecognizer:tap];
    objc_setAssociatedObject(container, DYTabGestureAttachedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Hook replacements

typedef NSArray *(*DYTabArrayIMP)(id, SEL);
static DYTabArrayIMP DYOrigTabArray;

static NSArray *DYTabArray(id self, SEL _cmd) {
    NSArray *tabs = DYOrigTabArray(self, _cmd);
    if (![tabs isKindOfClass:NSArray.class] || !tabs.count || !DYProfileTabHelperMine((AWEUserProfileTabHelper *)self)) return tabs;
    return DYProfileTabFilter((AWEUserProfileTabHelper *)self, tabs);
}

typedef void (*DYViewDidAppearIMP)(id, SEL);
static DYViewDidAppearIMP DYOrigViewDidAppear;

static void DYComponentViewDidAppear(id self, SEL _cmd) {
    DYOrigViewDidAppear(self, _cmd);
    AWEUIOrchestrationHomeComponent *component = (AWEUIOrchestrationHomeComponent *)self;
    AWEUserProfileTabHelper *helper = [component respondsToSelector:@selector(tabHelper)] ? [component tabHelper] : nil;
    if (!DYProfileTabHelperMine(helper)) return;
    if (!DYProfileTabComponents) DYProfileTabComponents = [NSHashTable weakObjectsHashTable];
    [DYProfileTabComponents addObject:self];
    // 等分页栏布局完成后再定位标题容器挂手势
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        DYAttachTabGesture(DYComponentRootView(component));
    });
}

void DYProfileTabsInstall(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class helperClass = NSClassFromString(@"AWEUserProfileTabHelper");
        Method tabArrayMethod = helperClass ? class_getInstanceMethod(helperClass, @selector(tabArray)) : NULL;
        if (tabArrayMethod) {
            DYOrigTabArray = (DYTabArrayIMP)method_getImplementation(tabArrayMethod);
            class_replaceMethod(helperClass, @selector(tabArray), (IMP)DYTabArray, method_getTypeEncoding(tabArrayMethod));
        }
        Class componentClass = NSClassFromString(@"AWEUIOrchestrationHomeComponent");
        Method appearMethod = componentClass ? class_getInstanceMethod(componentClass, @selector(viewDidAppear)) : NULL;
        if (appearMethod) {
            DYOrigViewDidAppear = (DYViewDidAppearIMP)method_getImplementation(appearMethod);
            class_replaceMethod(componentClass, @selector(viewDidAppear), (IMP)DYComponentViewDidAppear, method_getTypeEncoding(appearMethod));
        }
    });
}
