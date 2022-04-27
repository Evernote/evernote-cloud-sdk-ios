//
//  AppDelegate.m
//  EvernoteSDKSample
//
//  Created by Dylan Marriott on 12/01/17.
//  Copyright © 2017 Evernote. All rights reserved.
//

#import "AppDelegate.h"
#import <EvernoteSDK/EvernoteSDK.h>
#import "MainViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#warning Add Consumer Key and Consumer Secret, but also modify your app's Info.plist according to documentation!
#warning Remove these warnings once done with it.

    
  // Set shared session key information.
  [ENSession setSharedSessionConsumerKey:@"your_consumer_key"
                          consumerSecret:@"your_consumer_secret"
                            optionalHost:ENSessionHostSandbox];

  // Override point for customization after application launch.
  self.window = [[UIWindow alloc] initWithFrame:
                 [[UIScreen mainScreen] bounds]];

  UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[MainViewController alloc] init]];
  self.window.rootViewController = navController;
  [self.window makeKeyAndVisible];

  return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options
{
  return [[ENSession sharedSession] handleOpenURL:url];
}

@end
