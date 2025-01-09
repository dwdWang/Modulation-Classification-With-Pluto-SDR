% 定义不同的调制方式类型
modulationTypes = categorical(sort(["BPSK", "QPSK", "8PSK", ...
  "16QAM", "64QAM", "PAM4"]));
numFramesPerModType = 10000;  % 每种调制类型生成的帧数

% 训练集、验证集和测试集的比例
percentTrainingSamples = 80;
percentValidationSamples = 10;
percentTestSamples = 10;
SNR = 30;  % 信噪比
sps = 8;   % 每个符号的采样点数
spf = 1024;  % 每帧的采样点数
fs = 8e6;  % 采样率
fc = 1.8e9;  % 中心频率（1.8GHz）

% 创建信道
maxDeltaOff = 5;
deltaOff = (rand()*2*maxDeltaOff) - maxDeltaOff;  % 随机偏移
C = 1 + (deltaOff / 1e6);  % 时钟偏移修正
channel = helperModClassTestChannel(...
  'SampleRate', fs, ...
  'SNR', SNR, ...
  'PathDelays', [0 1.8 3.4] / fs, ...
  'AveragePathGains', [0 -2 -10], ...
  'KFactor', 4, ...
  'MaximumDopplerShift', 4, ...
  'MaximumClockOffset', 5, ...
  'CenterFrequency', 1.8e9);  % 信道设置，使用1.8GHz的中心频率

% 设置随机数生成器的种子，确保每次生成相同的数据
rng(12)

tic  % 开始计时
numModulationTypes = length(modulationTypes);  % 调制方式的数量
channelInfo = info(channel);  % 获取信道信息
transDelay = 50;  % 瞬态延迟

% 数据存储目录
dataDirectory = uigetdir("", "Select network location to save data files");

disp("Data file directory is " + dataDirectory)  % 显示数据文件的保存路径
fileNameRoot = "frame";  % 文件名的根

% 检查数据文件是否已存在
dataFilesExist = false;
if exist(dataDirectory, 'dir')
    files = dir(fullfile(dataDirectory, sprintf("%s*", fileNameRoot)));
    if length(files) == numModulationTypes * numFramesPerModType
        dataFilesExist = true;  % 如果数据文件已存在，标记为true
    end
end

% 如果数据文件不存在，生成数据并保存
if ~dataFilesExist
    disp("Generating data and saving in data files...")
    [success, msg, msgID] = mkdir(dataDirectory);  % 创建数据目录
    if ~success
        error(msgID, msg)  % 如果目录创建失败，报错
    end
    for modType = 1:numModulationTypes  % 遍历每种调制方式
        elapsedTime = seconds(toc);  % 计算已经经过的时间
        elapsedTime.Format = 'hh:mm:ss';  % 格式化时间输出
        fprintf('%s - Generating %s frames\n', ...
            elapsedTime, modulationTypes(modType))

        label = modulationTypes(modType);  % 当前调制方式的标签
        numSymbols = (numFramesPerModType / sps);  % 每种调制方式生成的符号数
        dataSrc = helperModClassGetSource(modulationTypes(modType), sps, 2 * spf, fs);  % 获取数据源
        modulator = helperModClassGetModulator(modulationTypes(modType), sps, fs);  % 获取调制器
        
        % 数字调制方式使用1.8GHz的中心频率
        channel.CenterFrequency = 1.8e9;

        for p = 1:numFramesPerModType  % 对每一帧进行处理
            % 生成随机数据
            x = dataSrc();

            % 调制
            y = modulator(x);

            % 通过信道传输信号
            rxSamples = channel(y);

            % 去除瞬态部分，修剪到大小并进行归一化
            frame = helperModClassFrameGenerator(rxSamples, spf, spf, transDelay, sps);

            % 保存数据文件
            fileName = fullfile(dataDirectory, ...
                sprintf("%s%s%03d", fileNameRoot, modulationTypes(modType), p));
            save(fileName, "frame", "label")  % 保存数据帧和标签
        end
    end
