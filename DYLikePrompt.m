#import "DYLikePrompt.h"

static __weak DYLikePrompt *DYLikeVisiblePrompt;

@interface DYLikePrompt ()
@property(nonatomic, strong) UIView *panel;
@property(nonatomic, strong) UILabel *heading;
@property(nonatomic, copy) void (^decision)(BOOL);
@property(nonatomic) BOOL finishing;
@end

@implementation DYLikePrompt

+ (void)presentForAction:(DYLikeActionType)action intent:(DYLikeIntent)intent
                    name:(NSString *)name isComment:(BOOL)isComment
                decision:(void (^)(BOOL))decision {
    NSAssert(NSThread.isMainThread, @"Present confirmations on the main thread");
    UIWindow *window = DYLikeActiveWindow();
    if (!window || DYLikeVisiblePrompt) {
        if (decision) decision(NO);
        return;
    }
    DYLikePrompt *prompt = [[self alloc] initWithFrame:window.bounds];
    prompt.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    prompt.overrideUserInterfaceStyle = DYLikeUserInterfaceStyle();
    prompt.decision = decision;
    DYLikeVisiblePrompt = prompt;
    [window addSubview:prompt];
    [prompt configureAction:action intent:intent name:name isComment:isComment];
    [NSNotificationCenter.defaultCenter addObserver:prompt selector:@selector(cancel)
        name:UIApplicationWillResignActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:prompt selector:@selector(updateTheme)
        name:DYLikeThemeDidChangeNotification object:nil];
    [prompt layoutIfNeeded];
    prompt.alpha = 0;
    prompt.panel.transform = UIAccessibilityIsReduceMotionEnabled() ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.97, 0.97);
    [UIView animateWithDuration:UIAccessibilityIsReduceMotionEnabled() ? 0 : 0.18 animations:^{
        prompt.alpha = 1;
        prompt.panel.transform = CGAffineTransformIdentity;
    } completion:^(__unused BOOL finished) {
        if (!prompt.finishing) UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, prompt.heading);
    }];
}

- (UILabel *)labelWithText:(NSString *)text size:(CGFloat)size weight:(UIFontWeight)weight {
    UILabel *label = [UILabel new];
    label.text = text;
    label.textColor = [UIColor blackColor];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody]
        scaledFontForFont:[UIFont systemFontOfSize:size weight:weight] maximumPointSize:30];
    label.adjustsFontForContentSizeCategory = YES;
    return label;
}

