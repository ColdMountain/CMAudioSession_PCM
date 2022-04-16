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
    CMAudioPCMSampleRate_Defalut = 8000,
    CMAudioPCMSampleRate_22050Hz = 22050,
    CMAudioPCMSampleRate_24000Hz = 24000,
    CMAudioPCMSampleRate_32000Hz = 32000,
    CMAudioPCMSampleRate_44100Hz = 44100,
} CMAudioPCMSampleRate;

@protocol CMAudioSessionPCMDelegate <NSObject>

@optional

- (void)cm_audioUnitBackPCM:(NSData*)audioData;

@end

@interface CMAudioSession_PCM : NSObject
- (instancetype)initAudioUnitWithSampleRate:(CMAudioPCMSampleRate)audioRate;
- (void)setOutputAudioPort:(AVAudioSessionPortOverride)audioSessionPortOverride;
- (void)cm_startAudioUnitRecorder;
- (void)cm_stopAudioUnitRecorder;
- (void)cm_closeAudioUnitRecorder;

@property (nonatomic, weak) id<CMAudioSessionPCMDelegate>delegate;
@property (nonatomic, assign) CMAudioPCMSampleRate audioRate;
@property (nonatomic, assign) NSInteger nsLevel;
@end

