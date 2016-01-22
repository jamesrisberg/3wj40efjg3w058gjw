//
//  AppDelegate.m
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "AppDelegate.h"
#import "EditorViewController.h"
#import "FilePickerViewController.h"
#import "ExportTest.h"
#import <Parse.h>
#import "FilterPickerViewController.h"
#import "CMWindow.h"
#import "UIFont+Theming.h"

@interface AppDelegate () {
    NSInteger _activityIndicatorCount;
    UIWindow *_window;
}

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [self applyTheming];
    
    [Parse setApplicationId:@"HOKpgx4PlskFPZkAvtBxk1OnpIAWQlJpdNuGUo1w"
                  clientKey:@"AKgMJl0JTZ32BGgVmgGL5h19ia0NBBeMEYc2q1oi"];
    
    srand(time(0));
    return YES;
}



- (FilePickerViewController *)filePicker {
    UINavigationController *nav = (id)self.window.rootViewController;
    return (FilePickerViewController *)nav.viewControllers.firstObject;
}

- (void)applyTheming {
    self.window.tintColor = [UIColor colorWithRed:1.0 green:0.169590711594 blue:0.42642134428 alpha:1.0];
    UILabel *defaultLabel = [UILabel new];
    [[UILabel appearance] setFont:[UIFont systemFontOfSize:defaultLabel.font.pointSize]];
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    [[self filePicker] addDocument:nil];
    completionHandler(YES);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)incrementNetworkActivityIndicator:(NSInteger)i {
    _activityIndicatorCount += i;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:_activityIndicatorCount > 0];
}

#pragma mark Custom UIWindow

- (UIWindow *)window {
    if (!_window) {
        _window = [[CMWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _window.windowLevel = UIWindowLevelNormal;
    }
    return _window;
}

- (void)setWindow:(UIWindow *)window {
    // DO NOTHING (???)
}

@end
