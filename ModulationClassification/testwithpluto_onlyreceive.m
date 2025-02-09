clear all;
clc;
% 加载训练好的调制分类网络和调制类型
load trainedModulationClassificationNetwork trainedNet modulationTypes

% 设置每个符号的样本数，帧的样本数和采样率
sps = 8;                % 每个符号的样本数
spf = 10000;             % 每帧的样本数
fs = 8e6;               % 采样率

% 设置接收无线电
rxRadio = sdrrx('Pluto');
rxRadio.RadioID = 'usb:0';  % 根据实际情况修改为你的接收端PlutoSDR的RadioID
rxRadio.CenterFrequency = 1.8e9;  % 设置中心频率为1.8GHz
rxRadio.BasebandSampleRate = fs;  % 设置基带采样率
rxRadio.ShowAdvancedProperties = true;
rxRadio.EnableQuadratureCorrection = false;
rxRadio.GainSource = "Manual";  % 设置增益来源为手动
maximumGain = 55;  % 最大增益
minimumGain = -5;  % 最小增益

% 设置接收无线电的帧数和启用突发模式
rxRadio.SamplesPerFrame = spf;
rxRadio.EnableBurstMode = true;
rxRadio.NumFramesInBurst = 1;
rxRadio.OutputDataType = 'single';

disp('调整接收器增益')
rxRadio.Gain = maximumGain;
gainAdjusted = false;
while ~gainAdjusted
    for p=1:20
        rx = rxRadio();  % 接收信号
    end
    maxAmplitude = max([abs(real(rx)); abs(imag(rx))]);
    if (maxAmplitude < 0.8) || (rxRadio.Gain <= minimumGain)
        gainAdjusted = true;
    else
        rxRadio.Gain = rxRadio.Gain - 3;  % 减少增益
    end
end
rxRadio.Gain = rxRadio.Gain - 3;

disp('开始接收器和测试')

AllPossibleModTypes = string(["BPSK", "QPSK", "8PSK", "16QAM", "64QAM", "PAM4", "B-FM","Others","FSK"]);

try
    while true
        tic;  % 记录循环开始时间
        predictedIndices = zeros(1, 5);  % 初始化索引数组
        close all;
        
        for i = 1:5
            disp(['正在进行第 ', num2str(i), ' 次识别']);
            
            % 接收信号
            rx = rxRadio();
            
            % 标准化接收到的信号
            framePower = mean(abs(rx).^2);
            rx = rx / sqrt(framePower);
            
            % 进行分类
            scores = predict(trainedNet, rx);  % 使用训练的网络进行预测
            [predictedModType, ~] = scores2label(scores, modulationTypes, 2);  % 转换得分为标签
            disp(predictedModType);
            
            stringpredictedModType = string(predictedModType);
            % 将不在 AllPossibleModTypes 中的调制类型归类为 "Others"
            if ~ismember(stringpredictedModType, AllPossibleModTypes)
                predictedModType = "Others";
            elseif predictedModType == "B-FM"
                predictedModType = "FSK";
            end
            
            % 找到预测结果在 AllPossibleModTypes 中的索引
            index = find(strcmp(stringpredictedModType, AllPossibleModTypes));
            
            % 确保 index 是一个单一的数值
            if isempty(index)
                index = length(AllPossibleModTypes);  % "Others" 的索引
            elseif numel(index) > 1
                warning('找到多个匹配的调制类型，使用第一个匹配项');
                index = index(1);
            end
            
            predictedIndices(i) = index;
        end
        
        % 计算出现次数最多的调制方式的索引
        [values, counts] = mode(predictedIndices);
        finalIndex = values;
        
        % 获取最终的预测调制方式
        finalPredictedModType = AllPossibleModTypes(finalIndex);
        if predictedModType == "B-FM"
                predictedModType = "FSK";
        end
        % 打印预测结果
        disp(['预测的调制方式: ', char(finalPredictedModType)]);
        
        % 绘制各个类别的得分柱状图
        % figure;
        % bar(scores);
        % title('各个类别的得分');
        % ylabel('得分');
        % xticklabels(modulationTypes);  % 设置X轴标签为各个调制方式
        % xtickangle(45);  % 调整X轴标签角度，避免重叠
        % grid on;
        
        % 提取I和Q分量并绘制星座图
        % iComponent = real(rx);
        % qComponent = imag(rx);
        % 
        % figure;
        % plot(iComponent, qComponent, '.');
        % axis equal;
        % xlabel('I 分量');
        % ylabel('Q 分量');
        % title('星座图（接收+标准化）');
        % grid on;

        % 创建一个新的图形窗口
        %figure;
        
        % 绘制 iComponent 的时域图像
        %subplot(2,1,1);
        %plot(iComponent, '-o', 'MarkerFaceColor', 'r'); % 使用红色圆圈标记抽样点
        %xlabel('样本编号');
        %ylabel('幅度');
        %title('iComponent 的时域图像');
        
        % 绘制 qComponent 的时域图像
        % subplot(2,1,2);
        % plot(qComponent, '-s', 'MarkerFaceColor', 'b'); % 使用蓝色方块标记抽样点
        % xlabel('样本编号');
        % ylabel('幅度');
        % title('qComponent 的时域图像');
        
        % 调整子图间距
        %sgtitle('iComponent 和 qComponent 的时域图像');
        if (finalPredictedModType=="Others")|(finalPredictedModType=="PAM4")
            rx=rx;
        else
            rx = signalSyncAndCompensate(rx,finalPredictedModType);
        end
        % 位同步
        %[Tbigest,rx]=bitSynchronization(rx, sps, 8, 0.3, 0.1);
        

        % 截取两个数组到相同的最大长度
        % maxLength = max(length(iComponent), length(qComponent));
        % iComponent = iComponent(1:maxLength);
        % qComponent = qComponent(1:maxLength);
        % 
        % % 提取I和Q分量并绘制星座图
        % iComponent = real(rx);
        % qComponent = imag(rx);
        
        %figure;
        %plot(iComponent, qComponent, '.');
        %axis equal;
        %xlabel('I 分量');
        %ylabel('Q 分量');
        %title('星座图（接收+标准化+位同步）');
        %grid on;
        %pauseRecognitionUntilButtonClick()
        tocTime = toc;  % 计算循环已花费的时间
        disp('检测用时：（s）');
        disp(tocTime);
        pauseTime = max(5 - tocTime, 0);  % 计算需要暂停的时间
        pause(pauseTime);  % 暂停指定的时间
    end
