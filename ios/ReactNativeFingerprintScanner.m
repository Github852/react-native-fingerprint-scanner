#import "ReactNativeFingerprintScanner.h"

#if __has_include(<React/RCTUtils.h>) // React Native >= 0.40
#import <React/RCTUtils.h>
#else // React Native < 0.40
#import "RCTUtils.h"
#endif

#import <LocalAuthentication/LocalAuthentication.h>

@implementation ReactNativeFingerprintScanner

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(isSensorAvailable: (RCTResponseSenderBlock)callback)
{
    LAContext *context = [[LAContext alloc] init];
    NSError *error;

    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        callback(@[[NSNull null], @true]);
    } else {
        // Device does not support FingerprintScanner
        callback(@[RCTMakeError(@"FingerprintScannerNotSupported", nil, nil)]);
        return;
    }
}

RCT_EXPORT_METHOD(authenticate: (NSString *)reason
                  fallback: (BOOL)fallbackEnabled
                  callback: (RCTResponseSenderBlock)callback)
{
    LAContext *context = [[LAContext alloc] init];
    NSError *error;

    // Toggle fallback button
    if (!fallbackEnabled) {
        context.localizedFallbackTitle = @"";
    }

    // Device has FingerprintScanner
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        // Attempt Authentication
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                localizedReason:reason
                          reply:^(BOOL success, NSError *error)
         {
             // Failed Authentication
             if (error) {
                 NSString *errorReason;

                 switch (error.code) {
                     case LAErrorAuthenticationFailed:
                         errorReason = @"AuthenticationFailed";
                         break;

                     case LAErrorUserCancel:
                         errorReason = @"UserCancel";
                         break;

                     case LAErrorUserFallback:
                         errorReason = @"UserFallback";
                         break;

                     case LAErrorSystemCancel:
                         errorReason = @"SystemCancel";
                         break;

                     case LAErrorPasscodeNotSet:
                         errorReason = @"PasscodeNotSet";
                         break;

                     case LAErrorTouchIDNotAvailable:
                         errorReason = @"FingerprintScannerNotAvailable";
                         break;

                     case LAErrorTouchIDNotEnrolled:
                         errorReason = @"FingerprintScannerNotEnrolled";
                         break;

                     default:
                         errorReason = @"FingerprintScannerUnknownError";
                         break;
                 }
                 
                 
                 // Try again
                 [self authenticate:reason fallback:fallbackEnabled callback:callback];
                 
                 return;
             }

             // Authenticated Successfully
             callback(@[[NSNull null], @"Authenticated with Fingerprint Scanner."]);
         }];

    } else {
        // This clause is reached if the user has attempted an invalid fingerprint too many times,
        // or if Touch ID is not enabled
        
        LAContext *context = [[LAContext alloc] init];
        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:reason reply:^(BOOL success, NSError * _Nullable error) {
                if(error) {
                    NSString *errorReason = @"AuthenticationFailed";
                    NSLog(@"Authentication failed: %@", errorReason);
                    callback(@[RCTMakeError(errorReason, nil, nil)]);
                } else {
                    callback(@[[NSNull null], @"Authenticated with Fingerprint Scanner."]);
                }
            }];
        } else {
            NSString *errorReason = @"AuthenticationFailed";
            NSLog(@"Authentication failed: %@", errorReason);
            callback(@[RCTMakeError(errorReason, nil, nil)]);
        }
        
        
    }
}

@end
