//
//  RNEZAudio.h
//  blank
//
//  Created by SEED on 10/02/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "RCTBridgeModule.h"
#include <EZAudio/EZAudio.h>

#define kAudioFilePath @"test.m4a"

@interface RNEZAudio : NSObject <RCTBridgeModule, EZAudioPlayerDelegate, EZMicrophoneDelegate, EZRecorderDelegate>

@property (nonatomic, strong) EZAudioPlayer *player;
@property (nonatomic, strong) EZMicrophone *microphone;
@property (nonatomic, strong) EZRecorder *recorder;


- (void) testBridgeConnection;
- (void) initAudioEngine;
- (void) startRecording;
- (void) stopRecording;

@end
