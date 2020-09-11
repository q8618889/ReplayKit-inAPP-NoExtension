//
//  MFJReplayKit.m
//  ReplayKit
//
//  Created by MAX on 2020/9/4.
//  Copyright © 2020 MAX. All rights reserved.
//

#import "MFJReplayKit.h"
//弱引用
#define kWeakSelf(weakSelf) __weak __typeof(&*self)weakSelf = self;
@interface MFJReplayKit ()
@property (nonatomic, assign) BOOL  isFirstSample; // 是否第一帧数据
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterInput;
@property (nonatomic, strong) AVAssetWriterInput *assetAudioInput;


@property (nonatomic, strong) NSString *videoOutPath; // 当前沙盒保存视频的路径
@property (strong,nonatomic)NSString * fileName;//文件名称

@end
@implementation MFJReplayKit

/// 初始化录制工具
+(instancetype)sharedReplay{
    static MFJReplayKit *replay=nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        replay=[[MFJReplayKit alloc] init];
        
    });
    return replay;
}
//是否正在录制
-(BOOL)isRecording{
    return [RPScreenRecorder sharedRecorder].recording;
}
/**
 *  开始录制
 */
-(void)startRecord:(NSString *)fileName;
{
    _fileName = fileName;
    self.isFirstSample = YES;
//    [RPScreenRecorder sharedRecorder].microphoneEnabled = YES;
    [self initAV];
    if ([RPScreenRecorder sharedRecorder].recording==YES) {
           NSLog(@"已经开始录制");
           return;
       }
    if ([[UIDevice currentDevice].systemVersion floatValue]<10.0) {
        NSLog(@"当前系统不支持 录制 需要10.0以上,如果你需要9.0 的创建方式请该方式不支持,请使用APPGroup 方式进行录制");
        return ;
    }else{
        if ([[RPScreenRecorder sharedRecorder] isAvailable]) {
            NSLog(@"录制开始初始化");
            [self intRPScreenRecorder];
        }else{
             NSLog(@"不支持ReplayKit");
        }
    }
    
}
/**
 *  结束录制
 */
