# ReplayKit-inAPP-NoExtension 使用的第二种


iOS 获取屏幕已经在iOS10 以后 有完整的 框架 但是需要外部权限实现框架 获取视频数据
想要实现内部的在 app 录制视频 并保存在沙盒路径内 可使用方案   
第一种 是一帧一帧 合成 最后加长录音 合成到视频
第二种 获取框架 数据流 写入本地 
第三种 完全按照框架流程系统权限去做

第一种实现需要使用AVPlayer 的截图功能开定时器 每 0.1s 进行一次 屏幕截屏
优点:可指定录制区域 不需要其他处理 

缺点 : cpu 占用太高 内存释放缓慢 卡顿 掉帧

坑:与webView 交互 会非常卡顿导致 webView 卡顿  cup 过高时 录制 同时也收到影响 

(这类网上实现的比较多.demo,也比较多, 如果业务功能本身cpu 占用不高 的话可以尝试使用)


第二种 获取框架中的数据流 并写入本地 

优点:cpu 占用非常少, 视频可控制清晰度.快捷.权限简单

缺点:录制区域是处过特殊处理的 view 将全部被录制其中.业务层UI不好分离 且只能录制在当前APP 内

坑:给系统录制权限是 超过几分钟就会重新弹出权限弹窗,(第一次录制录音可用,第二次录制时麦克风权限将消失(目前发现系统iOS12.3以前都有这个问题 解决方案 录音和录制屏幕分开处理 最后合成视频 方便对音轨视频做单独处理))

(13.3系统中弹出权限时间有些长 且无法获取 权限按钮的触发 所以 录制前5s 需要进行权限判断()  录制后的音频通道写入出现问题在解决  录音通道没有问题)



(这类文献较少读写数据流有一定难度,需要自己实现合成视频合成音频,不可再内存中储存 还有50M 可以使用,直接写到沙盒文件)

第三种 完全按照框架流程来 需要使用  App Groups，在iOS 8的SDK中提供的扩展新特性实现跨App的数据操作和分享；这个功能需要APP使用同一个证书。

优点:cpu 占用非常少, 视频可控制清晰度.快捷.权限简单.

缺点:需要新建依赖项目集成 

坑:正在采集相关数据(正在尝试ReplayKit----2)!
