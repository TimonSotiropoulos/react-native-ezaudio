//
//  RNEZAudio.m
//  blank
//
//  Created by SEED on 10/02/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "RNEZAudio.h"

@implementation RNEZAudio

@synthesize bridge = _bridge;
@synthesize player = _player;
@synthesize microphone = _microphone;
@synthesize recorder = _recorder;
@synthesize fft = _fft;
@synthesize audioFile = _audioFile;
@synthesize fftDataArray = _fftDataArray;

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
  _fft = [EZAudioFFTRolling fftWithWindowSize:6 // This is the buffer length before it will provide a new FFT sample :O
                                   sampleRate:880 // This should be the MAX_FREQUENCY of the FFT sample :)
                                     delegate:self];
  
  _fftDataArray = [[NSMutableArray alloc] init];
  
  [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
  {
    NSLog(@"Error overriding output to the speaker: %@", error.localizedDescription);
  }
  
  
  [self setupNotifications];
  
}

//------------------------------------------------------------------------------
#pragma mark - React Native Audio Controller Functions
//------------------------------------------------------------------------------


RCT_EXPORT_METHOD(startRecording:(NSString *)subDirectory: (NSString *)filename) {
  
  [_microphone startFetchingAudio];
  _recorder = [EZRecorder recorderWithURL:[self createFilePathURL:subDirectory filename:filename]
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

RCT_EXPORT_METHOD(playbackFile:(NSString *)filePath) {
  
  NSArray *documentFolders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *fullPath = [documentFolders[0] stringByAppendingPathComponent:filePath];
  
//  NSArray *paths = NSSearchPathForDirectoriesInDomains('/', NSUserDomainMask, YES);
//  NSString *fullPath = [[paths firstObject] stringByAppendingString:filePath];
  
  _audioFile = [EZAudioFile audioFileWithURL:[NSURL URLWithString:fullPath]];
  [_player playAudioFile:_audioFile];
}

RCT_EXPORT_METHOD(stopPlayback) {
  [_player pause];
}


//------------------------------------------------------------------------------
#pragma mark - Notifications
//------------------------------------------------------------------------------

- (void)setupNotifications
{
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(audioPlayerDidChangeAudioFile:)
                                               name:EZAudioPlayerDidChangeAudioFileNotification
                                             object:self.player];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(playerDidChangePlayState:)
                                               name:EZAudioPlayerDidChangePlayStateNotification
                                             object:self.player];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(audioPlayerDidChangeOutputDevice:)
                                               name:EZAudioPlayerDidChangeOutputDeviceNotification
                                             object:self.player];
}

- (void)audioPlayerDidChangeAudioFile:(NSNotification *)notification
{
  EZAudioPlayer *player = [notification object];
  NSLog(@"Player changed audio file: %@", [player audioFile]);
}

- (void)playerDidChangePlayState:(NSNotification *)notification
{
  __weak typeof (self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    EZAudioPlayer *player = [notification object];
    NSLog(@"Player change play state, isPlaying: %i", [player isPlaying]);
    BOOL isPlaying = [player isPlaying];
    if (isPlaying)
    {
      weakSelf.recorder.delegate = nil;
    }
  });
}

- (void)audioPlayerDidChangeOutputDevice:(NSNotification *)notification
{
  EZAudioPlayer *player = [notification object];
  NSLog(@"Player changed output device: %@", [player device]);
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
  
  dispatch_async(dispatch_get_main_queue(), ^{
    
    // Get the current volume size in decibles to do some fun stuff with!
    float decibelsNorm = [self getDecibelsFromVolume:buffer withBufferSize:bufferSize];
    float roundVal = roundf(decibelsNorm * 100) / 100;
    [_bridge.eventDispatcher sendAppEventWithName:@"VolumeUpdate" body:@{ @"volumeData": [NSNumber numberWithFloat:roundVal]}];
    
    // FFT Handler Function
    [_fft computeFFTWithBuffer:buffer[0] withBufferSize:bufferSize];
    
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
#pragma mark - EZAudioPlayerDelegate
//------------------------------------------------------------------------------

- (void)  audioPlayer:(EZAudioPlayer *)audioPlayer
          playedAudio:(float **)buffer
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels
          inAudioFile:(EZAudioFile *)audioFile
{
  dispatch_async(dispatch_get_main_queue(), ^{
    float decibelsNorm = [self getDecibelsFromVolume:buffer withBufferSize:bufferSize];
    float roundVal = roundf(decibelsNorm * 100) / 100;
    [_bridge.eventDispatcher sendAppEventWithName:@"VolumeUpdate" body:@{ @"volumeData": [NSNumber numberWithFloat:roundVal]}];
    
    // FFT Handler Function
    [_fft computeFFTWithBuffer:buffer[0] withBufferSize:bufferSize];
  });
}

//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
#pragma mark - EZAudioFFTDelegate
//------------------------------------------------------------------------------

- (void)        fft:(EZAudioFFT *)fft
 updatedWithFFTData:(float *)fftData
         bufferSize:(vDSP_Length)bufferSize
{
  dispatch_async(dispatch_get_main_queue(), ^{
    
    [_fftDataArray removeAllObjects];
    
    int count = 0;
    for (count = 0; count < bufferSize; count++) {
      float normFreq = fftData[count] * 1000.0; // where 100 is the GAIN we want to apply to make our numbers more usable!
      float ratioedFreq = MAX(0, MIN(1, normFreq));
      float roundVal = roundf(ratioedFreq * 100) / 100;
      [_fftDataArray addObject:[NSNumber numberWithFloat:roundVal]];
    }
    
    [_bridge.eventDispatcher sendAppEventWithName:@"FFTUpdate" body:@{ @"fftData": _fftDataArray}];
    
  });
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
  
  // Normalise the mean value here
  float decibalVal = meanVal + 160;
  
  double const inMin = 100;
  double const inMax = 130;
  
  if (decibalVal < inMin) {
    decibalVal = inMin;
  } else if (decibalVal > inMax) {
    decibalVal = inMax;
  }
  
  double const outMax = 1.0;
  
  double returnValRatioed = (outMax * (decibalVal - inMin)) / (inMax - inMin);
  return returnValRatioed;
}

- (NSURL *)createFilePathURL:(NSString *)subDirectory filename:(NSString *)filename {
  
  NSLog(@"Starting");
  NSLog(@"Sub Directory: %@", subDirectory );
  NSLog(@"FileNAme: %@", filename );
  
  
  NSFileManager *localFileManager = [NSFileManager defaultManager];
  // Firstly we need to try and create the directory for to save the shout
  NSArray *documentFolders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentSubDirectory = [documentFolders[0] stringByAppendingPathComponent:subDirectory];
  
  
  
  // Create the subdirectory structure
  if (![localFileManager createDirectoryAtPath:documentSubDirectory withIntermediateDirectories:YES attributes:nil error:nil]) {
    NSLog(@"Error Creating Directory");
    return nil;
  }
  
  NSString *filePath =[documentSubDirectory stringByAppendingPathComponent:filename];
  
  NSLog(@"FIle Path: %@", filePath);
  
  // Add the filename to the end of the cache subdirectory now that the file location has been created
  return [NSURL fileURLWithPath:filePath];
  
}

//- (NSArray *)applicationDocuments
//{
//  return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//}
//
//- (NSString *)applicationDocumentsDirectory
//{
//  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//  NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
//  return basePath;
//}
//
//- (NSURL *)testFilePathURL
//{
//  return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",
//                                 [self applicationDocumentsDirectory],
//                                 kAudioFilePath]];
//}


@end
