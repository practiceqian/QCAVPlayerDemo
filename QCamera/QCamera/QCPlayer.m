//
//  ViewController.m
//  QCamera
//
//  Created by huya_qiancheng on 2020/5/18.
//  Copyright © 2020 cccheng. All rights reserved.
//

#import "QCPlayer.h"
#import <Masonry.h>
#import <AVFoundation/AVFoundation.h>
@interface QCPlayer ()
//播放速度显示
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
//播放区域
@property (weak, nonatomic) IBOutlet UIImageView *playerView;

@property (weak, nonatomic) IBOutlet UILabel *curTime;
@property (weak, nonatomic) IBOutlet UILabel *totalTime;
@property (weak, nonatomic) IBOutlet UIProgressView *playProgress;
@property (assign) CGFloat totalSecs;
@property (assign) CGFloat curSec;


//播放控制器
@property (nonatomic,strong) AVPlayer * player;
//播放源控制
@property (nonatomic,strong) AVPlayerItem* playItem;
//播放显示层
@property (nonatomic,strong) AVPlayerLayer* playerLayer;
@end
@implementation QCPlayer

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //播放资源
    NSURL* playUrl = [NSURL URLWithString:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"];
    self.playItem = [AVPlayerItem playerItemWithURL:playUrl];
    //播放器实例
    self.player = [AVPlayer playerWithPlayerItem:self.playItem];
    //显示区域
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.playerView.bounds;
    //将显示区域添加到UIImageView上
    [self.playerView.layer addSublayer:self.playerLayer];
    
    //监听播放状态
    [self.playItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    //监听播放进度
    __weak typeof(self) weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:nil usingBlock:^(CMTime time) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        AVPlayerItem* item = strongSelf.playItem;
        strongSelf.curSec = item.currentTime.value/item.currentTime.timescale;
        strongSelf.curTime.text = strongSelf.curSec>9?[NSString stringWithFormat:@"00:%.0f",strongSelf.curSec]:[NSString stringWithFormat:@"00:0%.0f",strongSelf.curSec];
        strongSelf.playProgress.progress = strongSelf.curSec/strongSelf.totalSecs;
    }];
    
    [self.playItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
}

//播放
- (IBAction)play:(UIButton *)sender {
    self.player.rate = 1.0;
    [self changeSpeedLabelText:self.player.rate];
    [self.player play];
}

//暂停
- (IBAction)pause:(UIButton *)sender {
    self.player.rate = 1.0;
    [self changeSpeedLabelText:self.player.rate];
    [self.player pause];
}
//速度-
- (IBAction)playSpeedDown:(UIButton *)sender {
    if (self.player.rate>1.0) {
        self.player.rate -= 0.25;
        [self changeSpeedLabelText:self.player.rate];
    }
}
//速度+
- (IBAction)playSpeedUp:(UIButton*)sender {
    if (self.player.rate<2.0) {
        self.player.rate += 0.25;
        [self changeSpeedLabelText:self.player.rate];
    }
}
//更改播放速度标签
-(void)changeSpeedLabelText:(float)rate{
    self.speedLabel.text = [NSString stringWithFormat:@"%.2fx",rate];
}

#pragma mark - 监听播放状态
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([object isKindOfClass:[AVPlayerItem class]]) {
        if ([keyPath isEqualToString:@"status"]) {
            switch (self.playItem.status) {
                case AVPlayerItemStatusUnknown:
                    NSLog(@"播放状态未知");
                    break;
                case AVPlayerItemStatusReadyToPlay:
                    NSLog(@"准备播放");
                    self.totalSecs = CMTimeGetSeconds(self.playItem.duration);
                    self.totalTime.text = [NSString stringWithFormat:@"00:%.0f",self.totalSecs];
                    //开始播放
                    [self.player play];
                    break;
                case AVPlayerItemStatusFailed:
                    NSLog(@"播放失败");
                    break;;
                default:
                    break;
            }
        }else if ([keyPath isEqualToString:@"loadedTimeRanges"]){
            NSArray *array = self.playItem.loadedTimeRanges;
            CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
            float startSeconds = CMTimeGetSeconds(timeRange.start);
            float durationSeconds = CMTimeGetSeconds(timeRange.duration); NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
            NSLog(@"当前缓冲时间：%f",totalBuffer);
        }
    }
}
- (void)dealloc
{
    [self.playItem removeObserver:self forKeyPath:@"status"];
}
@end
