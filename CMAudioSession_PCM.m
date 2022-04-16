//
//  CMAudioSession_PCM.m
//  Player_PCM
//
//  Created by ColdMountain on 2020/11/24.
//

#import "CMAudioSession_PCM.h"

#define INPUT_BUS 1
#define OUTPUT_BUS 0

@interface CMAudioSession_PCM()
{
    OSStatus status;
    AudioUnit audioUnit;
    AudioBufferList *buffList;
    AudioStreamBasicDescription  dataFormat;
    AVAudioPlayer *audioPlayer;
    AVAudioSession *audioSession;
}
@end

//int nsProcess(int16_t *buffer, uint32_t sampleRate ,int samplesCount, int level)
//{
//    if (buffer == 0) return -1;
//    if (samplesCount == 0) return -1;
//    size_t samples = MIN(160, sampleRate / 100);
//    if (samples == 0) return -1;
//    uint32_t num_bands = 1;
//    int16_t *input = buffer;
//    size_t nTotal = (samplesCount / samples);
//    NsHandle *nsHandle = WebRtcNs_Create();
//    int status = WebRtcNs_Init(nsHandle, sampleRate);
//    if (status != 0) {
//        printf("WebRtcNs_Init fail\n");
//        return -1;
//    }
//    status = WebRtcNs_set_policy(nsHandle, level);
//    if (status != 0) {
//        printf("WebRtcNs_set_policy fail\n");
//        return -1;
//    }
//    for (int i = 0; i < nTotal; i++) {
//        int16_t *nsIn[1] = {input};   //ns input[band][data]
//        int16_t *nsOut[1] = {input};  //ns output[band][data]
//        WebRtcNs_Analyze(nsHandle, nsIn[0]);
//        WebRtcNs_Process(nsHandle, (const int16_t *const *) nsIn, num_bands, nsOut);
//        input += samples;
//    }
//    WebRtcNs_Free(nsHandle);
//
//    return 1;
//}

@implementation CMAudioSession_PCM
- (instancetype)initAudioUnitWithSampleRate:(CMAudioPCMSampleRate)audioRate{
    self = [super init];
    if (self) {
        self.audioRate = audioRate;
        self.nsLevel = 0;
        [self relocationAudio];
        [self initAudioComponent];
    }
    return self;
}

- (void)relocationAudio{
    // /Applications/VLC.app/Contents/MacOS/VLC --demux=rawaud --rawaud-channels 1 --rawaud-samplerate 8000
    NSError* error;
    BOOL success;
    //设置成语音视频模式
    audioSession = [AVAudioSession sharedInstance];
    
    success = [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                            withOptions:AVAudioSessionCategoryOptionAllowBluetooth|
                                        AVAudioSessionCategoryOptionAllowBluetoothA2DP|
                                        AVAudioSessionCategoryOptionMixWithOthers|
                                        AVAudioSessionCategoryOptionDuckOthers
//                                        AVAudioSessionCategoryOptionDefaultToSpeaker
                                  error:nil];
    //设置I/O的buffer buffer越小延迟越低
    NSTimeInterval bufferDyration = 0.01;
    [audioSession setPreferredIOBufferDuration:bufferDyration error:&error];
//    [audioSession setPreferredSampleRate:8000 error:&error]; 此代码会让 AirPods 在录制音频的时候 失真
    
    //set USB AUDIO device as high priority: iRig mic HD
    for (AVAudioSessionPortDescription *inputPort in [audioSession availableInputs])
    {
        if([inputPort.portType isEqualToString:AVAudioSessionPortUSBAudio])
        {
            [audioSession setPreferredInput:inputPort error:&error];
            [audioSession setPreferredInputNumberOfChannels:1 error:&error];
            break;
        }
    }
    success = [audioSession setActive:YES error:nil];
}

