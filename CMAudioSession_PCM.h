//
//  CMAudioSession_PCM.h
//  Player_PCM
//
//  Created by ColdMountain on 2020/11/24.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

typedef enum {
    CMAudioSampleRate_Defalut = 8000,
    CMAudioSampleRate_22050Hz = 22050,
    CMAudioSampleRate_24000Hz = 24000,
    CMAudioSampleRate_32000Hz = 32000,
    CMAudioSampleRate_44100Hz = 44100,
} CMAudioSampleRate;

@protocol CMAudioSessionPCMDelegate <NSObject>

@optional

- (void)cm_audioUnitBackPCM:(NSData*)audioData;

@end

@interface CMAudioSession_PCM : NSObject
- (instancetype)initAudioUnitWithSampleRate:(CMAudioSampleRate)audioRate;
- (void)setOutputAudioPort:(AVAudioSessionPortOverride)audioSessionPortOverride;
- (void)cm_startAudioUnitRecorder;
- (void)cm_stopAudioUnitRecorder;

@property (nonatomic, weak) id<CMAudioSessionPCMDelegate>delegate;
@property (nonatomic, assign) CMAudioSampleRate audioRate;
@property (nonatomic, assign) NSInteger nsLevel;
@end

