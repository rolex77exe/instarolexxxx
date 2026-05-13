#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSArray<NSString *> *RXDeveloperLinkTokens(void) {
    static NSArray<NSString *> *tokens;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tokens = @[
            @"telegram",
            @"github",
            @"x page",
            @"xpage",
            @"buy me a coffee",
            @"boosty",
            @"boosty.to",
            @"donate",
            @"telegram channel",
            @"github page",
            @"support bhttpp",
            @"bhttpp",
            @"tap to join the telegram",
            @"geliştirici",
            @"developer"
        ];
    });
    return tokens;
}

static UITableViewCell *RXFindParentCellForView(UIView *view) {
    UIView *cursor = view;
    while (cursor != nil) {
        if ([cursor isKindOfClass:[UITableViewCell class]]) {
            return (UITableViewCell *)cursor;
        }
        cursor = cursor.superview;
    }
    return nil;
}

static void RXDisableDeveloperCell(UITableViewCell *cell) {
    if (cell == nil) {
        return;
    }
    cell.hidden = YES;
    cell.userInteractionEnabled = NO;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.contentView.hidden = YES;
}

static NSString *RXRebrandText(NSString *text) {
    if (text.length == 0) {
        return text;
    }

    NSError *error = nil;
    NSRegularExpression *regex =
        [NSRegularExpression regularExpressionWithPattern:@"BHTikTokpp|BHTikTok\\s*\\+\\+|BHTikTok\\s*Plus|BHTT\\s*\\+\\+|BHTTPP|BHTikTok|BHTiktok"
                                                  options:NSRegularExpressionCaseInsensitive
                                                    error:&error];
    if (error != nil || regex == nil) {
        return text;
    }

    return [regex stringByReplacingMatchesInString:text
                                           options:0
                                             range:NSMakeRange(0, text.length)
                                      withTemplate:@"rolex7exe"];
}

static BOOL RXContainsDeveloperLinkToken(NSString *text) {
    if (text.length == 0) {
        return NO;
    }

    NSString *lower = text.lowercaseString;
    for (NSString *token in RXDeveloperLinkTokens()) {
        if ([lower containsString:token]) {
            return YES;
        }
    }
    return NO;
}

static void RXPatchLabel(UILabel *label, BOOL *developerLinkFound) {
    if (label == nil) {
        return;
    }

    NSString *currentText = label.text;
    NSString *updatedText = RXRebrandText(currentText);
    if (updatedText != nil && ![updatedText isEqualToString:currentText]) {
        label.text = updatedText;
    }

    if (RXContainsDeveloperLinkToken(currentText) || RXContainsDeveloperLinkToken(updatedText)) {
        if (developerLinkFound != NULL) {
            *developerLinkFound = YES;
        }
        label.text = @"";
        label.hidden = YES;
        RXDisableDeveloperCell(RXFindParentCellForView(label));
    }
}

static void RXPatchButton(UIButton *button, BOOL *developerLinkFound) {
    if (button == nil) {
        return;
    }

    NSString *title = [button titleForState:UIControlStateNormal];
    NSString *updatedTitle = RXRebrandText(title);
    if (updatedTitle != nil && ![updatedTitle isEqualToString:title]) {
        [button setTitle:updatedTitle forState:UIControlStateNormal];
    }

    if (RXContainsDeveloperLinkToken(title) || RXContainsDeveloperLinkToken(updatedTitle)) {
        if (developerLinkFound != NULL) {
            *developerLinkFound = YES;
        }
        button.hidden = YES;
        button.enabled = NO;
        button.userInteractionEnabled = NO;
        RXDisableDeveloperCell(RXFindParentCellForView(button));
    }
}

static void RXPatchViewTree(UIView *view, BOOL *developerLinkFound) {
    if (view == nil) {
        return;
    }

    if ([view isKindOfClass:[UILabel class]]) {
        RXPatchLabel((UILabel *)view, developerLinkFound);
    } else if ([view isKindOfClass:[UIButton class]]) {
        RXPatchButton((UIButton *)view, developerLinkFound);
    }

    for (UIView *subview in view.subviews) {
        RXPatchViewTree(subview, developerLinkFound);
    }
}

static void RXPatchCell(UITableViewCell *cell) {
    if (cell == nil) {
        return;
    }

    BOOL developerLinkFound = NO;
    RXPatchViewTree(cell.contentView, &developerLinkFound);

    NSString *text = RXRebrandText(cell.textLabel.text);
    if (text != nil) {
        cell.textLabel.text = text;
    }

    NSString *detail = RXRebrandText(cell.detailTextLabel.text);
    if (detail != nil) {
        cell.detailTextLabel.text = detail;
    }

    if (RXContainsDeveloperLinkToken(cell.textLabel.text) || RXContainsDeveloperLinkToken(cell.detailTextLabel.text)) {
        developerLinkFound = YES;
    }

    if (developerLinkFound) {
        RXDisableDeveloperCell(cell);
    } else {
        cell.contentView.hidden = NO;
    }
}

