function y = helperModClassFrameGenerator(x, windowLength, stepSize, offset, sps)
%helperModClassFrameGenerator为机器学习生成框架
%Y=helperModClassFrameGenerator（X、WLEN、STEP、OFFSET、SPS）分段
%输入X，用于生成机器学习算法中使用的帧。
%X必须是复值列向量。输出Y是一个大小
%WLENxN复值数组，其中N是输出帧数。
%每个单独的帧都有WLEN样本。窗口进行STEP
%新帧的样本。STEP可以小于或大于WLEN。
%该函数在计算出输入X后开始对其进行分段
%基于offset值的初始偏移。OFFSET是确定性的
%指定为实值标量的偏移值。SPS是
%每个符号的样本数。总偏移量为偏移+随机（[0 SPS]）样本。这个
%偏移的确定性部分消除了瞬态，而随机
%部分使网络能够适应未知的延迟值。每一帧
%被归一化为具有单位能量。
%
%另请参见调制分类与深度学习示例。
%版权所有2018 The MathWorks，股份有限公司。


numSamples = length(x);
numFrames = ...
  floor(((numSamples-offset)-(windowLength-stepSize))/stepSize);

y = zeros([windowLength,numFrames],class(x));

startIdx = offset + randi([0 sps]);
frameCnt = 1;
while startIdx + windowLength < numSamples
  xWindowed = x(startIdx+(0:windowLength-1),1);
  framePower = mean(abs(xWindowed).^2);
  xWindowed = xWindowed / sqrt(framePower);
  y(:,frameCnt) = xWindowed;
  frameCnt = frameCnt + 1;
  startIdx = startIdx + stepSize;
end
