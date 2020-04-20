#import <Flutter/Flutter.h>

@interface JmlinkFlutterPlugin : NSObject<FlutterPlugin>


@property FlutterMethodChannel *methodChannel;

@property(nonatomic, assign) BOOL isSetup;
@property(nonatomic, assign) BOOL isRegisterHandler;
@property(nonatomic, assign) BOOL isRegisterDefaultHandler;
@property(nonatomic, strong) NSURL *cacheOpenUrl;
@property(nonatomic, strong) NSUserActivity *cacheUserActivity;

@end