else
    disp("Data files exist. Skip data generation.")  % 如果数据文件已存在，跳过数据生成
end

% 创建信号数据存储
frameDS = signalDatastore(dataDirectory,'SignalVariableNames',["frame","label"]);

% 拆分训练集、验证集和测试集
splitPercentages = [percentTrainingSamples, percentValidationSamples, percentTestSamples];
[trainDS, validDS, testDS] = helperModClassSplitData(frameDS, splitPercentages);

% 读取训练集和验证集数据到内存
trainFrames = transform(trainDS, @helperModClassReadFrame);
rxTrainFrames = readall(trainFrames);  % 直接读取所有帧，不使用并行

validFrames = transform(validDS, @helperModClassReadFrame);
rxValidFrames = readall(validFrames);  % 直接读取所有帧，不使用并行

% 读取训练集和验证集标签到内存
trainLabels = transform(trainDS, @helperModClassReadLabel);
rxTrainLabels = readall(trainLabels);  % 直接读取所有标签，不使用并行

validLabels = transform(validDS, @helperModClassReadLabel);
rxValidLabels = readall(validLabels);  % 直接读取所有标签，不使用并行

% 创建CNN网络
modClassNet = helperModClassCNN(modulationTypes, sps, spf);
maxEpochs = 20;
miniBatchSize = 1024;
trainingPlots = "none";
metrics = [];
verbose = true;
validationFrequency = floor(numel(rxTrainLabels) / miniBatchSize);  % 验证频率
validationFrequency = max(1, floor(numel(rxTrainLabels) / miniBatchSize));  % 确保验证频率是正值
options = trainingOptions('sgdm', ...
  InitialLearnRate = 3e-1, ...
  MaxEpochs = maxEpochs, ...
  MiniBatchSize = miniBatchSize, ...
  Shuffle = 'every-epoch', ...
  Plots = trainingPlots, ...
  Verbose = verbose, ...
  ValidationData = {rxValidFrames, rxValidLabels}, ...
  ValidationFrequency = validationFrequency, ...
  ValidationPatience = 5, ...
  Metrics = metrics, ...
  LearnRateSchedule = 'piecewise', ...
  LearnRateDropPeriod = 6, ...
  LearnRateDropFactor = 0.75, ...
  OutputNetwork = 'best-validation-loss');  % 设置训练参数

% 开始训练网络
elapsedTime = seconds(toc);
elapsedTime.Format = 'hh:mm:ss';
fprintf('%s - Training the network\n', elapsedTime)
trainedNet = trainnet(rxTrainFrames, rxTrainLabels, modClassNet, "crossentropy", options);  % 训练网络

% 测试网络性能
elapsedTime = seconds(toc);
elapsedTime.Format = 'hh:mm:ss';
fprintf('%s - Classifying test frames\n', elapsedTime)

% 读取测试集数据
testFrames = transform(testDS, @helperModClassReadFrame);
rxTestFrames = readall(testFrames);  % 直接读取所有帧，不使用并行

% 读取测试集标签
testLabels = transform(testDS, @helperModClassReadLabel);
rxTestLabels = readall(testLabels);  % 直接读取所有标签，不使用并行

% 预测测试集的标签
scores = predict(trainedNet, cat(3, rxTestFrames{:}));
rxTestPred = scores2label(scores, modulationTypes);  % 将预测的分数转为标签
testAccuracy = mean(rxTestPred == rxTestLabels);  % 计算准确率
disp("Test accuracy: " + testAccuracy * 100 + "%")

% 混淆矩阵可视化
figure
cm = confusionchart(rxTestLabels, rxTestPred);
cm.Title = 'Confusion Matrix for Test Data';
cm.RowSummary = 'row-normalized';
cm.Parent.Position = [cm.Parent.Position(1:2) 950 550];  % 设置图表位置
