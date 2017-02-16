//
//  RNEZAudio.h
//  blank
//
//  Created by SEED on 10/02/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "RCTBridgeModule.h"
#import "RCTEventDispatcher.h"
#include <EZAudio/EZAudio.h>

@interface RNEZAudio : NSObject <RCTBridgeModule, EZAudioPlayerDelegate, EZMicrophoneDelegate, EZRecorderDelegate, EZAudioFFTDelegate, EZOutputDelegate>

@property (nonatomic, strong) EZAudioPlayer *player;
@property (nonatomic, strong) EZMicrophone *microphone;
@property (nonatomic, strong) EZRecorder *recorder;
@property (nonatomic, strong) EZAudioFFT *fft;
@property (nonatomic, strong) EZAudioFile *audioFile;
@property (nonatomic, strong) NSMutableArray *fftDataArray;


- (void) testBridgeConnection;
- (void) initAudioEngine;
- (void) startRecording:(NSString *)subDirectory: (NSString *)filename;
- (void) stopRecording;
- (void) playbackFile:(NSString *)filePath;
- (void) stopPlayback;
@end