- (void)configureAction:(DYLikeActionType)action intent:(DYLikeIntent)intent name:(NSString *)name isComment:(BOOL)isComment {
    self.accessibilityViewIsModal = YES;
    UIControl *scrim = [[UIControl alloc] initWithFrame:self.bounds];
    scrim.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.46];
    scrim.isAccessibilityElement = NO;
    [scrim addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:scrim];

    NSString *verb = action == DYLikeActionLike || action == DYLikeActionCommentLike ? @"点赞" :
        action == DYLikeActionCommentDislike ? @"点踩" :
        action == DYLikeActionFavorite ? @"收藏" : @"关注";
    BOOL commentAction = action == DYLikeActionCommentLike || action == DYLikeActionCommentDislike;
    NSString *title = [NSString stringWithFormat:@"是否确认%@", verb];
    NSString *confirmTitle = @"确认";
    if (intent == DYLikeIntentRemove) {
        title = [NSString stringWithFormat:@"是否取消%@", verb];
        confirmTitle = @"确认取消";
    } else if (intent == DYLikeIntentToggle && !commentAction) {
        title = [NSString stringWithFormat:@"是否更改%@状态", verb];
        confirmTitle = @"确认更改";
    }

    self.panel = [UIView new];
    self.panel.translatesAutoresizingMaskIntoConstraints = NO;
    self.panel.backgroundColor = UIColor.whiteColor;
    self.panel.layer.cornerRadius = 16;
    self.panel.layer.cornerCurve = kCACornerCurveContinuous;
    self.panel.clipsToBounds = YES;
    [self addSubview:self.panel];

    // 上半部分内容容器
    UIStackView *content = [UIStackView new];
    content.axis = UILayoutConstraintAxisVertical;
    content.spacing = 4;
    content.alignment = UIStackViewAlignmentFill;
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [self.panel addSubview:content];

    UILabel *amzzLabel = [self labelWithText:@"AMZZ" size:17 weight:UIFontWeightBold];
    [content addArrangedSubview:amzzLabel];

    self.heading = [self labelWithText:title size:14 weight:UIFontWeightRegular];
    self.heading.accessibilityTraits |= UIAccessibilityTraitHeader;
    [content addArrangedSubview:self.heading];

    if (name.length) {
        UILabel *nameLabel = [self labelWithText:name size:13 weight:UIFontWeightMedium];
        nameLabel.numberOfLines = 2;
        nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [content addArrangedSubview:nameLabel];
    }

    // 横向主分割线（浅灰色）
    UIView *horizontalDivider = [UIView new];
    horizontalDivider.translatesAutoresizingMaskIntoConstraints = NO;
    horizontalDivider.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
    [self.panel addSubview:horizontalDivider];

    // 底部按钮区域（无背景色）
    UIView *buttonContainer = [UIView new];
    buttonContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.panel addSubview:buttonContainer];

    // “取消”按钮（保持半透明灰色）
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor colorWithWhite:0 alpha:0.5] forState:UIControlStateNormal];
    cancelButton.backgroundColor = [UIColor clearColor];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [buttonContainer addSubview:cancelButton];

    // 纵向分割线
    UIView *verticalDivider = [UIView new];
    verticalDivider.translatesAutoresizingMaskIntoConstraints = NO;
    verticalDivider.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
    [buttonContainer addSubview:verticalDivider];

    // “确认” / “确认取消” 按钮（纯黑色字体）
    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [confirmButton setTitle:confirmTitle forState:UIControlStateNormal];
    [confirmButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    confirmButton.backgroundColor = [UIColor clearColor];
    confirmButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    [confirmButton addTarget:self action:@selector(confirm) forControlEvents:UIControlEventTouchUpInside];
    [buttonContainer addSubview:confirmButton];

    // 布局约束：固定宽度 280pt，高度 140pt
    NSLayoutConstraint *preferredWidth = [self.panel.widthAnchor constraintEqualToConstant:280];
    preferredWidth.priority = 999;

    NSLayoutConstraint *preferredHeight = [self.panel.heightAnchor constraintEqualToConstant:140];
    preferredHeight.priority = 999;

    [NSLayoutConstraint activateConstraints:@[
        preferredWidth,
        preferredHeight,
        [self.panel.widthAnchor constraintLessThanOrEqualToAnchor:self.safeAreaLayoutGuide.widthAnchor constant:-40],
        [self.panel.centerXAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.centerXAnchor],
        [self.panel.centerYAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.centerYAnchor],

        // 按钮容器约束（高度 44pt）
        [buttonContainer.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor],
        [buttonContainer.trailingAnchor constraintEqualToAnchor:self.panel.trailingAnchor],
        [buttonContainer.bottomAnchor constraintEqualToAnchor:self.panel.bottomAnchor],
        [buttonContainer.heightAnchor constraintEqualToConstant:44],

        // 横向分割线
        [horizontalDivider.bottomAnchor constraintEqualToAnchor:buttonContainer.topAnchor],
        [horizontalDivider.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor],
        [horizontalDivider.trailingAnchor constraintEqualToAnchor:self.panel.trailingAnchor],
        [horizontalDivider.heightAnchor constraintEqualToConstant:0.5],

        // 内容区域约束（垂直居中于 96pt 的上半空间）
        [content.centerYAnchor constraintEqualToAnchor:self.panel.topAnchor constant:48],
        [content.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor constant:16],
        [content.trailingAnchor constraintEqualToAnchor:self.panel.trailingAnchor constant:-16],

        // 取消按钮
        [cancelButton.leadingAnchor constraintEqualToAnchor:buttonContainer.leadingAnchor],
        [cancelButton.topAnchor constraintEqualToAnchor:buttonContainer.topAnchor],
        [cancelButton.bottomAnchor constraintEqualToAnchor:buttonContainer.bottomAnchor],
        [cancelButton.trailingAnchor constraintEqualToAnchor:verticalDivider.leadingAnchor],

        // 纵向分割线
        [verticalDivider.centerXAnchor constraintEqualToAnchor:buttonContainer.centerXAnchor],
        [verticalDivider.topAnchor constraintEqualToAnchor:buttonContainer.topAnchor],
        [verticalDivider.bottomAnchor constraintEqualToAnchor:buttonContainer.bottomAnchor],
        [verticalDivider.widthAnchor constraintEqualToConstant:0.5],

        // 确认按钮
        [confirmButton.leadingAnchor constraintEqualToAnchor:verticalDivider.trailingAnchor],
        [confirmButton.topAnchor constraintEqualToAnchor:buttonContainer.topAnchor],
        [confirmButton.bottomAnchor constraintEqualToAnchor:buttonContainer.bottomAnchor],
        [confirmButton.trailingAnchor constraintEqualToAnchor:buttonContainer.trailingAnchor]
    ]];
}

