#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/runtime.h>

static BOOL RXCleanerRunning = NO;
static __weak UIViewController *RXCleanerHostController = nil;
static NSTimer *RXCleanerTimer = nil;
static char RXCleanerButtonAssociationKey;

__attribute__((constructor))
static void RXLoadOriginalBHTikTokCore(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundlePath = [NSBundle mainBundle].bundlePath ?: @"";
        NSString *corePath = [bundlePath stringByAppendingPathComponent:@"Frameworks/BHTikTokCore.dylib"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:corePath]) {
            dlopen(corePath.UTF8String, RTLD_NOW | RTLD_GLOBAL);
        }
    });
}

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

static NSArray<NSString *> *RXFollowStateTokens(void) {
    static NSArray<NSString *> *tokens;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tokens = @[
            @"takip ediliyor",
            @"following"
        ];
    });
    return tokens;
}

static NSArray<NSString *> *RXUnfollowConfirmTokens(void) {
    static NSArray<NSString *> *tokens;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tokens = @[
            @"takibi bırak",
            @"takibi birak",
            @"takipten çık",
            @"takipten cik",
            @"unfollow"
        ];
    });
    return tokens;
}

static BOOL RXTextContainsAnyToken(NSString *text, NSArray<NSString *> *tokens) {
    if (text.length == 0) {
        return NO;
    }
    NSString *lower = text.lowercaseString;
    for (NSString *token in tokens) {
        if ([lower containsString:token]) {
            return YES;
        }
    }
    return NO;
}

static void RXCollectViewsRecursively(UIView *root, NSMutableArray<UIView *> *outViews) {
    if (root == nil) {
        return;
    }
    [outViews addObject:root];
    for (UIView *subview in root.subviews) {
        RXCollectViewsRecursively(subview, outViews);
    }
}

static NSString *RXButtonTitle(UIButton *button) {
    if (button == nil) {
        return @"";
    }
    NSString *title = button.currentTitle;
    if (title.length == 0) {
        title = [button titleForState:UIControlStateNormal];
    }
    if (title.length == 0) {
        title = button.titleLabel.text;
    }
    return title ?: @"";
}

static BOOL RXButtonIsVisibleAndTouchable(UIButton *button) {
    if (button == nil || button.hidden || button.alpha < 0.05 || !button.userInteractionEnabled || !button.enabled || button.window == nil) {
        return NO;
    }
    CGRect rect = [button convertRect:button.bounds toView:nil];
    if (CGRectIsEmpty(rect) || CGRectIsNull(rect)) {
        return NO;
    }
    return CGRectIntersectsRect(rect, [UIScreen mainScreen].bounds);
}

static BOOL RXTapFirstButtonMatchingTokensInView(UIView *root, NSArray<NSString *> *tokens) {
    if (root == nil) {
        return NO;
    }

    NSMutableArray<UIView *> *views = [NSMutableArray array];
    RXCollectViewsRecursively(root, views);
    for (UIView *view in views) {
        if (![view isKindOfClass:[UIButton class]]) {
            continue;
        }
        UIButton *button = (UIButton *)view;
        if (!RXButtonIsVisibleAndTouchable(button)) {
            continue;
        }
        if (RXTextContainsAnyToken(RXButtonTitle(button), tokens)) {
            [button sendActionsForControlEvents:UIControlEventTouchUpInside];
            return YES;
        }
    }
    return NO;
}

static BOOL RXHasButtonMatchingTokensInView(UIView *root, NSArray<NSString *> *tokens) {
    if (root == nil) {
        return NO;
    }

    NSMutableArray<UIView *> *views = [NSMutableArray array];
    RXCollectViewsRecursively(root, views);
    for (UIView *view in views) {
        if (![view isKindOfClass:[UIButton class]]) {
            continue;
        }
        UIButton *button = (UIButton *)view;
        if (!RXButtonIsVisibleAndTouchable(button)) {
            continue;
        }
        if (RXTextContainsAnyToken(RXButtonTitle(button), tokens)) {
            return YES;
        }
    }
    return NO;
}

static UIScrollView *RXFindLargestScrollableView(UIView *root) {
    if (root == nil) {
        return nil;
    }
    NSMutableArray<UIView *> *views = [NSMutableArray array];
    RXCollectViewsRecursively(root, views);

    UIScrollView *best = nil;
    CGFloat bestScore = 0.0;
    for (UIView *view in views) {
        if (![view isKindOfClass:[UIScrollView class]]) {
            continue;
        }
        UIScrollView *scrollView = (UIScrollView *)view;
        if (!scrollView.scrollEnabled || scrollView.hidden || scrollView.alpha < 0.05 || scrollView.window == nil) {
            continue;
        }
        CGFloat extra = scrollView.contentSize.height - scrollView.bounds.size.height;
        if (extra <= 30.0) {
            continue;
        }
        if (extra > bestScore) {
            best = scrollView;
            bestScore = extra;
        }
    }
    return best;
}

static UIWindow *RXActiveWindow(void) {
    NSSet<UIScene *> *scenes = UIApplication.sharedApplication.connectedScenes;
    for (UIScene *scene in scenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }
        if (scene.activationState != UISceneActivationStateForegroundActive) {
            continue;
        }
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) {
                return window;
            }
        }
        if (windowScene.windows.count > 0) {
            return windowScene.windows.firstObject;
        }
    }
    return nil;
}

