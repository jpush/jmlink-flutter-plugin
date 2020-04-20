#import "JmlinkFlutterPlugin.h"
// 如果需要使用 idfa 功能所需要引入的头文件（可选）
#import <AdSupport/AdSupport.h>
#import "JMLinkService.h"


#define JMLog(fmt, ...) NSLog((@"| JML | iOS | - " fmt), ##__VA_ARGS__)

static NSString *jmlink_handler_key  = @"jmlink_handler_key";
static NSString *jmlink_getParam_key = @"jmlink_getParam_key";

@implementation JmlinkFlutterPlugin

- (void)dealloc {
    
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"com.jiguang.jmlink_flutter_plugin" binaryMessenger:[registrar messenger]];
    JmlinkFlutterPlugin* instance = [[JmlinkFlutterPlugin alloc] init];
    instance.methodChannel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addApplicationDelegate:instance];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    JMLog(@"handleMethodCall: method = %@",call.method);
    NSString *method = call.method;
    if ([method isEqualToString:@"setup"]) {
        [self setup:call result:result];
    }else if ([method isEqualToString:@"setDebugMode"]) {
        [self setDebugMode:call result:result];
    }else if ([method isEqualToString:@"registerJMLinkDefaultHandler"]) {
        [self registerMLinkDefaultHandler:call result:result];
    }else if ([method isEqualToString:@"registerJMLinkHandler"]) {
        [self registerMLinkHandler:call result:result];
    }else if ([method isEqualToString:@"getJMLinkParam"]) {
        [self getMLinkParam:call result:result];
    }else{
        result(FlutterMethodNotImplemented);
    }
}

- (void)setup:(FlutterMethodCall *)call result:(FlutterResult)result {
    JMLog(@"setup: %@",call.arguments);
    
    NSDictionary *arguments = [call arguments];
    NSString *appKey = arguments[@"appKey"];
    NSString *channel = arguments[@"channel"];
    NSNumber *useIDFA = arguments[@"useIDFA"];
    NSNumber *isProduction = arguments[@"isProduction"];
    
    JMLinkConfig *config = [[JMLinkConfig alloc] init];
    if (![appKey isKindOfClass:[NSNull class]]) {
        config.appKey = appKey;
    }
    config.appKey =appKey;
    if (![channel isKindOfClass:[NSNull class]]) {
        config.channel = channel;
    }
    NSString *idfaStr = NULL;
    if(![useIDFA isKindOfClass:[NSNull class]]){
        if([useIDFA boolValue]){
            idfaStr = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
            config.advertisingId = idfaStr;
        }
    }
    config.isProduction = (BOOL)isProduction;
    [JMLinkService setupWithConfig:config];
    
    self.isSetup = YES;
    [self scheduleCache];
}

- (void)setDebugMode:(FlutterMethodCall *)call result:(FlutterResult)result {
    JMLog(@"setDebugMode: %@",call.arguments);
    
    NSDictionary *arguments = call.arguments;
    NSNumber *debug = arguments[@"debug"];
    [JMLinkService setDebug:(BOOL)debug];
}

- (void)registerMLinkHandler:(FlutterMethodCall *)call result:(FlutterResult)result {
    JMLog(@"registerMLinkHandler: %@",call.arguments);
    
    NSString *jmlink_key = [call.arguments objectForKey:jmlink_handler_key];
    if (!jmlink_key || jmlink_key.length <= 0) {
        JMLog(@"mlink key is can not be nil.");
    }
    self.isRegisterHandler = YES;
    __weak typeof(self)weakself = self;
    [JMLinkService registerMLinkHandlerWithKey:jmlink_key handler:^(NSURL * _Nonnull url, NSDictionary * _Nullable params) {
        JMLog(@"registerMLinkHandlerWithKey callback: %@",params);
        
        __strong typeof(weakself)strongself = weakself;
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:params];
        [dic setValue:jmlink_key forKey:jmlink_handler_key];
        
        result(dic);
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongself.methodChannel invokeMethod:@"onReceiveJMLinkHandler" arguments:dic];
        });
    }];
    
    double time = self.isRegisterDefaultHandler?0:0.3;
    [self performSelector:@selector(scheduleCache) withObject:nil afterDelay:time];
}

- (void)registerMLinkDefaultHandler:(FlutterMethodCall *)call result:(FlutterResult)result {
    JMLog(@"registerMLinkDefaultHandler: %@",call.arguments);
    
    self.isRegisterDefaultHandler = YES;
    __weak typeof(self)weakself = self;
    [JMLinkService registerMLinkDefaultHandler:^(NSURL * _Nonnull url, NSDictionary * _Nullable params) {
        JMLog(@"registerMLinkDefaultHandler callback: %@",params);
        __strong typeof(weakself)strongself = weakself;
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongself.methodChannel invokeMethod:@"onReceiveJMLinkDefaultHandler" arguments:params];
        });
    }];
    double time = self.isRegisterHandler?0:0.3;
    [self performSelector:@selector(scheduleCache) withObject:nil afterDelay:time];
}

- (void)getMLinkParam:(FlutterMethodCall *)call result:(FlutterResult)result {
    JMLog(@"getMLinkParam: %@",call.arguments);
    
    NSString *paramKey = @"";//SDK 的这个参数没用，所以直接传空
    [JMLinkService getMLinkParam:paramKey handler:^(NSDictionary * _Nullable params) {
        JMLog(@"getMLinkParam callback: %@",params);
        dispatch_async(dispatch_get_main_queue(), ^{
            result(params);
        });
    }];
}

- (void)scheduleCache {
    if (self.isSetup) {
        if (!self.isRegisterHandler && !self.isRegisterDefaultHandler) {
            return;
        }
        if (self.cacheOpenUrl) {
            JMLog(@"scheduleCache - routeMLink");
            [JMLinkService routeMLink:self.cacheOpenUrl];
            self.cacheOpenUrl = nil;
        }
        if (self.cacheUserActivity) {
            JMLog(@"scheduleCache - continueUserActivity");
            [JMLinkService continueUserActivity:self.cacheUserActivity];
            self.cacheUserActivity = nil;
        }
    }
}

#pragma mark - Application Delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    JMLog(@"application:handleOpenURL:");
    if (self.isSetup) {
        return [JMLinkService routeMLink:url];
    }else{
        self.cacheOpenUrl = url;
        return YES;
    }
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(nonnull void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    JMLog(@"application:continueUserActivity:");
    if (self.isSetup) {
        return [JMLinkService continueUserActivity:userActivity];
    }else{
        self.cacheUserActivity = userActivity;
        return YES;
    }
}

@end
