# Modulation-Classification-With-Pluto-SDR
# 基于 PLUTOSDR 和深度学习的调制制式识别系统😍

## 概述 Overview
本项目是 2024 ADI通达杯比赛的作品，在比赛中获得了二等奖。主要功能是通过深度学习实现调制制式的识别，并且进行位同步、频偏补偿、相偏补偿。

This project is an entry for the 2024 ADI Tongda Cup competition, where it was awarded the second prize. Its primary function is to achieve modulation scheme recognition through deep learning, as well as to perform bit synchronization, frequency offset compensation, and phase offset compensation.

在比赛中，发送端使用矢量信号源（如 RS 的 SMBV100A）或 Pluto 设备发出各种调制信号，每五秒钟改变一次调制方式，接收端使用另一台 Pluto 设备接收信号，并通过算法进行调制制式的识别。

During the competition, the transmitting end utilizes a vector signal generator (such as the SMBV100A from RS) or a Pluto device to emit various modulated signals, altering the modulation method every five seconds. The receiving end employs another Pluto device to capture the signals and utilizes algorithms to identify the modulation schemes.

## 运行环境 Operating Environment
- **Matlab 版本：R2024a**  Matlab 应当安装通信常用的工具箱，深度学习工具箱，以及 Pluto SDR 的相关 Toolbox
- **需要两台电脑:** 一台运行发送端代码，一台运行接收端代码
- **需要两台 PLUTO SDR**：一台用于发送，一台用于接收

- **Matlab Version：R2024a**  Matlab should be installed with commonly used toolboxes for communications, the Deep Learning Toolbox, and the relevant Toolbox for Pluto SDR.  
- **Two computers are required:** One to run the transmitting end code and the other to run the receiving end code.
- **Two PLUTO SDRs are required**: One to send, the other to receive.

## 功能说明 Function
1. **可以识别的信号调制方式**：BPSK、QPSK、8PSK、4QAM（QPSK）、16QAM、64QAM、4PAM、FM
2. **发送端信号**：是伪随机序列经过 0.35 根升余弦成型后的基带数据。
3. **载频频率**：1.8GHz
4. **测试环境**：测评时的环境为实验室环境，信道条件近似为 AWGN 信号。
5. **识别距离**：大概 1 米
6. **缺陷**：对于 64QAM 这类制式，虽然可以较为准确地识别类型，但并不能准确描绘出星座图。原因可能在于接收端的增益过低。

(Function)
1. **Recognizable Signal Modulation Schemes**: BPSK, QPSK, 8PSK, 4QAM (QPSK), 16QAM, 64QAM, 4PAM, FM  
2. **Transmitting End Signal**: The signal is baseband data formed by a pseudo-random sequence shaped with a 0.35 root-raised cosine filter.  
3. **Carrier Frequency**: 1.8 GHz  
4. **Testing Environment**: The evaluation was conducted in a laboratory setting, with channel conditions approximating AWGN (Additive White Gaussian Noise).  
5. **Recognition Distance**: Approximately 1 meter  
6. **Limitations**: For modulation schemes like 64QAM, while the type can be identified with relatively high accuracy, the constellation diagram cannot be accurately depicted. This issue may stem from the low gain at the receiving end.

## 代码说明 About the Code
1. **参考**：本代码基于 Matlab 的示例代码开发，链接： https://ww2.mathworks.cn/help/deeplearning/ug/modulation-classification-with-deep-learning.html
2. **发送端的代码**：直接运行 `testwithpluto_onlysend.m` 即可
3. **接收端的代码**：直接运行 `testwithpluto_onlyreceive.m` 即可
4. **其他代码**：总体功能与示例代码保持一致，但是为了适应比赛要求而做了一些改动

(About the Code)
1. **Reference**: This code is developed based on Matlab's example code, at: https://ww2.mathworks.cn/help/deeplearning/ug/modulation-classification-with-deep-learning.html
2. **Transmitting End Code**: Simply run `testwithpluto_onlysend.m`.  
3. **Receiving End Code**: Simply run `testwithpluto_onlyreceive.m`.  
4. **Other Code**: The overall functionality remains consistent with the example code, but modifications have been made to meet the competition requirements.
