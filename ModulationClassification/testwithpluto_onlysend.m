close all;

% 定义所有可用的调制类型，转换为普通的字符串数组
modulationTypesToTest = string(["BPSK", "QPSK", "8PSK", ...
  "16QAM", "64QAM", "PAM4"]);

% 设置每个符号的样本数，帧的样本数和采样率
sps = 8;                % 每个符号的样本数
spf = 10000;             % 每帧的样本数
fs = 8e6;               % 采样率

% 设置发送无线电
txRadio = sdrtx('Pluto');
txRadio.RadioID = 'usb:0';  % 根据实际情况修改为你的发送端PlutoSDR的RadioID
txRadio.CenterFrequency = 1.8e9;  % 设置中心频率为1.8GHz
txRadio.BasebandSampleRate = fs;  % 设置基带采样率

% 设置随机数生成器为已知状态，确保每次仿真运行时生成相同的帧
rng(1235)

% 声明全局变量
global isRunning

% 初始化变量
isRunning = true;

% 创建图形用户界面
hFig = figure('Name', '发送控制器', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.3 0.3 0.4 0.4]);
hButton = uicontrol(hFig, 'Style', 'pushbutton', 'String', '暂停切换（但不停止发送）', 'Units', 'normalized', 'Position', [0.3 0.7 0.4 0.2], ...
                    'Callback', @(src, event) stopTransmission(src, event),'FontSize',14);
hLabel = uicontrol(hFig, 'Style', 'text', 'String', '当前调制方式:', 'Units', 'normalized', 'Position', [0.1 0.3 0.8 0.2], ...
                   'HorizontalAlignment', 'center','FontSize',18);

try
    currentModTypeIndex = 2;
    while isRunning
        % 获取所选择的调制方式
        selectedModType = modulationTypesToTest(currentModTypeIndex);
        
        % 更新标签显示当前调制方式
        set(hLabel, 'String', ['当前调制方式: ', char(selectedModType)]);
        
        disp(['开始发送:', char(selectedModType)])
        
        % 获取数据源和调制器
        dataSrc = helperModClassGetSource(selectedModType, sps, 2*spf, fs);
        modulator = helperModClassGetModulator(selectedModType, sps, fs);
        
        x = dataSrc();  % 获取输入数据
        y = modulator(x);  % 调制信号
        % 移除滤波器的过渡效应
        y = y(4*sps+1:end,1);
        maxVal = max(max(abs(real(y))), max(abs(imag(y))));
        y = y *0.8/maxVal;  % 归一化信号
        
        % 发送信号
        transmitRepeat(txRadio, complex(y));  % 发送信号
        
        % 等待5秒
        pause(5);
        
        % 切换到下一个调制方式
        if currentModTypeIndex < 6
            currentModTypeIndex = currentModTypeIndex + 1;
        else 
            currentModTypeIndex = 1;
        end
    end
catch ME
    if strcmp(ME.identifier, 'MATLAB:uiwait:Canceled')
        disp('用户取消了操作.');
    else
        rethrow(ME);
    end
finally
    release(txRadio);
    delete(hFig);
end

function stopTransmission(src, event)
    global isRunning
    isRunning = false;
    src.String = '已经暂停切换';
end



