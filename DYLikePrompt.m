#import "DYLikePrompt.h"

static __weak DYLikePrompt *DYLikeVisiblePrompt;

@interface DYLikePrompt ()
@property(nonatomic, strong) UIView *panel;
@property(nonatomic, strong) UIStackView *buttons;
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

- (UIButton *)buttonWithTitle:(NSString *)title primary:(BOOL)primary accent:(UIColor *)accent {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody]
        scaledFontForFont:[UIFont systemFontOfSize:15 weight:UIFontWeightMedium] maximumPointSize:22];
    button.titleLabel.adjustsFontForContentSizeCategory = YES;
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = 0.8;
    button.contentEdgeInsets = UIEdgeInsetsMake(11, 8, 11, 8);
    button.layer.cornerRadius = 13;
    button.layer.cornerCurve = kCACornerCurveContinuous;
    button.backgroundColor = primary ? accent : UIColor.tertiarySystemFillColor;
    [button setTitleColor:primary ? UIColor.whiteColor : UIColor.labelColor forState:UIControlStateNormal];
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:42].active = YES;
    [button addTarget:self action:primary ? @selector(confirm) : @selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)configureAction:(DYLikeActionType)action intent:(DYLikeIntent)intent name:(NSString *)name isComment:(BOOL)isComment {
    self.accessibilityViewIsModal = YES;
    UIControl *scrim = [[UIControl alloc] initWithFrame:self.bounds];
    scrim.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.46];
    scrim.isAccessibilityElement = NO;
    [scrim addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:scrim];

    NSString *verb = action == DYLikeActionLike ? @"点赞" : action == DYLikeActionFavorite ? @"收藏" : @"关注";
    NSString *title = [NSString stringWithFormat:@"是否确认%@", verb];
    // 确认按钮改为“确认”
    NSString *confirmTitle = @"确认";
    if (intent == DYLikeIntentRemove) {
        title = [NSString stringWithFormat:@"是否取消%@", verb];
        confirmTitle = @"确认取消";
    } else if (intent == DYLikeIntentToggle) {
        title = [NSString stringWithFormat:@"是否更改%@状态", verb];
        confirmTitle = @"确认更改";
    }

    self.panel = [UIView new];
    self.panel.translatesAutoresizingMaskIntoConstraints = NO;
    self.panel.backgroundColor = UIColor.whiteColor;
    self.panel.layer.cornerRadius = 24;
    self.panel.layer.cornerCurve = kCACornerCurveContinuous;
    self.panel.clipsToBounds = YES;
    [self addSubview:self.panel];

    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.alwaysBounceVertical = NO;
    [self.panel addSubview:scroll];

    UIStackView *content = [UIStackView new];
    content.axis = UILayoutConstraintAxisVertical;
    content.spacing = 8;
    content.alignment = UIStackViewAlignmentFill;
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:content];

    UILabel *amzzLabel = [self labelWithText:@"AMZZ" size:19 weight:UIFontWeightBold];
    [content addArrangedSubview:amzzLabel];

    self.heading = [self labelWithText:title size:15 weight:UIFontWeightRegular];
    self.heading.accessibilityTraits |= UIAccessibilityTraitHeader;
    [content addArrangedSubview:self.heading];

    if (name.length) {
        UILabel *nameLabel = [self labelWithText:name size:14 weight:UIFontWeightMedium];
        nameLabel.numberOfLines = 2;
        nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [content addArrangedSubview:nameLabel];
    }

    self.buttons = [[UIStackView alloc] initWithArrangedSubviews:@[
        [self buttonWithTitle:@"取消" primary:NO accent:DYLikeAccent(action)],
        [self buttonWithTitle:confirmTitle primary:YES accent:DYLikeAccent(action)]
    ]];
    self.buttons.translatesAutoresizingMaskIntoConstraints = NO;
    self.buttons.spacing = 10;
    self.buttons.distribution = UIStackViewDistributionFillEqually;
    [self.panel addSubview:self.buttons];
    [self updateButtonAxis];

    // 将弹窗目标宽度调小至 295
    NSLayoutConstraint *preferredWidth = [self.panel.widthAnchor constraintEqualToConstant:295];
    preferredWidth.priority = 999;
    NSLayoutConstraint *contentHeight = [scroll.heightAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.heightAnchor];
    contentHeight.priority = 750;
    [NSLayoutConstraint activateConstraints:@[
        preferredWidth,
        [self.panel.widthAnchor constraintLessThanOrEqualToAnchor:self.safeAreaLayoutGuide.widthAnchor constant:-44],
        [self.panel.centerXAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.centerXAnchor],
        [self.panel.centerYAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.centerYAnchor],
        [self.panel.topAnchor constraintGreaterThanOrEqualToAnchor:self.safeAreaLayoutGuide.topAnchor constant:12],
        [self.panel.bottomAnchor constraintLessThanOrEqualToAnchor:self.safeAreaLayoutGuide.bottomAnchor constant:-12],
        [scroll.topAnchor constraintEqualToAnchor:self.panel.topAnchor constant:20],
        [scroll.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor constant:18],
        [scroll.trailingAnchor constraintEqualToAnchor:self.panel.trailingAnchor constant:-18],
        [scroll.heightAnchor constraintGreaterThanOrEqualToConstant:32], contentHeight,
        [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [content.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [content.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor],
        [self.buttons.topAnchor constraintEqualToAnchor:scroll.bottomAnchor constant:18],
        [self.buttons.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor constant:18],
        [self.buttons.trailingAnchor constraintEqualToAnchor:self.panel.trailingAnchor constant:-18],
        [self.buttons.bottomAnchor constraintEqualToAnchor:self.panel.bottomAnchor constant:-18]
    ]];
}

- (void)updateButtonAxis {
    self.buttons.axis = UIContentSizeCategoryIsAccessibilityCategory(self.traitCollection.preferredContentSizeCategory) ?
        UILayoutConstraintAxisVertical : UILayoutConstraintAxisHorizontal;
}

- (void)updateTheme {
    UIUserInterfaceStyle style = DYLikeUserInterfaceStyle();
    if (self.overrideUserInterfaceStyle != style) self.overrideUserInterfaceStyle = style;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self updateTheme];
    [self updateButtonAxis];
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
    self.buttons.userInteractionEnabled = NO;
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