-(void)stopRecordAndShowVideoPreviewController:(void(^)(NSString * path))pathBlock;
{
    [[RPScreenRecorder sharedRecorder] stopRecordingWithHandler:^(RPPreviewViewController *previewViewController, NSError *  error){
        if (error) {
            NSLog(@"结束录制error %@", error);
            
        }
        else {
            NSLog(@"录制完成");
            
        }
    }];
    //    kWeakSelf(weakSelf);
    __block BOOL finish = NO;
    [self.assetWriterInput markAsFinished];//结束视频写入
    [self.assetAudioInput markAsFinished];//结束音频写入
    [self.assetWriter finishWritingWithCompletionHandler:^{
        self.assetWriterInput = nil;
        self.assetAudioInput = nil;
        self.assetWriter = nil;
        NSLog(@"%@",self.videoOutPath);
        pathBlock(self.videoOutPath);
        
        finish = YES;
    }];

   
}
-(void)initAV
{
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    self.videoOutPath = [documents stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",self.fileName]];
    
    [[NSFileManager defaultManager] removeItemAtPath:self.videoOutPath error:nil];//设置路径
    // 定义 AVAssetWriter
    NSNumber *width= [NSNumber numberWithFloat:[[UIScreen mainScreen] bounds].size.width];
    NSNumber *height = [NSNumber numberWithFloat:[[UIScreen mainScreen] bounds].size.height];
    // 视频参数
    NSDictionary *compressionProperties =
        @{AVVideoProfileLevelKey         : AVVideoProfileLevelH264HighAutoLevel,
          AVVideoH264EntropyModeKey      : AVVideoH264EntropyModeCABAC,
          AVVideoAverageBitRateKey       : @(1920 * 1080 * 11.4),
          AVVideoMaxKeyFrameIntervalKey  : @30,
          AVVideoAllowFrameReorderingKey : @NO};

    NSDictionary *videoSettings =
        @{
            AVVideoCompressionPropertiesKey : compressionProperties,
            AVVideoCodecKey                 : AVVideoCodecTypeH264,
            AVVideoWidthKey                 : width,
            AVVideoHeightKey                : height
        };
//    // 音频参数
//    AudioChannelLayout acl;
//        bzero( &acl, sizeof(acl));
//        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
//
//

    
    
     // 音频参数
    AudioChannelLayout acl;
        bzero( &acl, sizeof(acl));
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;

    NSDictionary *audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
                                             [NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                                             [NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                                             [NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                                             [NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                                             nil];
    
 
    
//    CMAudioFormatDescriptionRef audioFormatDesc = nil;
//    {
//        AudioStreamBasicDescription outAudioStreamBasicDescription = {0};
//        // 设置采样率，有 32K, 44.1K，48K
//        outAudioStreamBasicDescription.mSampleRate = 32000;
//
//        // 音频格式可以设置为 ：
//        // kAudioFormatMPEG4AAC_HE
//        // kAudioFormatMPEG4AAC_HE_V2
//        // kAudioFormatMPEG4AAC
//        outAudioStreamBasicDescription.mFormatID = kAudioFormatMPEG4AAC_HE;
//
//        // 指明格式的细节. 设置为 0 说明没有子格式。
//        // 如果 mFormatID 设置为 kAudioFormatMPEG4AAC_HE 该值应该为0
//        outAudioStreamBasicDescription.mFormatFlags = 0;
//
//        // 每个音频包的字节数.
//        // 该字段设置为 0, 表明包里的字节数是变化的。
//        // 对于使用可变包大小的格式，请使用AudioStreamPacketDescription结构指定每个数据包的大小。
//        outAudioStreamBasicDescription.mBytesPerPacket = 0;
//
//        // 每个音频包帧的数量. 对于未压缩的数据设置为 1.
//        // 动态码率格式，这个值是一个较大的固定数字，比如说AAC的1024。
//        // 如果是动态帧数（比如Ogg格式）设置为0。
//        outAudioStreamBasicDescription.mFramesPerPacket = 1;
//
//        // 每个帧的字节数。对于压缩数据，设置为 0.
//        outAudioStreamBasicDescription.mBytesPerFrame = 0;
//
//        // 音频声道数
//        outAudioStreamBasicDescription.mChannelsPerFrame = 2;
//
//        // 压缩数据，该值设置为0.
//        outAudioStreamBasicDescription.mBitsPerChannel = 0;
//
//        // 用于字节对齐，必须是0.
//        outAudioStreamBasicDescription.mReserved = 0;
//
//        CMAudioFormatDescriptionCreate(NULL, &outAudioStreamBasicDescription, 0, NULL, 0, NULL, NULL, &audioFormatDesc);
//    }
    

    
    // 定义 writer
    self.assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    self.assetWriterInput.expectsMediaDataInRealTime = YES;

    self.assetAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
    self.assetAudioInput.expectsMediaDataInRealTime = YES;

    self.assetWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:self.videoOutPath] fileType:AVFileTypeMPEG4 error:nil];
    [self.assetWriter addInput:self.assetWriterInput];
    [self.assetWriter addInput:self.assetAudioInput];
    [self.assetWriter setMovieTimeScale:60];
    //    开始写入视频
    [self.assetWriter startWriting];
}
-(void)intRPScreenRecorder{
    
    [[RPScreenRecorder sharedRecorder] startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
        switch (bufferType) {
            case RPSampleBufferTypeVideo:
                // Handle video sample buffer for app audio
            {
                // 如果是第一帧数据，判断数据类型，如果不是 video，则废弃，否则会出现视频开头是黑屏
                if (self.isFirstSample) {
                    self.isFirstSample = NO;
                }
                if (CMSampleBufferIsValid(sampleBuffer) && self.assetWriterInput.readyForMoreMediaData) {
                    [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                    [self.assetWriterInput appendSampleBuffer:sampleBuffer];
                }
            }
                break;
            case RPSampleBufferTypeAudioApp:
                //合成不出来 拿到信息后 读取后为nil
                // Handle audio sample buffer for app audio
//                if (CMSampleBufferIsValid(sampleBuffer) && self.assetWriterInput.readyForMoreMediaData) {
//                    [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
//                    [self.assetAudioInput appendSampleBuffer:sampleBuffer];
//                }
                break;
            case RPSampleBufferTypeAudioMic:
                ////合成不出来 拿到信息后 读取后为nil 但是 在 iOS12 部分版本中  录音权限偶尔 无法启动 所以单独录制
//                 Handle audio sample buffer for mic audio
//                if (CMSampleBufferIsValid(sampleBuffer) && self.assetWriterInput.readyForMoreMediaData) {
//                    [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
//                    [self.assetAudioInput appendSampleBuffer:sampleBuffer];
//                }
                break;
            default:
                break;
        }
    } completionHandler:^(NSError * _Nullable error) {
        NSLog(@"%@",error);
    }];
    

}
@end