catch ME
    if strcmp(ME.identifier, 'MATLAB:uiwait:Canceled')
        disp('用户取消了操作.');
    else
        rethrow(ME);
    end
finally
    release(rxRadio);
end


function processedSignal = signalSyncAndCompensate(rx, modulationType)
    % signalSyncAndCompensate: 实现位同步、频偏补偿、相偏补偿，并绘制星座图
    % 
    % 输入参数:
    % rx: 输入已调信号
    % modulationType: 调制类型 ('BPSK', 'QPSK', '8PSK', '16QAM', '64QAM', 'PAM4', 'FSK')
    %
    % 输出:
    % processedSignal: 经过处理后的信号

    % 参数设置
    SPS = 8; % 每符号采样点数
    interpolationFactor = 1; % 插值因子

    % 将调制类型转换为字符数组进行判断
    modulationType = char(modulationType);

    % 确定 CoarseFrequencyCompensator 和 CarrierSynchronizer 的调制类型
    switch modulationType
        case {'BPSK', 'QPSK', '8PSK'}
            modulationForComp = modulationType; % PSK 直接匹配
            interpMethod = 'zeroPadding'; % PSK 使用零频插值
        case {'16QAM', '64QAM'}
            modulationForComp = 'QAM'; % QAM 类型统一为 'QAM'
            interpMethod = 'lowpassFilter'; % QAM 使用低通滤波器插值
        case 'PAM4'
            modulationForComp = 'PAM'; % PAM 类型
            interpMethod = 'linear'; % PAM 使用线性插值
        case 'FSK'
            modulationForComp = 'FSK'; % FSK 类型
            interpMethod = 'zeroPadding'; % FSK 使用零频插值
        otherwise
            error("Unsupported modulation type: %s", modulationType);
    end

    % 1. 根据调制方式选择插值方法
    switch interpMethod
        case 'zeroPadding'
            % 对PSK和FSK信号进行零频插值
            rxInterpolated = interp(rx, interpolationFactor);
        case 'lowpassFilter'
            % 对QAM信号使用低通滤波器插值
            rxInterpolated = lowpassInterpolation(rx, interpolationFactor);
        case 'linear'
            % 对PAM信号使用线性插值
            rxInterpolated = linearInterpolation(rx, interpolationFactor);
        otherwise
            error("Unsupported interpolation method: %s", interpMethod);
    end

    % 创建一个新的 figure 并添加四个子图
    figure;
    subplot(2, 2, 1);
    plot(real(rxInterpolated), imag(rxInterpolated), 'b.');
    set(gcf, 'Color', 'w'); % 设置背景为白色
    axis equal; grid on;
    title('接收信号星座图');
    xlabel('实部'); ylabel('虚部');

    % 2. 位同步
    symbolSync = comm.SymbolSynchronizer( ...
        'TimingErrorDetector', 'Gardner (non-data-aided)', ... % 使用 Gardner 检测器
        'SamplesPerSymbol', SPS * interpolationFactor); % 每符号采样点数增加为插值后的采样数
    rxSymbolSynced = symbolSync(rxInterpolated);

    subplot(2, 2, 2);
    plot(real(rxSymbolSynced), imag(rxSymbolSynced), 'b.');
    set(gcf, 'Color', 'w'); % 设置背景为白色
    axis equal; grid on;
    title('位同步后信号星座图');
    xlabel('实部'); ylabel('虚部');

    % 3. 频偏补偿
    coarseFreqComp = comm.CoarseFrequencyCompensator( ...
        'Modulation', modulationForComp, ...
        'FrequencyResolution', 1e3);
    rxFreqCompensated = coarseFreqComp(rxSymbolSynced);

    subplot(2, 2, 3);
    plot(real(rxFreqCompensated), imag(rxFreqCompensated), 'b.');
    set(gcf, 'Color', 'w'); % 设置背景为白色
    axis equal; grid on;
    title('频偏补偿后信号星座图');
    xlabel('实部'); ylabel('虚部');

    % **4. 相偏补偿**
    carrierSync = comm.CarrierSynchronizer( ...
        'Modulation', modulationForComp, ... % 适配修改后的调制类型
        'SamplesPerSymbol', SPS * interpolationFactor, ...
        'DampingFactor', 1, ...
        'NormalizedLoopBandwidth', 0.005);
    rxCarrierSynced = carrierSync(rxFreqCompensated);

    subplot(2, 2, 4);
    plot(real(rxCarrierSynced), imag(rxCarrierSynced), 'b.');
    set(gcf, 'Color', 'w'); % 设置背景为白色
    axis equal; grid on;
    title('相偏补偿后信号星座图');
    xlabel('实部'); ylabel('虚部');

    % 返回处理后的信号
    processedSignal = rxCarrierSynced;