- (void)setOutputAudioPort:(AVAudioSessionPortOverride)audioSessionPortOverride{
    AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription *portDesc in [currentRoute outputs])
    {
        NSLog(@"当前输出:%@==========%lu",portDesc.portType,(unsigned long)audioSessionPortOverride);
        if([portDesc.portType isEqualToString:AVAudioSessionPortBuiltInReceiver]){
            [audioSession overrideOutputAudioPort:audioSessionPortOverride error:nil];
            break;
        }else if ([portDesc.portType isEqualToString:AVAudioSessionPortBuiltInSpeaker]){
            [audioSession overrideOutputAudioPort:audioSessionPortOverride error:nil];
            break;
        }
    }
}

- (void)initAudioComponent{
    // 描述音频元件
    AudioComponentDescription desc;
    desc.componentType         = kAudioUnitType_Output;
    desc.componentSubType      = kAudioUnitSubType_VoiceProcessingIO;
    //kAudioUnitSubType_VoiceProcessingIO, kAudioUnitSubType_RemoteIO
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags        = 0;
    desc.componentFlagsMask    = 0;
    // 获得一个元件
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    // 获得 Audio Unit
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    if (status != noErr) {
        NSLog(@"1、AudioUnitGetProperty error, ret: %d", (int)status);
    }
    
    AudioStreamBasicDescription inputFormat;
    inputFormat.mSampleRate       = self.audioRate;
    inputFormat.mFormatID         = kAudioFormatLinearPCM;
    inputFormat.mFormatFlags      = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved;
    inputFormat.mFramesPerPacket  = 1;
    inputFormat.mChannelsPerFrame = 1;
    inputFormat.mBitsPerChannel   = 16;
//    inputFormat.mBytesPerPacket = 2;
//    inputFormat.mBytesPerFrame = 2;
    inputFormat.mBytesPerFrame    = (inputFormat.mBitsPerChannel / 8) * inputFormat.mChannelsPerFrame;
    inputFormat.mBytesPerPacket   = inputFormat.mBytesPerFrame;
    [self printAudioStreamBasicDescription:inputFormat];
    status = AudioUnitSetProperty(audioUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output,
                         INPUT_BUS,
                         &inputFormat,
                         sizeof(inputFormat));
    if (status != noErr) {
        NSLog(@"2、AudioUnitGetProperty error, ret: %d", (int)status);
    }
    
    AudioStreamBasicDescription outputFormat = inputFormat;
     outputFormat.mChannelsPerFrame = 1;
     
    status = AudioUnitSetProperty(audioUnit,
                          kAudioUnitProperty_StreamFormat,
                          kAudioUnitScope_Input,
                          OUTPUT_BUS,
                          &outputFormat,
                          sizeof(outputFormat));

     if (status != noErr) {
         NSLog(@"3、AudioUnitGetProperty error, ret: %d", (int)status);
     }
    
    UInt32 flag = 1;
    status = AudioUnitSetProperty(audioUnit,
                         kAudioOutputUnitProperty_EnableIO,
                         kAudioUnitScope_Input,
                         INPUT_BUS,
                         &flag,
                         sizeof(flag));
    if (status != noErr) {
        NSLog(@"4、AudioUnitGetProperty error, ret: %d", (int)status);
    }
    
    // 设置数据采集回调函数
    AURenderCallbackStruct recordCallback;
    recordCallback.inputProc = RecordingCallback;
    recordCallback.inputProcRefCon = (__bridge void *)self;
    status = AudioUnitSetProperty(audioUnit,
                         kAudioOutputUnitProperty_SetInputCallback,
                         kAudioUnitScope_Global,
                         INPUT_BUS,
                         &recordCallback,
                         sizeof(recordCallback));
    if (status != noErr) {
        NSLog(@"5、AudioUnitGetProperty error, ret: %d", (int)status);
    }
    
    OSStatus result = AudioUnitInitialize(audioUnit);
    NSLog(@"result %d", (int)result);
}