- (void)updateTheme {
    UIUserInterfaceStyle style = DYLikeUserInterfaceStyle();
    if (self.overrideUserInterfaceStyle != style) self.overrideUserInterfaceStyle = style;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self updateTheme];
}

- (void)confirm { [self finish:YES]; }
- (void)cancel { [self finish:NO]; }
- (BOOL)accessibilityPerformEscape { [self cancel]; return YES; }

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (!self.window && self.decision && !self.finishing) {
        self.finishing = YES;
        void (^decision)(BOOL) = self.decision;
        self.decision = nil;
        DYLikeVisiblePrompt = nil;
        [NSNotificationCenter.defaultCenter removeObserver:self];
        dispatch_async(dispatch_get_main_queue(), ^{ decision(NO); });
    }
}

- (void)finish:(BOOL)confirmed {
    if (self.finishing) return;
    self.finishing = YES;
    self.panel.userInteractionEnabled = NO;
    [NSNotificationCenter.defaultCenter removeObserver:self];
    void (^decision)(BOOL) = self.decision;
    self.decision = nil;
    [UIView animateWithDuration:UIAccessibilityIsReduceMotionEnabled() ? 0 : 0.15 animations:^{
        self.alpha = 0;
    } completion:^(__unused BOOL finished) {
        [self removeFromSuperview];
        DYLikeVisiblePrompt = nil;
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
        dispatch_async(dispatch_get_main_queue(), ^{ if (decision) decision(confirmed); });
    }];
}

+ (void)showStaleNotice {
    UIWindow *window = DYLikeActiveWindow();
    if (!window) return;
    UILabel *label = [UILabel new];
    label.overrideUserInterfaceStyle = DYLikeUserInterfaceStyle();
    label.text = @"内容已变化，本次操作已取消";
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.textColor = UIColor.blackColor;
    label.backgroundColor = UIColor.whiteColor;
    label.layer.cornerRadius = 14;
    label.layer.cornerCurve = kCACornerCurveContinuous;
    label.clipsToBounds = YES;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [window addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:window.safeAreaLayoutGuide.centerXAnchor],
        [label.topAnchor constraintEqualToAnchor:window.safeAreaLayoutGuide.topAnchor constant:16],
        [label.widthAnchor constraintEqualToAnchor:window.safeAreaLayoutGuide.widthAnchor constant:-40],
        [label.heightAnchor constraintGreaterThanOrEqualToConstant:48]
    ]];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, label.text);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [label removeFromSuperview]; });
}
@end
