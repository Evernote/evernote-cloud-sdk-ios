//
//  AppDelegate.m
//  EvernoteSDKSample
//
//  Created by Ben Zotto on 4/24/14.
//  Copyright (c) 2014 n/a. All rights reserved.
//

#import "AppDelegate.h"
#import <ENSDK/ENSDK.h>
#import "MainViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#warning Add Consumer Key and Consumer Secret, but also modify your app's Info.plist according to documentation!
#warning Remove these warnings once done with it.

    // Set shared session key information.
    [ENSession setSharedSessionConsumerKey:@"your key"
                            consumerSecret:@"your secret"
                              optionalHost:ENSessionHostSandbox];
    
    
    // OPTION: Set personal, production account by commenting out sandbox service and uncomenting below code for production test.You can obtain DeveloperToken at https://www.evernote.com/api/DeveloperToken.action

//   [ENSession setSharedSessionDeveloperToken:@""
//                                noteStoreUrl:@""];

    
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:
                   [[UIScreen mainScreen] bounds]];

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[MainViewController alloc] init]];
    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [[ENSession sharedSession] handleOpenURL:url];
}

@end
