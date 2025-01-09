function testAccuracy = helperModClassSDRTest(~)
%这个函数我改成一个脚本了，不用管

modulationTypesToTest = categorical(["BPSK", "QPSK", "8PSK", ...
  "16QAM", "64QAM", "PAM4", "GFSK", "CPFSK", "B-FM"]);
load trainedModulationClassificationNetwork trainedNet modulationTypes
numFramesPerModType = 100;

sps = 8;                % Samples per symbol
spf = 1024;             % Samples per frame
fs = 200e3;             % Sample rate

txRadio = sdrtx('Pluto');
txRadio.RadioID = 'usb:0';
txRadio.CenterFrequency = 902e6;
txRadio.BasebandSampleRate = fs;


  rxRadio = sdrrx('Pluto');
  rxRadio.RadioID = 'usb:1';
  rxRadio.CenterFrequency = 902e6;
  rxRadio.BasebandSampleRate = fs;
  rxRadio.ShowAdvancedProperties = true;
  rxRadio.EnableQuadratureCorrection = false;
  rxRadio.GainSource = "Manual";
  maximumGain = 55;
  minimumGain = -5;
% Use burst mode with numFramesInBurst set to 1, so that each capture 
% (call to the receiver) will return an independent fresh frame even 
% though the radio overruns.
rxRadio.SamplesPerFrame = spf;
rxRadio.EnableBurstMode = true;
rxRadio.NumFramesInBurst = 1;
rxRadio.OutputDataType = 'single';

% Display Tx and Rx radios
txRadio %#ok<NOPRT>
rxRadio %#ok<NOPRT>

% Set random number generator to a known state to be able to regenerate
% the same frames every time the simulation is run
rng(1235)
tic

numModulationTypes = length(modulationTypesToTest);
txModType = repmat(modulationTypesToTest(1),numModulationTypes*numFramesPerModType,1);
estimatedModType = repmat(modulationTypesToTest(1),numModulationTypes*numFramesPerModType,1);
frameCnt = 1;
for modType = 1:numModulationTypes
  elapsedTime = seconds(toc);
  elapsedTime.Format = 'hh:mm:ss';
  fprintf('%s - Testing %s frames\n', ...
    elapsedTime, modulationTypesToTest(modType))
  dataSrc = helperModClassGetSource(modulationTypesToTest(modType), sps, 2*spf, fs);
  modulator = helperModClassGetModulator(modulationTypesToTest(modType), sps, fs);
  
    % Digital modulation types use a center frequency of 902 MHz
    txRadio.CenterFrequency = 902e6;
    rxRadio.CenterFrequency = 902e6;
  
  disp('Starting transmitter')
  x = dataSrc();
  y = modulator(x);
  % Remove filter transients
  y = y(4*sps+1:end,1);
  maxVal = max(max(abs(real(y))), max(abs(imag(y))));
  y = y *0.8/maxVal;
  % Download waveform signal to radio and repeatedly transmit it over the air
  transmitRepeat(txRadio, complex(y));
  
  disp('Adjusting receiver gain')
  rxRadio.Gain = maximumGain;
  gainAdjusted = false;
  while ~gainAdjusted
    for p=1:20
      rx = rxRadio();
    end
    maxAmplitude = max([abs(real(rx)); abs(imag(rx))]);
    if (maxAmplitude < 0.8) || (rxRadio.Gain <= minimumGain)
      gainAdjusted = true;
    else
      rxRadio.Gain = rxRadio.Gain - 3;
    end
  end
  
  disp('Starting receiver and test')
  for p=1:numFramesPerModType
    rx = rxRadio();
    
    framePower = mean(abs(rx).^2);
    rx = rx / sqrt(framePower);
    
    % Classify
    txModType(frameCnt) = modulationTypesToTest(modType);
    scores = predict(trainedNet,rx);
    estimatedModType(frameCnt) = scores2label(scores,modulationTypes,2);
    
    frameCnt = frameCnt + 1;
    
    % Pause for some time to get an independent channel. The pause duration 
    % together with the processing time of a single loop must be greater 
    % than the channel coherence time. Assume channel coherence time is less 
    % than 0.35 seconds.
    pause(0.35)
  end
  disp('Releasing Tx radio')
  release(txRadio);
  testAccuracy = mean(txModType(1:frameCnt-1) == estimatedModType(1:frameCnt-1));
  disp("Test accuracy: " + testAccuracy*100 + "%")
end
disp('Releasing Rx radio')
release(rxRadio);
testAccuracy = mean(txModType == estimatedModType);
disp("Final test accuracy: " + testAccuracy*100 + "%")

figure
cm = confusionchart(txModType, estimatedModType);
cm.Title = 'Confusion Matrix for Test Data';
cm.RowSummary = 'row-normalized';
cm.Parent.Position = [cm.Parent.Position(1:2) 740 424];
end