end

% 对QAM信号使用低通滤波器插值
function rxInterpolated = lowpassInterpolation(rx, interpolationFactor)
    % 设计低通滤波器
    fs = 8e6; % 假设采样率为1
    cutoff = 0.5; % 截止频率设置为采样频率的一半
    [b, a] = butter(6, cutoff, 'low'); % 6阶低通滤波器
    rxInterpolated = interp(rx, interpolationFactor); % 插值
    rxInterpolated = filter(b, a, rxInterpolated); % 滤波器平滑信号
end

% 对PAM信号使用线性插值
function rxInterpolated = linearInterpolation(rx, interpolationFactor)
    rxInterpolated = interp(rx, interpolationFactor, 'linear');
end
























function [Tbigest, rx_sync] = bitSynchronization(rx, sps, k, r, step)
    % 插值使rx从离散变为连续，每两个数据之间的时间间隔为0.1秒
    T = 0.1; % 时间间隔
    t_rx = (0:length(rx)-1) / sps; % 原始信号时间向量
    t_interp = 0:T/100:max(t_rx); % 插值后的时间向量
    
    % 分别对实部和虚部进行插值
    rx_real_interp = interp1(t_rx, real(rx), t_interp, 'linear'); % 实部线性插值
    rx_imag_interp = interp1(t_rx, imag(rx), t_interp, 'linear'); % 虚部线性插值
    
    % 初始化变量
    Tbigest = 0;
    max_insideR = 0;
    insideR_values = [];
    
    % 初始抽样时刻为T=0，每隔T抽样一次
    current_t = 0;
    while current_t <= T
        start_index = round(current_t * sps + 1);
        end_index = length(rx_real_interp);
        sampled_indices = start_index:sps:end_index;
        sampled_data_real = rx_real_interp(sampled_indices);
        sampled_data_imag = rx_imag_interp(sampled_indices);
        
        % 将实部和虚部组合成二维数据
        sampled_data = [sampled_data_real', sampled_data_imag'];
        
        % 聚类
        idx = kmeans(sampled_data, k);
        
        % 计算每个聚类中心的坐标
        centroids = zeros(k, 2);
        for i = 1:k
            centroids(i, :) = mean(sampled_data(idx == i, :));
        end
        
        % 统计距离聚类中心r以内的点的个数
        insideR = 0;
        for j = 1:size(sampled_data, 1)
            point = sampled_data(j, :);
            min_dist = min(sqrt(sum((point - centroids).^2, 2)));
            if min_dist <= r
                insideR = insideR + 1;
            end
        end
        
        % 记录insideR值
        insideR_values(end+1) = insideR;
        
        % 更新最大insideR和对应的Tbigest
        if insideR > max_insideR
            max_insideR = insideR;
            Tbigest = current_t;
        end
        
        % 抽样时刻后移T/step
        current_t = current_t + T/step;
    end
    
    % 以Tbigest为起始时间，T为周期进行抽样，得到新的离散序列rx_sync
    start_index = round(Tbigest * sps + 1);
    rx_sync = rx(start_index:sps:end);
    
    % 绘制原始信号的星座图
    figure;
    subplot(1, 2, 1);
    plot(real(rx), imag(rx), '.');
    title('Original Signal Constellation Diagram');
    xlabel('Real Part');
    ylabel('Imaginary Part');
    grid on;
    
    % 绘制最佳同步时刻的星座图并标出聚类中心
    subplot(1, 2, 2);
    plot(real(rx_sync), imag(rx_sync), '.', 'DisplayName', 'Sampled Points');
    hold on;
    plot(centroids(:, 1), centroids(:, 2), 'ro', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Centroids');
    legend show;
    title(['Synced Signal Constellation Diagram at T=', num2str(Tbigest)]);
    xlabel('Real Part');
    ylabel('Imaginary Part');
    grid on;
end




