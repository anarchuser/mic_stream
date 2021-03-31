#import "MicStreamPlugin.h"
#import <mic_stream/mic_stream-Swift.h>

@implementation MicStreamPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMicStreamPlugin registerWithRegistrar:registrar];
}
@end
