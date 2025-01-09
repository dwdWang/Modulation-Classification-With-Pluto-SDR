function modClassNet = helperModClassCNN(modulationTypes,sps,spf)
%helperModClassCNN调制分类CNN
%CNN=helperModClassCNN（MODTYPES、SPS、SPF）创建卷积
%神经网络，CNN，用于调制分类。MODTYPES是
%网络可以识别的调制类型，SPS是
%SPF是每帧的样本数。
%
%CNN由五个卷积层和一个完全连接的层组成
%层。除最后一个卷积层外，每个卷积层后面都有一个批
%归一化层、整流线性单元（ReLU）激活层，以及
%最大池化层。在最后一个卷积层中，最大池化层
%被全局平均池化层所取代。输出层具有
%softmax激活。

numModTypes = numel(modulationTypes);
netWidth = 1;
poolSize = 2;

modClassNet = [
  sequenceInputLayer(1,SplitComplexInputs=1,MinLength=spf,...
    Normalization="zscore",Name="Input Layer")

  convolution1dLayer(sps,16*netWidth,Padding="same",Name="CNN1")
  batchNormalizationLayer(Name="BN1")
  reluLayer(Name="ReLU1")
  maxPooling1dLayer(poolSize,Stride=poolSize,Name="MaxPool1")

  convolution1dLayer(sps,32*netWidth,Padding="same",Name="CNN2")
  batchNormalizationLayer(Name="BN2")
  reluLayer(Name="ReLU2")
  maxPooling1dLayer(poolSize,Stride=poolSize,Name="MaxPool2")

  convolution1dLayer(sps,48*netWidth,Padding="same",Name="CNN3")
  batchNormalizationLayer(Name="BN3")
  reluLayer(Name="ReLU3")
  maxPooling1dLayer(poolSize,Stride=poolSize,Name="MaxPool3")

  convolution1dLayer(sps,64*netWidth,Padding="same",Name="CNN4")
  batchNormalizationLayer(Name="BN4")
  reluLayer(Name="ReLU4")
  maxPooling1dLayer(poolSize,Stride=poolSize,Name="MaxPool4")

  convolution1dLayer(sps,32*netWidth,Padding="same",Name="CNN5")
  batchNormalizationLayer(Name="BN5")
  reluLayer(Name="ReLU5")
  globalAveragePooling1dLayer(Name="AP1")  

  fullyConnectedLayer(numModTypes,Name="FC1")
  softmaxLayer(Name="SoftMax")];