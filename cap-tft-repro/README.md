# cap-tft-repro — Cardputer Zero 内屏镜像到 ADV Cap TFT 外屏

在新设备 + 新外屏上复现"主屏画面镜像到外屏"的完整方案。

## 效果

内屏(/dev/fb0,320x170 RGB565)实时镜像到外屏(2.8" ILI9341 SPI 屏),
1:1 原始大小铺满全宽,上下各 35px 黑边,约 10fps,开机自启。

## 硬件前提

- Cardputer Zero(或任何 Raspberry Pi OS 设备,fb0 为 320x170)
- Prokuon CardputerADV Cap TFT V2(ILI9341),插在 HAT/CAP 扩展槽
- 接线(扩展槽默认引出,手动连线参考):
  SCLK=GPIO11,MOSI=GPIO10,CS=GPIO7(spidev0.1),DC=GPIO22,RES=GPIO26,
  供电=扩展槽 5V(ext_5v_out),GND

## 安装

把整个目录拷到新设备,然后:

```bash
cd cap-tft-repro
bash install.sh
sudo reboot
```

install.sh 做的事:
1. 装依赖 `python3-spidev python3-pil device-tree-compiler`
2. 装镜像程序 `/usr/local/bin/cap-tft-mirror`
3. 装默认参数 `/etc/default/cap-tft-mirror`
4. 装并 enable 服务 `cap-tft-mirror.service`
5. 编译安装 `cap-tft-5v.dtbo` overlay(开机自动打开扩展槽 5V 供电)
6. 在 `/boot/firmware/config.txt` 追加 `dtparam=spi=on` 和 `dtoverlay=cap-tft-5v`

重启后外屏应自动跟随内屏。

## 关键结论(踩坑记录)

1. **这块屏的显存是横屏 320x240**,不是资料标称的竖屏 240x320。
   按 240x320 推会导致:左边 80 列显示垃圾(紫条)、行回绕错位。
2. **MY/MV 位行为异常**:设 MY 无效果,设 MV 出梳子状条纹。
   所以上下翻转在软件里做(ROTATE_180),不用面板寄存器。
3. **字节序**:PIL 输出小端,面板要大端,推送前必须 byteswap。
4. **内核 fbtft 驱动方案不可用**(持续刷流会冻结/雪花),spidev 直推是唯一稳定路径。
5. SPI 速度 16MHz 稳定;32MHz 在复杂画面下偶发位错误。
6. 面板用**精简初始化序列**(完整 Adafruit 序列在此面板上会导致固定雪花带)。

## 参数调优(/etc/default/cap-tft-mirror)

改完 `sudo systemctl restart cap-tft-mirror` 生效:

| 参数 | 默认 | 说明 |
|---|---|---|
| MADCTL | 0x40 | 0x36 寄存器值。MX=镜像方向;BGR 位(0x08)影响红蓝顺序 |
| TRANSFORM | ROTATE_180 | 软件翻转:ROTATE_180 / FLIP_LEFT_RIGHT / FLIP_TOP_BOTTOM |
| INVERT | 0 | 1=INVON(反相显示),0=INVOFF |
| SWAP | 1 | 1=字节交换(大端),0=不交换 |
| SPEED | 16000000 | SPI 时钟 Hz |

## 新屏排障方法(如果换了一批屏表现不同)

方向/几何不对:推一个分色块图案(不同区域不同纯色+数字编号),
拍照对照实际显示位置,反推显存映射。颜色不对:推 8 色块
(红绿蓝黄青品红白黑),逐一比对,再调 MADCTL 的 BGR 位、SWAP、INVERT
(一共就 2x2x2 种组合,轮一遍必有正解)。
