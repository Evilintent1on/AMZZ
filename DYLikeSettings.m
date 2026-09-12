#import "DYLikeSettings.h"
#import "DYLikeCore.h"
#import <UIKit/UIKit.h>

static NSString *const kDYLikePreferenceDomain = @"com.apple.Preferences";
static NSString *const kDYLikeEnabledLikeKey = @"DYLikeEnabled_Like";
static NSString *const kDYLikeEnabledFavoriteKey = @"DYLikeEnabled_Favorite";
static NSString *const kDYLikeEnabledFollowKey = @"DYLikeEnabled_Follow";

static BOOL DYLikeReadBool(NSString *key, BOOL defaultValue) {
    Boolean keyExists = false;
    Boolean value = CFPreferencesGetAppBooleanValue((__bridge CFStringRef)key, (__bridge CFStringRef)kDYLikePreferenceDomain, &keyExists);
    return keyExists ? (BOOL)value : defaultValue;
}

static void DYLikeWriteBool(NSString *key, BOOL value) {
    CFPreferencesSetAppValue((__bridge CFStringRef)key, value ? kCFBooleanTrue : kCFBooleanFalse, (__bridge CFStringRef)kDYLikePreferenceDomain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)kDYLikePreferenceDomain);
}

BOOL DYLikeIsLikeConfirmationEnabled(void) {
    return DYLikeReadBool(kDYLikeEnabledLikeKey, YES);
}

BOOL DYLikeIsFavoriteConfirmationEnabled(void) {
    return DYLikeReadBool(kDYLikeEnabledFavoriteKey, YES);
}

BOOL DYLikeIsFollowConfirmationEnabled(void) {
    return DYLikeReadBool(kDYLikeEnabledFollowKey, YES);
}

void DYLikeSetLikeConfirmationEnabled(BOOL enabled) {
    DYLikeWriteBool(kDYLikeEnabledLikeKey, enabled);
}

void DYLikeSetFavoriteConfirmationEnabled(BOOL enabled) {
    DYLikeWriteBool(kDYLikeEnabledFavoriteKey, enabled);
}

void DYLikeSetFollowConfirmationEnabled(BOOL enabled) {
    DYLikeWriteBool(kDYLikeEnabledFollowKey, enabled);
}

@interface DYLikeSettingsViewController ()
@end

@implementation DYLikeSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"DYLike 设置";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self setupUI];
}

- (void)setupUI {
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:scrollView];

    UIStackView *stackView = [UIStackView new];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.spacing = 16;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:stackView];

    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:scrollView.topAnchor constant:16],
        [stackView.leadingAnchor constraintEqualToAnchor:scrollView.leadingAnchor constant:16],
        [stackView.trailingAnchor constraintEqualToAnchor:scrollView.trailingAnchor constant:-16],
        [stackView.widthAnchor constraintEqualToAnchor:scrollView.widthAnchor constant:-32],
        [stackView.bottomAnchor constraintEqualToAnchor:scrollView.bottomAnchor constant:-16]
    ]];

    [stackView addArrangedSubview:[self createSwitchCellWithTitle:@"点赞确认" action:@selector(likeSwitchChanged:) isOn:DYLikeIsLikeConfirmationEnabled() iconImage:@"heart.fill"]];
    [stackView addArrangedSubview:[self createSwitchCellWithTitle:@"收藏确认" action:@selector(favoriteSwitchChanged:) isOn:DYLikeIsFavoriteConfirmationEnabled() iconImage:@"bookmark.fill"]];
    [stackView addArrangedSubview:[self createSwitchCellWithTitle:@"关注确认" action:@selector(followSwitchChanged:) isOn:DYLikeIsFollowConfirmationEnabled() iconImage:@"person.badge.plus"]];
}

- (UIView *)createSwitchCellWithTitle:(NSString *)title action:(SEL)action isOn:(BOOL)isOn iconImage:(NSString *)iconName {
    UIView *cell = [UIView new];
    cell.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    cell.layer.cornerRadius = 10;
    cell.layer.masksToBounds = YES;

    UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:iconName]];
    iconView.tintColor = [UIColor labelColor];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [cell addSubview:iconView];

    UILabel *label = [UILabel new];
    label.text = title;
    label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    label.textColor = [UIColor labelColor];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [cell addSubview:label];

    UISwitch *switchControl = [UISwitch new];
    switchControl.on = isOn;
    switchControl.onTintColor = [UIColor systemGreenColor];
    [switchControl addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    switchControl.translatesAutoresizingMaskIntoConstraints = NO;
    [cell addSubview:switchControl];

    [NSLayoutConstraint activateConstraints:@[
        [cell.heightAnchor constraintEqualToConstant:50],
        [iconView.leadingAnchor constraintEqualToAnchor:cell.leadingAnchor constant:16],
        [iconView.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor],
        [iconView.widthAnchor constraintEqualToConstant:24],
        [iconView.heightAnchor constraintEqualToConstant:24],
        [label.leadingAnchor constraintEqualToAnchor:iconView.trailingAnchor constant:12],
        [label.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor],
        [switchControl.trailingAnchor constraintEqualToAnchor:cell.trailingAnchor constant:-16],
        [switchControl.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor]
    ]];

    return cell;
}

- (void)likeSwitchChanged:(UISwitch *)sender {
    DYLikeSetLikeConfirmationEnabled(sender.isOn);
}

- (void)favoriteSwitchChanged:(UISwitch *)sender {
    DYLikeSetFavoriteConfirmationEnabled(sender.isOn);
}

- (void)followSwitchChanged:(UISwitch *)sender {
    DYLikeSetFollowConfirmationEnabled(sender.isOn);
}

@end
