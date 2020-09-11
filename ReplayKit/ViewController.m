//
//  ViewController.m
//  ReplayKit
//
//  Created by ijiayi on 2020/9/4.
//  Copyright © 2020 ijiayi. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "BlazeiceAudioRecordAndTransCoding.h"
#import "MFJReplayKit.h"
#import "Masonry.h"
#import "MXAlertView.h"
@interface ViewController ()<WKUIDelegate,WKNavigationDelegate>
{
    BOOL isRecing;//正在录制中
    BOOL isPauseing;//正在暂停中
    BOOL isRecingStopSpace;//判断录制间隔空间
    BOOL isCreateAudio;
    
    
    BlazeiceAudioRecordAndTransCoding * audio;
    UIButton * beginBtn;//开始按钮
    UILabel * timelable;//时间展示
    
    int recordingCount;//录制次数
    int timeCount;

 
}
@property(nonatomic,strong)WKWebView * webView;

@property (nonatomic, strong) NSString *fileName;


@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self  SetThePermissions];
    [self  setWKWebView];//初始 录制内容
    [self  setRecordingUI];//初始 录制UI
    [self  setFile];//设置文件路径
    audio = [BlazeiceAudioRecordAndTransCoding new];

    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];//监听是否进入后台
    if ([MFJReplayKit sharedReplay].isRecording) {};//激活状态
}
-(void)enterBackground//进入后台停止录制
{
    if (isRecing == YES)
    {
        dispatch_suspend(_timer);
        [[MFJReplayKit sharedReplay] stopRecordAndShowVideoPreviewController:^(NSString *path) {
        }];
        isRecing = NO;
        beginBtn.selected = NO;
        NSLog(@"由于退出到后台,停止录制.请点击开始录制,才可以继续录制!");
        
    }
}
-(void)setWKWebView
{
    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:@"" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    [wkUController addUserScript:wkUScript];
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = wkUController;
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 60) configuration:configuration];
    // UI代理
    self.webView .UIDelegate = self;
    // 导航代理
    self.webView .navigationDelegate = self;
    // 是否允许手势左滑返回上一级, 类似导航控制的左滑返回
    self.webView .allowsBackForwardNavigationGestures = YES;
    //可返回的页面列表, 存储已打开过的网页
    [self.view addSubview:self.webView];
    [self.webView  loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com"]]];
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
          make.top.offset([[UIApplication sharedApplication] statusBarFrame].size.height);
          make.left.offset(0);
          make.right.offset(0);
          make.bottom.offset(-64);
      }];
}
-(void)setRecordingUI
{
    timelable = [[UILabel alloc]init];
    timelable.textAlignment =NSTextAlignmentCenter;
    timelable.text = @"00:00:00";
    timelable.textColor=[UIColor whiteColor];
    [self.view addSubview:timelable];
    
    //开始按钮
    beginBtn =[UIButton buttonWithType:UIButtonTypeCustom];
    [beginBtn setTitle:@"录制" forState:0];
    [beginBtn setTitle:@"暂停" forState:UIControlStateSelected];

    [beginBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [beginBtn setImage:[UIImage imageNamed:@"play_button"] forState:UIControlStateNormal];
//    [beginBtn setImage:[UIImage imageNamed:@"pause_button"] forState:UIControlStateSelected];
    [beginBtn addTarget:self action:@selector(beginToRecVideo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:beginBtn];
    
    //结束按钮
    UIButton * stopAndSaveBtn =[UIButton buttonWithType:UIButtonTypeCustom];
    [stopAndSaveBtn setTitle:@"结束录制" forState:UIControlStateNormal];
    [stopAndSaveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    stopAndSaveBtn.layer.borderWidth = 0.5f;
    stopAndSaveBtn.layer.borderColor = [UIColor whiteColor].CGColor;
    [stopAndSaveBtn addTarget:self action:@selector(stopAndSaveVideo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopAndSaveBtn];
    [beginBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.webView.mas_bottom).offset(10);
        make.left.offset(30);
        make.width.offset(60);
        make.height.offset(24);
    }];

    
    [timelable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.webView.mas_bottom).offset(0);
        make.left.equalTo(beginBtn.mas_right).offset(30);
        make.height.offset(44);
    }];
    [stopAndSaveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.webView.mas_bottom).offset(5);
        make.left.equalTo(timelable.mas_right).offset(30);
        make.height.offset(34);
        make.width.offset(160);
    }];

}

