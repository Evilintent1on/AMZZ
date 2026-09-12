#import "DYLikeSettings.h"
#import "DYLikeCore.h"

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

    [stackView addArrangedSubview:[self createSwitchCellWithTitle:@"开启点赞确认" 
                                                           action:@selector(likeSwitchChanged:) 
                                                           isOn:DYLikeIsLikeConfirmationEnabled()]];
    [stackView addArrangedSubview:[self createSwitchCellWithTitle:@"开启收藏确认" 
                                                           action:@selector(favoriteSwitchChanged:) 
                                                           isOn:DYLikeIsFavoriteConfirmationEnabled()]];
    [stackView addArrangedSubview:[self createSwitchCellWithTitle:@"开启关注确认" 
                                                           action:@selector(followSwitchChanged:) 
                                                           isOn:DYLikeIsFollowConfirmationEnabled()]];
}

- (UIView *)createSwitchCellWithTitle:(NSString *)title action:(SEL)action isOn:(BOOL)isOn {
    UIView *cell = [UIView new];
    cell.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    cell.layer.cornerRadius = 10;
    cell.layer.masksToBounds = YES;

    UILabel *label = [UILabel new];
    label.text = title;
    label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    label.textColor = [UIColor labelColor];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [cell addSubview:label];

    UISwitch *switchControl = [UISwitch new];
    switchControl.on = isOn;
    
    // 强制使用 iOS 系统默认绿色
    switchControl.onTintColor = [UIColor systemGreenColor];
    
    [switchControl addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    switchControl.translatesAutoresizingMaskIntoConstraints = NO;
    [cell addSubview:switchControl];

    [NSLayoutConstraint activateConstraints:@[
        [cell.heightAnchor constraintEqualToConstant:50],
        [label.leadingAnchor constraintEqualToAnchor:cell.leadingAnchor constant:16],
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
