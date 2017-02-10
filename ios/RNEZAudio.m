//
//  RNEZAudio.m
//  blank
//
//  Created by SEED on 10/02/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "RNEZAudio.h"

@implementation RNEZAudio

@synthesize player = _player;
@synthesize microphone = _microphone;
@synthesize recorder = _recorder;

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(testBridgeConnection) {
  NSLog(@"Logged in object C from JAVASCRIPT");
}

RCT_EXPORT_METHOD(initAudioEngine) {
  
  // Create the Audio Session that will handle the playing and recording of data
  AVAudioSession *session = [AVAudioSession sharedInstance];
  NSError *error;
  
  // Set the Category and see catch any errors
  [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
  if (error) {
    NSLog(@"Error setting up audio session category: %@", error.localizedDescription);
  }
  
  // Set the Audio Session to Active and catch and errors
  [session setActive:YES error:&error];
  if (error) {
    NSLog(@"Error setting up audio session active: %@", error.localizedDescription);
  }
  
  _microphone = [EZMicrophone microphoneWithDelegate:self];
  _player = [EZAudioPlayer audioPlayerWithDelegate:self];
  
  [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
  {
    NSLog(@"Error overriding output to the speaker: %@", error.localizedDescription);
  }
  
  
  [self setupNotifications];
  
  NSLog(@"File written to application sandbox's documents directory: %@", [self testFilePathURL]);
  
}

RCT_EXPORT_METHOD(startRecording) {
  
  [_microphone startFetchingAudio];
  _recorder = [EZRecorder recorderWithURL:[self testFilePathURL]
                                 clientFormat:[_microphone audioStreamBasicDescription]
                                     fileType:EZRecorderFileTypeM4A
                                     delegate:self];
  
}

RCT_EXPORT_METHOD(stopRecording) {
  
  [_microphone stopFetchingAudio];
  
  if (_recorder) {
    [_recorder closeAudioFile];
  }
  
}

- (void)setupNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(playerDidChangePlayState:)
                                               name:EZAudioPlayerDidChangePlayStateNotification
                                             object:self.player];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(playerDidReachEndOfFile:)
                                               name:EZAudioPlayerDidReachEndOfFileNotification
                                             object:self.player];
}

- (void)playerDidChangePlayState:(NSNotification *)notification
{
  __weak typeof (self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    EZAudioPlayer *player = [notification object];
    BOOL isPlaying = [player isPlaying];
    if (isPlaying)
    {
      weakSelf.recorder.delegate = nil;
    }
  });
}

- (void)playerDidReachEndOfFile:(NSNotification *)notification
{
  __weak typeof (self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    
    //[weakSelf.playingAudioPlot clear];
    
  });
}

//------------------------------------------------------------------------------
#pragma mark - EZMicrophoneDelegate
//------------------------------------------------------------------------------

#warning Thread Safety


// This function handles the raw audio data for duoing our funky visualisations!
- (void)   microphone:(EZMicrophone *)microphone
     hasAudioReceived:(float **)buffer
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels
{

  __weak typeof (self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    //
    // All the audio plot needs is the buffer data (float*) and the size.
    // Internally the audio plot will handle all the drawing related code,
    // history management, and freeing its own resources. Hence, one badass
    // line of code gets you a pretty plot :)
    //
//    [weakSelf.recordingAudioPlot updateBuffer:buffer[0]
//                               withBufferSize:bufferSize];
    
    // Get the current volume size in decibles to do some fun stuff with!
    float decibels = [self getDecibelsFromVolume:buffer withBufferSize:bufferSize];
    NSLog(@"Decibels: %f", decibels);
    
  });
}

// This fucntion handles actually recording our data...
- (void)   microphone:(EZMicrophone *)microphone
        hasBufferList:(AudioBufferList *)bufferList
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels
{
  //
  // Getting audio data as a buffer list that can be directly fed into the
  // EZRecorder. This is happening on the audio thread - any UI updating needs
  // a GCD main queue block. This will keep appending data to the tail of the
  // audio file.
  //
  [_recorder appendDataFromBufferList:bufferList
                          withBufferSize:bufferSize];
}


//------------------------------------------------------------------------------
#pragma mark - Utility
//------------------------------------------------------------------------------

- (float)getDecibelsFromVolume:(float**)buffer withBufferSize:(UInt32)bufferSize {
  
  // Decibel Calculation.
  
  float one = 1.0;
  float meanVal = 0.0;
  
  vDSP_vsq(buffer[0], 1, buffer[0], 1, bufferSize);
  vDSP_meanv(buffer[0], 1, &meanVal, bufferSize);
  vDSP_vdbcon(&meanVal, 1, &one, &meanVal, 1, 1, 0);
  
  return meanVal;
}

- (NSArray *)applicationDocuments
{
  return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
}

- (NSString *)applicationDocumentsDirectory
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
  return basePath;
}

- (NSURL *)testFilePathURL
{
  return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",
                                 [self applicationDocumentsDirectory],
                                 kAudioFilePath]];
}


@end