#pragma mark- Action
/// 开始录制
-(void)beginToRecVideo
{
    if (isRecingStopSpace == YES)//判断录制间隔 防止 文件不完整
    {
        [MXAlertView showWithTopTitle:@"提示" bottomTitles:@[@"取消"] content:@"间隔时间较短!" dataSource:nil completionHandler:^(int index, UIButton *sender) {
        
            
        }];
        return;
    }
    isRecingStopSpace = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self-> isRecingStopSpace = NO;
        
    });
    
    if (isRecing == NO)//判断是否正在录制
    {
        recordingCount++;//标记录制的文件
        [[MFJReplayKit sharedReplay] startRecord:[NSString stringWithFormat:@"%d-%d",recordingCount,recordingCount]];//对文件名进行名称增加标识 保证完成录制时可以合成 视频
        isRecing = YES;
        [self setTime];//进行计时
        beginBtn.selected = YES;
        [audio beginRecordByFileName:[NSString stringWithFormat:@"%d",recordingCount]];//初始化音频文件 路径
        [audio startRecord];//开始录音
    }else{
        dispatch_suspend(_timer);//停止录制
        [[MFJReplayKit sharedReplay] stopRecordAndShowVideoPreviewController:^(NSString *path) {
        }];//结束录制返回当前录制 地址
        /**
         初始化相关文件标记
         */
        isRecing = NO;
        beginBtn.selected = NO;
        [audio pauseRecord];

    }
    //由于 录制屏幕属于系统层级权限 无法主动获取当前权限  只能在录制5s 后查询是否正在录制中 并进行权限不足情况下的判断
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            RPScreenRecorder* recorder = RPScreenRecorder.sharedRecorder;
            if ([recorder isRecording] == NO)
            {
                dispatch_suspend( self->_timer);
                [[MFJReplayKit sharedReplay] stopRecordAndShowVideoPreviewController:^(NSString *path) {
                }];
                self->isRecing = NO;
                self->beginBtn.selected = NO;
                [ self->audio endRecord];
                [self setFile];
                self-> recordingCount = 0;
                self->timeCount = 0;
                self->timelable.text = @"00:00:00";
                [MXAlertView showWithTopTitle:@"提示" bottomTitles:@[@"重新录制",@"取消"] content:@"请允许App录制屏幕,否则无法进行录屏" dataSource:nil completionHandler:^(int index, UIButton *sender) {
    
                    
                }];
                
            }
            
        });
    });
}
/// 结束录制
-(void)stopAndSaveVideo
{
    if (isRecing == YES)
    {
        dispatch_suspend(_timer);
        [[MFJReplayKit sharedReplay] stopRecordAndShowVideoPreviewController:^(NSString *path) {
        }];
        isRecing = NO;
        beginBtn.selected = NO;
        [audio endRecord];

        
    }
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSArray * videoAllArray = [self  getFileList:docPath];
    if (videoAllArray.count < 1)
    {
        [MXAlertView showWithTopTitle:@"提示" bottomTitles:@[@"取消"] content:@"无可用文件" dataSource:nil completionHandler:^(int index, UIButton *sender) {
         
            
        }];
        return;
        
    }
    
    [MXAlertView showWithTopTitle:@"提示" bottomTitles:@[@"重新录制",@"保存到相册"] content:@"是否保存到相册" dataSource:nil completionHandler:^(int index, UIButton *sender) {
        if (index == 0)
        {
            [self setFile];
            self-> recordingCount = 0;
            self->timeCount = 0;
            self->timelable.text = @"00:00:00";
        }else{
            if (videoAllArray.count > 0)
            {
             
                if (self->isCreateAudio == YES) {
                    NSString* videoName = [NSString stringWithFormat:@"%d.mp4",self->recordingCount];
                    NSString *exportPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:videoName];
                    
                    BOOL videoCompatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(exportPath);
                    //检查视频能否保存至相册
                    if (videoCompatible) {
                        UISaveVideoAtPathToSavedPhotosAlbum(exportPath, self,
                    @selector(video:didFinishSavingWithError:contextInfo:), nil);
                    } else {
                        NSLog(@"该视频无法保存至相册");
                    }
                    
                    [self setFile];
                    self-> recordingCount = 0;
                    self->timeCount = 0;
                    self->timelable.text = @"00:00:00";
                    
                }else{
                    [self SyntheticVideo];
                }
            }
        }
    }];
    
    NSLog(@"%@",videoAllArray);
    
    
    
    //    [self updateData:path];
}
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"保存视频失败：%@", error);
    } else {
        NSLog(@"保存视频成功");
        [self setFile];
        self-> recordingCount = 0;
        self->timeCount = 0;
        self->timelable.text = @"00:00:00";
    }
}
///计时
-(void)setTime
{
    int timec = timeCount;
    timeCount=timec; //计时时间
    if (_queue == nil) {
        _queue= dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,_queue);
        dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0); //每秒执行
        dispatch_source_set_event_handler(_timer, ^{
            
            if ([MFJReplayKit sharedReplay].isRecording == NO){
                return ;
            }
            
            int hour    = self->timeCount  /3600;
            int minutes = (self->timeCount%3600)/60;
            int seconds = self->timeCount % 60;
            NSString *strTime;
            strTime= [NSString stringWithFormat:@"%.2d:%.2d:%.2d",hour,minutes,seconds];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //设置界面的按钮显示 根据自己需求设置
                self->timelable.text =strTime;
            });
            self->timeCount++;
        });
    }
    
    dispatch_resume(_timer);
}