static OSStatus RecordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    CMAudioSession_PCM *session = (__bridge CMAudioSession_PCM *)inRefCon;
    OSStatus status = noErr;
    UInt16 numSamples = inNumberFrames*1;
     if (inNumberFrames > 0) {
         session->buffList = (AudioBufferList *)malloc(sizeof(AudioBufferList));
         session->buffList->mNumberBuffers = 1;
         session->buffList->mBuffers[0].mNumberChannels = 1;
         session->buffList->mBuffers[0].mDataByteSize = numSamples * sizeof(UInt16);
         session->buffList->mBuffers[0].mData = malloc(numSamples * sizeof(UInt16));
         status = AudioUnitRender(session->audioUnit,
                                  ioActionFlags,
                                  inTimeStamp,
                                  inBusNumber,
                                  inNumberFrames,
                                  session->buffList);
         NSData *pcmData = [NSData dataWithBytes:session->buffList->mBuffers[0].mData
                                    length:session->buffList->mBuffers[0].mDataByteSize];
//         NSLog(@"size = %d", session->buffList->mBuffers[0].mDataByteSize);
         if ([session.delegate respondsToSelector:@selector(cm_audioUnitBackPCM:)]) {
             char* speexByte = (char*)[pcmData bytes];
             
             //添加webRTC降噪
             /* 音频数据 音频采样率
              * 位深 降噪等级0~3
              */
//             int success =  nsProcess(speexByte,
//                                      session.audioRate,
//                                      16,
//                                      (int)session.nsLevel);
//             if (success==0) {
//                 NSLog(@"降噪失败 error:%d",success);
//             }
             NSData *data = [NSData dataWithBytes:speexByte length:pcmData.length];
             [session.delegate cm_audioUnitBackPCM:data];
         }
     } else {
         NSLog(@"inNumberFrames is %u", (unsigned int)inNumberFrames);
     }
    return noErr;
}

//开启AudioUnit
- (void)cm_startAudioUnitRecorder {
    OSStatus status;
    status = AudioOutputUnitStart(audioUnit);
    if (status == noErr) {
        NSLog(@"开启音频");
    }
}

//关闭AudioUnit
- (void)cm_stopAudioUnitRecorder{
    OSStatus status = AudioOutputUnitStop(audioUnit);
    if (status == noErr) {
        NSLog(@"停止音频");
    }
}

- (void)cm_closeAudioUnitRecorder{
    AudioUnitUninitialize(audioUnit);
    if (buffList != NULL) {
        if (buffList->mBuffers[0].mData) {
            free(buffList->mBuffers[0].mData);
            buffList->mBuffers[0].mData = NULL;
        }
        free(buffList);
        buffList = NULL;
    }
    AudioComponentInstanceDispose(audioUnit);
}


- (void)printAudioStreamBasicDescription:(AudioStreamBasicDescription)asbd {
    char formatID[5];
    UInt32 mFormatID = CFSwapInt32HostToBig(asbd.mFormatID);
    bcopy (&mFormatID, formatID, 4);
    formatID[4] = '\0';
    printf("************PCM采集************\n");
    printf("Sample Rate:         %10.0f\n",  asbd.mSampleRate);
    printf("Format ID:           %10s\n",    formatID);
    printf("Format Flags:        %10X\n",    (unsigned int)asbd.mFormatFlags);
    printf("Bytes per Packet:    %10d\n",    (unsigned int)asbd.mBytesPerPacket);
    printf("Frames per Packet:   %10d\n",    (unsigned int)asbd.mFramesPerPacket);
    printf("Bytes per Frame:     %10d\n",    (unsigned int)asbd.mBytesPerFrame);
    printf("Channels per Frame:  %10d\n",    (unsigned int)asbd.mChannelsPerFrame);
    printf("Bits per Channel:    %10d\n",    (unsigned int)asbd.mBitsPerChannel);
    printf("\n");
}

@end