static BOOL RXShouldBlockURL(NSURL *url) {
    if (url == nil) {
        return NO;
    }

    NSString *host = url.host.lowercaseString ?: @"";
    NSArray<NSString *> *blockedHosts = @[
        @"t.me",
        @"telegram.me",
        @"telegram.org",
        @"github.com",
        @"www.github.com",
        @"x.com",
        @"www.x.com",
        @"twitter.com",
        @"www.twitter.com",
        @"buymeacoffee.com",
        @"www.buymeacoffee.com",
        @"boosty.to",
        @"www.boosty.to"
    ];

    for (NSString *blocked in blockedHosts) {
        if ([host isEqualToString:blocked] || [host hasSuffix:[@"." stringByAppendingString:blocked]]) {
            return YES;
        }
    }

    return NO;
}

static void RXPatchController(UIViewController *controller) {
    if (controller == nil) {
        return;
    }

    controller.title = RXRebrandText(controller.title);
    controller.navigationItem.title = RXRebrandText(controller.navigationItem.title);
    BOOL foundDeveloperLink = NO;
    RXPatchViewTree(controller.view, &foundDeveloperLink);
}

%hook NSBundle

- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {
    NSString *localized = %orig;
    NSString *bundlePath = self.bundlePath.lowercaseString ?: @"";
    if (![bundlePath containsString:@"bhtiktok.bundle"] && ![bundlePath containsString:@"bhtiktokpp.bundle"]) {
        return localized;
    }

    NSString *lowerKey = key.lowercaseString ?: @"";
    if ([lowerKey containsString:@"developer_"] ||
        [lowerKey isEqualToString:@"developer"] ||
        [lowerKey containsString:@"telegram"] ||
        [lowerKey containsString:@"github"] ||
        [lowerKey containsString:@"x page"] ||
        [lowerKey containsString:@"boosty"] ||
        [lowerKey containsString:@"coffee"] ||
        [lowerKey containsString:@"donate"] ||
        [lowerKey containsString:@"support"]) {
        return @"";
    }

    return RXRebrandText(localized);
}

%end

%hook UILabel

- (void)setText:(NSString *)text {
    NSString *patched = RXRebrandText(text);
    BOOL isDeveloperLinkText = RXContainsDeveloperLinkToken(text) || RXContainsDeveloperLinkToken(patched);
    if (isDeveloperLinkText) {
        patched = @"";
    }
    %orig(patched);
    if (isDeveloperLinkText) {
        self.hidden = YES;
        RXDisableDeveloperCell(RXFindParentCellForView(self));
    }
}

%end

%hook UIButton

- (void)setTitle:(NSString *)title forState:(UIControlState)state {
    NSString *patched = RXRebrandText(title);
    BOOL isDeveloperLinkText = RXContainsDeveloperLinkToken(title) || RXContainsDeveloperLinkToken(patched);
    if (isDeveloperLinkText) {
        patched = @"";
    }
    %orig(patched, state);
    if (isDeveloperLinkText) {
        self.hidden = YES;
        self.enabled = NO;
        self.userInteractionEnabled = NO;
        RXDisableDeveloperCell(RXFindParentCellForView(self));
    }
}

%end

%hook UINavigationItem

- (void)setTitle:(NSString *)title {
    %orig(RXRebrandText(title));
}

%end

%hook UITableViewCell

- (void)layoutSubviews {
    %orig;
    RXPatchCell(self);
}

%end

%hook SettingsController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    RXPatchController((UIViewController *)self);
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    RXPatchController((UIViewController *)self);
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    %orig;
    RXPatchCell(cell);
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    %orig;
    BOOL foundDeveloperLink = NO;
    RXPatchViewTree(view, &foundDeveloperLink);
    if (foundDeveloperLink) {
        view.hidden = YES;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    %orig;
    BOOL foundDeveloperLink = NO;
    RXPatchViewTree(view, &foundDeveloperLink);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell != nil) {
        BOOL foundDeveloperLink = NO;
        RXPatchViewTree(cell.contentView, &foundDeveloperLink);
        if (foundDeveloperLink) {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            return;
        }
    }
    %orig;
}

%end

%hook ViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    RXPatchController((UIViewController *)self);
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    RXPatchController((UIViewController *)self);
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    %orig;
    RXPatchCell(cell);
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    %orig;
    BOOL foundDeveloperLink = NO;
    RXPatchViewTree(view, &foundDeveloperLink);
    if (foundDeveloperLink) {
        view.hidden = YES;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell != nil) {
        BOOL foundDeveloperLink = NO;
        RXPatchViewTree(cell.contentView, &foundDeveloperLink);
        if (foundDeveloperLink) {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            return;
        }
    }
    %orig;
}

- (void)handleDeveloperSectionSelectionForRow:(NSInteger)row {
    return;
}

- (void)openTelegramChannel {
    return;
}

%end

%hook UIApplication

- (BOOL)openURL:(NSURL *)url {
    if (RXShouldBlockURL(url)) {
        return NO;
    }
    return %orig;
}

- (void)openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey, id> *)options completionHandler:(void (^)(BOOL success))completion {
    if (RXShouldBlockURL(url)) {
        if (completion != nil) {
            completion(NO);
        }
        return;
    }
    %orig;
}

%end