#pragma mark- 文件管理
-(void)setFile
{
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSArray * videoAllArray = [self  getFileList:docPath];//获取当前目录所有文件夹
    NSMutableArray * coursewareIdArray = [NSMutableArray array];
    [videoAllArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj containsString:[NSString stringWithFormat:@"%d",recordingCount]])
        {
            [coursewareIdArray addObject:obj];//获取当前切片相关的视频
        }
    }];
    [self removeFileSuffixList:coursewareIdArray filePath:docPath];//移除当前相关切片视频
}
-(NSArray*)getFileList:(NSString*)path{
    if (path.length==0) {
        return nil;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *fileList = [fileManager contentsOfDirectoryAtPath:path error:&error];
    if (error) {
        NSLog(@"getFileList Failed:%@",[error localizedDescription]);
    }
    return fileList;
}
-(void)removeFileSuffixList:(NSArray<NSString*>*)suffixList filePath:(NSString*)path{
    NSArray *fileArray = nil;
    
    fileArray = [self getFileList:path];
    NSMutableArray *fileArrayTmp = [NSMutableArray array];
    for (NSString *fileName in fileArray) {
        NSString* allPath = [path stringByAppendingPathComponent:fileName];
        [fileArrayTmp addObject:allPath];
    }
    fileArray = fileArrayTmp;
    for (NSString *aPath in fileArray) {
        for (NSString* suffix in suffixList) {
            if ([aPath hasSuffix:suffix]) {
                [self removeFile:aPath];
            }
        }
    }
}
-(BOOL)removeFile:(NSString*)filePath{
    BOOL isSuccess = NO;
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    isSuccess = [fileManager removeItemAtPath:filePath error:&error];
    if (error) {
        NSLog(@"removeFile Field：%@",[error localizedDescription]);
    }else{
        NSLog(@"removeFile Success");
    }
    return isSuccess;
}
//拼接输出路径
- (NSURL *)getVideosURLPath:(NSString *)videoName{
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];//获取目录
    NSString *failPath = [documents stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",videoName]];
    NSURL *filUrl = [NSURL fileURLWithPath:failPath];
    return filUrl;
}
//新建文件并返回地址
- (NSString *)action_addFiles:(NSString *)path{
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        //文件夹已存在
    } else {
        //创建文件夹
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}
#pragma mark-  视频合成
-(void)SyntheticVideo//合成
{
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];//获取目录
    NSArray * videoAllArray = [self  getFileList:docPath];//获取路径
    NSMutableArray * coursewareIdArray = [NSMutableArray array];//新建关联容器
    
    [videoAllArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj containsString:[NSString stringWithFormat:@"%d",recordingCount]]&&[obj containsString:@"-"])
        {
            [coursewareIdArray addObject:[NSString stringWithFormat:@"%@/%@",docPath,obj]];//获取当前切片相关的视频
        }
    }];
    if (coursewareIdArray.count > 0)//暂停拼接
    {
        //        //完成拼接多段
        [self synthesisMedia:coursewareIdArray];
    }
}
#pragma mark- 视频合成
-(AVMutableComposition *)mergeVideostoOnevideo:(NSArray*)array{
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    //视频通道
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    //音频通道
//    AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    Float64 tmpDuration =0.0f;
    //合成视频
    for (NSInteger i=0; i<array.count; i++){
        NSURL * url = [NSURL fileURLWithPath:array[i]];
        AVURLAsset *videoAsset = [[AVURLAsset alloc]initWithURL:url options:nil];
        CMTime time = [videoAsset duration];
        NSInteger seconds = ceil(time.value/time.timescale);
        NSLog(@"第%ld个视频时长 = %ld",i,seconds);
        //视频采集
        CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero,videoAsset.duration);
        NSError *error;
        //合成视频
        if ([videoAsset tracksWithMediaType:AVMediaTypeVideo].count < 1)
        {
            NSLog(@"视频未找到图像源文件!");
            return nil;
        }
        [compositionVideoTrack insertTimeRange:timeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:compositionVideoTrack.timeRange.duration error:&error];
//        //合成音频
//        if ([videoAsset tracksWithMediaType:AVMediaTypeAudio].count < 1)
//        {
//            NSLog(@"视频未找到音源文件!");
//        }else{
//
//            [compositionAudioTrack insertTimeRange:timeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:compositionAudioTrack.timeRange.duration error:&error];
//
//        }
        tmpDuration = CMTimeGetSeconds(videoAsset.duration) + tmpDuration;

    }
    //竖屏录制的视频，合成后会改变方向。所以手动转了一下
    //    compositionVideoTrack.preferredTransform =  CGAffineTransformMakeRotation(M_PI/2);
    
    return mixComposition;
}
//分段多个视频 进行合成
- (void)synthesisMedia:(NSMutableArray *)array{
    AVMutableComposition *mixComposition = [self mergeVideostoOnevideo:array];
    if (mixComposition == nil)
    {
        NSLog(@"合成错误XXXXXXXXXXXXXXXXXXXXX");
        [MXAlertView showWithTopTitle:@"出现错误!" bottomTitles:@[@"接受"] content:@"抱歉!由于系统录制出错导致合成文件受损." dataSource:nil completionHandler:^(int index, UIButton *sender) {
            self->isRecing = NO;
            self->beginBtn.selected = NO;
            [ self->audio endRecord];
            [self setFile];
            self-> recordingCount = 0;
            self->timeCount = 0;
            self->timelable.text = @"00:00:00";
        }];
        return;
    }
    AVAssetExportSession* assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    assetExport.outputFileType = AVFileTypeMPEG4;
    NSURL *filUrl = [self getVideosURLPath:[NSString stringWithFormat:@"%d",recordingCount]];//自定义的输出路径
    assetExport.outputURL = filUrl;//视频的输出路径
    assetExport.shouldOptimizeForNetworkUse = YES;
    //视频合成
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        //回到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            AVURLAsset *videoAsset = [[AVURLAsset alloc]initWithURL:filUrl options:nil];
            CMTime time = [videoAsset duration];
            NSInteger seconds = ceil(time.value/time.timescale);
            NSLog(@"%ld",seconds);
            NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];//获取目录

            [self mergeVideo:[[self getVideosURLPath:[NSString stringWithFormat:@"%d",self->recordingCount]] absoluteString] andAudio:[NSString stringWithFormat:@"%@/%d.wav",documents,self->recordingCount] andTarget:self andAction:@selector(videoAndAudio:)];
            
            //在系统相册存储一份（需要开启相册的权限,不然闪退）
            //UISaveVideoAtPathToSavedPhotosAlbum([filUrl path], nil, nil, nil);
            //！！filUrl为视频的输出路径！！
        });
        
    }];
}
-(void)mergeVideo:(NSString *)videoPath andAudio:(NSString *)audioPath andTarget:(id)target andAction:(SEL)action
{
    NSURL *audioUrl=[NSURL fileURLWithPath:audioPath];
    NSURL *videoUrl=[NSURL fileURLWithPath:videoPath];
    
    AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audioUrl options:nil];
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:videoUrl options:nil];
    
    if ([audioAsset tracksWithMediaType:AVMediaTypeAudio].count < 1||[videoAsset tracksWithMediaType:AVMediaTypeVideo].count<1) {
        [MXAlertView showWithTopTitle:@"出现错误!" bottomTitles:@[@"接受"] content:@"抱歉!合成文件受损.需要重新录制.ღ( ´･ᴗ･` )比心~(视频上传中尽量不要切出APP)" dataSource:nil completionHandler:^(int index, UIButton *sender) {
                   [self setFile];
                   self-> recordingCount = 0;
                   self->timeCount = 0;
                   self->timelable.text = @"00:00:00";

        }];
        return;
    }
    //混合音乐
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionCommentaryTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionCommentaryTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration)
                                        ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
                                         atTime:kCMTimeZero error:nil];
    
    
    //混合视频
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                   preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                   ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                    atTime:kCMTimeZero error:nil];
    AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                          presetName:AVAssetExportPresetPassthrough];
    
    //[audioAsset release];
    //[videoAsset release];
    
    //保存混合后的文件的过程
    NSString* videoName = [NSString stringWithFormat:@"%d.mp4",self->recordingCount];
    NSString *exportPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:videoName];
    NSURL    *exportUrl = [NSURL fileURLWithPath:exportPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
    }
    
    _assetExport.outputFileType = @"com.apple.quicktime-movie";
    NSLog(@"file type %@",_assetExport.outputFileType);
    _assetExport.outputURL = exportUrl;
    _assetExport.shouldOptimizeForNetworkUse = YES;
    
    [_assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void )
    {
//        NSLog(@"完成了");
         // your completion code here
         if ([target respondsToSelector:action])
         {
             [target performSelector:action withObject:exportPath withObject:nil];
         }
     }];
    
    //[_assetExport release];
}
-(void)videoAndAudio:(id)exportPath
{
    isCreateAudio = YES;

    NSLog(@"%@",exportPath);
    BOOL videoCompatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(exportPath);
    //检查视频能否保存至相册
    if (videoCompatible) {
        UISaveVideoAtPathToSavedPhotosAlbum(exportPath, self,
                                            @selector(video:didFinishSavingWithError:contextInfo:), nil);
    } else {
        NSLog(@"该视频无法保存至相册");
    }
}

