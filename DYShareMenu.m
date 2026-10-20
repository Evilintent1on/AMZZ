//
//  DYShareMenu.m
//  AMZZ
//
//  分享面板精简：移植自 DYKiller 的同名功能（DKShareMenu + DKShareMenuClean）。
//
//  实现（与原版一致）：
//   - 作品分享面板的数据由 AWESharePanelFunctionsDataManager 装配：先发配置请求
//     （shareContext 带 aweme 的才是作品面板），随后 setDataSource: 收到「行 × 功能模型」。
//   - 每个功能模型的 function.shareType 是稳定业务标识，title 是显示文案。
//     过滤时把见过的按钮收录进持久目录（设置页据此生成开关），开启移除的行按标识剔除，
//     空行一并收起；联系人行不是功能模型、天然保留。设置改动下次打开面板生效。
//   - AMZZ 的 hook 都是运行时替换，这里同样用 class_replaceMethod，不依赖 Logos。
//

#import "DYShareMenu.h"
#import <objc/runtime.h>

static NSString *const DYShareMenuCatalogKey = @"DYShareMenuCatalog";
static NSString *const DYShareMenuHidePrefix = @"DYShareMenuHide.";
static NSString *const DYShareMenuOrderKey = @"DYShareMenuOrder";

@protocol DYShareMenuFunction <NSObject>
- (NSString *)shareType;
@end

@protocol DYShareMenuModel <NSObject>
- (id<DYShareMenuFunction>)function;
- (NSString *)title;
@end

@protocol DYShareMenuLocalizations <NSObject>
+ (instancetype)sharedInstance;
- (NSString *)translatedStringForString:(NSString *)string;
@end

@interface AWEShareContext : NSObject
- (id)aweme;
@end

static BOOL DYShareMenuValidID(id itemID) {
    if (![itemID isKindOfClass:NSString.class] || ![itemID length] || [itemID length] > 128) return NO;
    static NSCharacterSet *invalid;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSMutableCharacterSet *characters = [NSCharacterSet.whitespaceAndNewlineCharacterSet mutableCopy];
        [characters formUnionWithCharacterSet:NSCharacterSet.controlCharacterSet];
        invalid = [characters copy];
    });
    return [itemID rangeOfCharacterFromSet:invalid].location == NSNotFound;
}

static NSString *DYShareMenuItemID(id<DYShareMenuModel> model) {
    if (![model respondsToSelector:@selector(function)]) return nil;
    id<DYShareMenuFunction> function = model.function;
    if (![function respondsToSelector:@selector(shareType)]) return nil;
    id itemID = function.shareType;
    return DYShareMenuValidID(itemID) ? itemID : nil;
}

NSArray<NSDictionary *> *DYShareMenuCatalog(void) {
    id stored = [NSUserDefaults.standardUserDefaults objectForKey:DYShareMenuCatalogKey];
    if (![stored isKindOfClass:NSArray.class]) return @[];
    NSMutableArray *catalog = [NSMutableArray array];
    for (id entry in stored) {
        if ([entry isKindOfClass:NSDictionary.class] && DYShareMenuValidID(entry[@"id"])) {
            [catalog addObject:entry];
        }
    }
    return catalog;
}

NSString *DYShareMenuHideKey(NSString *itemID) {
    return [DYShareMenuHidePrefix stringByAppendingString:itemID];
}

static void DYShareMenuRecord(NSArray<NSDictionary *> *entries) {
    if (!entries.count) return;
    NSArray *old = DYShareMenuCatalog();
    NSMutableArray *catalog = [old mutableCopy];
    NSMutableSet *known = [NSMutableSet set];
    for (NSDictionary *entry in old) [known addObject:entry[@"id"]];
    for (NSDictionary *entry in entries) {
        NSString *itemID = entry[@"id"];
        if ([known containsObject:itemID]) continue;
        [known addObject:itemID];
        [catalog addObject:entry];
    }
    if (catalog.count != old.count) {
        [NSUserDefaults.standardUserDefaults setObject:catalog forKey:DYShareMenuCatalogKey];
    }
}

NSArray<NSString *> *DYShareMenuOrder(void) {
    id stored = [NSUserDefaults.standardUserDefaults objectForKey:DYShareMenuOrderKey];
    if (![stored isKindOfClass:NSArray.class]) return @[];
    NSMutableArray *order = [NSMutableArray array];
    for (id itemID in stored) if (DYShareMenuValidID(itemID)) [order addObject:itemID];
    return order;
}

void DYShareMenuSetOrder(NSArray<NSString *> *order) {
    [NSUserDefaults.standardUserDefaults setObject:order forKey:DYShareMenuOrderKey];
}

