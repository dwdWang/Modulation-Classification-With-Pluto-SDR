function frames = helperModClassGetNNFrames(rx)
%helperModClassGetNNFrames Generate formatted frames for neural networks
%   F = helperModClassGetNNFrames(X) formats the input X, into
%   frames that can be used with the neural network designed in this
%   example, and returns the frames in the output F.
%   
%   See also ModulationClassificationWithDeepLearningExample.

%   Copyright 2019-2023 MathWorks, Inc.

framesComplex = helperModClassFrameGenerator(rx,1024,1024,32,8);

frames = permute(framesComplex, [1 3 2]);
end