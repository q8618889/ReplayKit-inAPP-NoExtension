//
//  MFJReplayKit.h
//  ReplayKit
//
//  Created by MAX on 2020/9/4.
//  Copyright © 2020 MAX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ReplayKit/ReplayKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface MFJReplayKit : NSObject<RPPreviewViewControllerDelegate>

/**
 *  是否正在录制
 */
@property (nonatomic,assign,readonly) BOOL isRecording;

/**
 *  单例对象
 */
+(instancetype)sharedReplay;

/**
 *  开始录制
 *  fileName 本地储存路径 
 */
-(void)startRecord:(NSString *)fileName;
/**
 *  结束录制
 */
-(void)stopRecordAndShowVideoPreviewController:(void(^)(NSString * path))pathBlock;
@end

NS_ASSUME_NONNULL_END