// 同一行内按自定义顺序重排：列入顺序表的按名次在前，未列入的保持原相对顺序跟在后面；
// 行里只要有元素拿不到标识（不是功能行）就不动这一行。
static NSArray *DYShareMenuSortedLine(NSArray *kept) {
    NSArray<NSString *> *order = DYShareMenuOrder();
    if (!order.count || kept.count < 2) return kept;
    NSMutableDictionary<NSString *, NSNumber *> *rank = [NSMutableDictionary dictionary];
    [order enumerateObjectsUsingBlock:^(NSString *itemID, NSUInteger idx, BOOL *stop) {
        rank[itemID] = @(idx);
    }];
    NSMutableArray *indexed = [NSMutableArray arrayWithCapacity:kept.count];
    for (NSUInteger i = 0; i < kept.count; i++) {
        NSString *itemID = DYShareMenuItemID(kept[i]);
        if (!itemID) return kept;
        [indexed addObject:@{ @"m": kept[i], @"r": rank[itemID] ?: @(NSIntegerMax), @"i": @(i) }];
    }
    [indexed sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        NSComparisonResult c = [a[@"r"] compare:b[@"r"]];
        return c != NSOrderedSame ? c : [a[@"i"] compare:b[@"i"]];
    }];
    NSMutableArray *sorted = [NSMutableArray arrayWithCapacity:kept.count];
    for (NSDictionary *entry in indexed) [sorted addObject:entry[@"m"]];
    return sorted;
}

NSArray *DYShareMenuFilter(NSArray *lines) {
    if (![lines isKindOfClass:NSArray.class]) return lines;
    Class localizationClass = NSClassFromString(@"ALPLocalizationsManager");
    id<DYShareMenuLocalizations> localizations = [localizationClass respondsToSelector:@selector(sharedInstance)]
        ? [(id<DYShareMenuLocalizations>)localizationClass sharedInstance] : nil;
    NSMutableArray *entries = [NSMutableArray array];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:lines.count];
    BOOL changed = NO;
    for (id line in lines) {
        if (![line isKindOfClass:NSArray.class]) {
            [result addObject:line];
            continue;
        }
        NSMutableArray *kept = [NSMutableArray arrayWithCapacity:[line count]];
        for (id<DYShareMenuModel> model in line) {
            NSString *itemID = DYShareMenuItemID(model);
            if (itemID) {
                id title = [model respondsToSelector:@selector(title)] ? model.title : nil;
                if (![title isKindOfClass:NSString.class] || ![title length]) title = itemID;
                NSString *localized = [localizations respondsToSelector:@selector(translatedStringForString:)]
                    ? [localizations translatedStringForString:title] : nil;
                [entries addObject:@{ @"id": itemID, @"title": localized.length ? localized : title }];
            }
            if (itemID && [NSUserDefaults.standardUserDefaults boolForKey:DYShareMenuHideKey(itemID)]) changed = YES;
            else [kept addObject:model];
        }
        NSArray *sortedKept = DYShareMenuSortedLine(kept);
        if (kept.count == [line count] && [sortedKept isEqualToArray:kept]) {
            [result addObject:line];
        } else {
            changed = YES;
            if (sortedKept.count) [result addObject:sortedKept];
        }
    }
    DYShareMenuRecord(entries);
    return changed ? [result copy] : lines;
}

#pragma mark - Hook replacements

static char kDYShareMenuWorkContextKey;

typedef void (*DYFetchConfigIMP)(id, SEL, id, AWEShareContext *, id, id);
static DYFetchConfigIMP DYOrigFetchConfig;

static void DYFetchConfig(id self, SEL _cmd, id scene, AWEShareContext *context, id configuration, id shareView) {
    BOOL work = [context respondsToSelector:@selector(aweme)] && context.aweme != nil;
    objc_setAssociatedObject(self, &kDYShareMenuWorkContextKey, @(work), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    DYOrigFetchConfig(self, _cmd, scene, context, configuration, shareView);
}

typedef void (*DYSetDataSourceIMP)(id, SEL, NSArray *);
static DYSetDataSourceIMP DYOrigSetDataSource;

static void DYSetDataSource(id self, SEL _cmd, NSArray *dataSource) {
    if ([objc_getAssociatedObject(self, &kDYShareMenuWorkContextKey) boolValue]) {
        dataSource = DYShareMenuFilter(dataSource);
    }
    DYOrigSetDataSource(self, _cmd, dataSource);
}

void DYShareMenuInstall(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class managerClass = NSClassFromString(@"AWESharePanelFunctionsDataManager");
        if (!managerClass) return;
        SEL fetchSelector = @selector(fetchSharePanelFunctionConfigWithScene:shareContext:customConfiguration:shareView:);
        Method fetchMethod = class_getInstanceMethod(managerClass, fetchSelector);
        if (fetchMethod) {
            DYOrigFetchConfig = (DYFetchConfigIMP)method_getImplementation(fetchMethod);
            class_replaceMethod(managerClass, fetchSelector, (IMP)DYFetchConfig, method_getTypeEncoding(fetchMethod));
        }
        Method dataSourceMethod = class_getInstanceMethod(managerClass, @selector(setDataSource:));
        if (dataSourceMethod) {
            DYOrigSetDataSource = (DYSetDataSourceIMP)method_getImplementation(dataSourceMethod);
            class_replaceMethod(managerClass, @selector(setDataSource:), (IMP)DYSetDataSource, method_getTypeEncoding(dataSourceMethod));
        }
    });
}
