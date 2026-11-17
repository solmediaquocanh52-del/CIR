#import "CSCircleSwitcherLogoCell.h"

@implementation CSCircleSwitcherLogoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.backgroundView = [[UIView alloc] init];
        self.backgroundView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        titleLabel.text = @"CircleSwitcher 2.0.0";
        titleLabel.font = [UIFont systemFontOfSize:26.0 weight:UIFontWeightBold];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        if (@available(iOS 13.0, *)) {
            titleLabel.textColor = [UIColor labelColor];
        }

        UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        subtitleLabel.text = @"3D Circular Wheel & Liquid Glass Switcher";
        subtitleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
        subtitleLabel.textAlignment = NSTextAlignmentCenter;
        if (@available(iOS 13.0, *)) {
            subtitleLabel.textColor = [UIColor secondaryLabelColor];
        } else {
            subtitleLabel.textColor = [UIColor grayColor];
        }

        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, subtitleLabel]];
        stack.translatesAutoresizingMaskIntoConstraints = NO;
        stack.axis = UILayoutConstraintAxisVertical;
        stack.alignment = UIStackViewAlignmentCenter;
        stack.spacing = 4.0;

        [self.contentView addSubview:stack];
        [NSLayoutConstraint activateConstraints:@[
            [stack.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [stack.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor]
        ]];
    }
    return self;
}

@end