//录音权限
- (BOOL)SetThePermissions
{
    __block BOOL bCanRecord = YES;
    if ([[[UIDevice currentDevice]systemVersion]floatValue] >= 8.0)
    {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:)
                               withObject:^(BOOL granted)
             {
                 if (granted) {
                     bCanRecord = YES;
                 }else {
                     bCanRecord = NO;
                     UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                     }];
                     UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"前往开启" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                         
#ifdef __IPHONE_8_0
                         //跳入当前App设置界面,
                         NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                         if( [[UIApplication sharedApplication]canOpenURL:url] ) {
                             [[UIApplication sharedApplication] openURL:url]; // iOS 9 的跳转
                         }
#else
                         //适配iOS7 ,跳入系统设置界面
                         NSURL *url = [NSURL URLWithString:@"prefs:General&path=Reset"];
                         if( [[UIApplicationsharedApplication]canOpenURL:url] ) {
                             [[UIApplicationsharedApplication]openURL:url];
                         }
#endif
                     }];
                     NSLog(@"麦克风权限未开启");
                     [MXAlertView showWithTopTitle:@"出现错误!" bottomTitles:@[@"取消",@"去开启"] content:@"录制需要用到你的麦克风权限" dataSource:nil completionHandler:^(int index, UIButton *sender) {
                         
                         if (index == 1)
                         {
                             NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                             if ([[UIApplication sharedApplication] canOpenURL:url]) {
                                 if (@available(iOS 10.0, *)) {
                                     [[UIApplication sharedApplication] openURL:url
                                                                        options:@{}
                                                              completionHandler:^(BOOL success) {
                                         
                                     }];
                                 }else{
                                     [[UIApplication sharedApplication] openURL:url];
                                     
                                 }
                             }
                             
                         }
                     }];
                 }
             }];
        }
    }
    
    return bCanRecord;
}

@end