static BOOL RXLooksLikeFollowingScreen(UIViewController *controller) {
    if (controller == nil || controller.view == nil || controller.navigationController == nil) {
        return NO;
    }
    if (RXHasButtonMatchingTokensInView(controller.view, RXFollowStateTokens())) {
        return YES;
    }
    NSString *titleBlob = [NSString stringWithFormat:@"%@ %@", controller.title ?: @"", controller.navigationItem.title ?: @""];
    return RXTextContainsAnyToken(titleBlob, @[@"following", @"takip"]);
}

static UIBarButtonItem *RXCleanerButtonForController(UIViewController *controller) {
    UIBarButtonItem *item = objc_getAssociatedObject(controller, &RXCleanerButtonAssociationKey);
    if (item == nil) {
        item = [[UIBarButtonItem alloc] initWithTitle:@"Temizle"
                                                style:UIBarButtonItemStylePlain
                                               target:controller
                                               action:@selector(rx_toggleFollowCleaner)];
        objc_setAssociatedObject(controller, &RXCleanerButtonAssociationKey, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return item;
}

static void RXSetCleanerButtonState(UIViewController *controller, BOOL running) {
    UIBarButtonItem *item = objc_getAssociatedObject(controller, &RXCleanerButtonAssociationKey);
    if (item != nil) {
        item.title = running ? @"Dur" : @"Temizle";
    }
}

static void RXEnsureCleanerButtonVisible(UIViewController *controller) {
    if (!RXLooksLikeFollowingScreen(controller)) {
        return;
    }
    UIBarButtonItem *item = RXCleanerButtonForController(controller);
    item.title = (RXCleanerRunning && RXCleanerHostController == controller) ? @"Dur" : @"Temizle";

    if (controller.navigationItem.rightBarButtonItem == item) {
        return;
    }

    NSMutableArray<UIBarButtonItem *> *items = [NSMutableArray array];
    if (controller.navigationItem.rightBarButtonItems.count > 0) {
        [items addObjectsFromArray:controller.navigationItem.rightBarButtonItems];
    } else if (controller.navigationItem.rightBarButtonItem != nil) {
        [items addObject:controller.navigationItem.rightBarButtonItem];
    }

    BOOL exists = NO;
    for (UIBarButtonItem *existingItem in items) {
        if (existingItem == item) {
            exists = YES;
            break;
        }
    }
    if (!exists) {
        [items addObject:item];
    }
    controller.navigationItem.rightBarButtonItems = items;
}

static void RXStopFollowCleaner(void) {
    RXCleanerRunning = NO;
    if (RXCleanerTimer != nil) {
        [RXCleanerTimer invalidate];
        RXCleanerTimer = nil;
    }
    if (RXCleanerHostController != nil) {
        RXSetCleanerButtonState(RXCleanerHostController, NO);
    }
    RXCleanerHostController = nil;
}

static void RXFollowCleanerStep(void) {
    if (!RXCleanerRunning || RXCleanerHostController == nil) {
        return;
    }
    UIViewController *controller = RXCleanerHostController;
    if (controller.view.window == nil) {
        return;
    }

    UIWindow *window = RXActiveWindow();
    BOOL tapped = NO;
    if (window != nil) {
        tapped = RXTapFirstButtonMatchingTokensInView(window, RXUnfollowConfirmTokens());
    }
    if (!tapped) {
        tapped = RXTapFirstButtonMatchingTokensInView(controller.view, RXFollowStateTokens());
    }

    UIScrollView *scrollView = RXFindLargestScrollableView(controller.view);
    if (scrollView != nil) {
        CGFloat maxY = MAX(0.0, scrollView.contentSize.height - scrollView.bounds.size.height);
        if (maxY > 0.0) {
            CGFloat delta = MAX(110.0, scrollView.bounds.size.height * 0.45);
            CGFloat nextY = MIN(maxY, scrollView.contentOffset.y + delta);
            [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, nextY) animated:YES];
        }
    }
}

static void RXStartFollowCleaner(UIViewController *controller) {
    RXStopFollowCleaner();
    RXCleanerHostController = controller;
    RXCleanerRunning = YES;
    RXSetCleanerButtonState(controller, YES);

    RXCleanerTimer = [NSTimer scheduledTimerWithTimeInterval:0.75
                                                      repeats:YES
                                                        block:^(__unused NSTimer *timer) {
        RXFollowCleanerStep();
    }];
    [[NSRunLoop mainRunLoop] addTimer:RXCleanerTimer forMode:NSRunLoopCommonModes];
    RXFollowCleanerStep();
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

%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    RXEnsureCleanerButtonVisible(self);
}

- (void)viewDidLayoutSubviews {
    %orig;
    RXEnsureCleanerButtonVisible(self);
}

%new
- (void)rx_toggleFollowCleaner {
    RXEnsureCleanerButtonVisible(self);

    if (RXCleanerRunning && RXCleanerHostController == self) {
        RXStopFollowCleaner();
        return;
    }

    __weak UIViewController *weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Takip Temizle"
                                                                   message:@"Takipten çıkma işlemi başlatılsın mı?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"İptal"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Başlat"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(__unused UIAlertAction *action) {
        UIViewController *strongSelf = weakSelf;
        if (strongSelf != nil) {
            RXStartFollowCleaner(strongSelf);
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
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
