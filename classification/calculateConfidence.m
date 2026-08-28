function [calibratedConf, stats] = calculateConfidence(logitsOrProbs, options)
% CALCULATECONFIDENCE Computes calibrated confidence from model output
%
% Clearly distinguishes between:
% - Raw Softmax Probability
% - Calibrated Confidence (via Temperature Scaling T=1.2)
%
% EyeXpert — SIH 2026

    arguments
        logitsOrProbs (1,:) double
        options.Temperature (1,1) double = 1.25 % Learned temperature scaling
        options.IsLogits (1,1) logical = false
    end

    if options.IsLogits
        logits = logitsOrProbs;
    else
        % Numerical stability inverse softmax (log-odds)
        probs = max(eps, min(1 - eps, logitsOrProbs));
        logits = log(probs);
    end

    % Apply temperature scaling: z_i / T
    scaledLogits = logits / options.Temperature;
    expScaled = exp(scaledLogits - max(scaledLogits));
    calibratedProbs = expScaled / sum(expScaled);

    [maxProb, predIdx] = max(calibratedProbs);
    predictedLevel = predIdx - 1;

    % Uncertainty metrics
    entropy = -sum(calibratedProbs .* log(calibratedProbs + eps)) / log(numel(calibratedProbs));
    margin = maxProb - max([calibratedProbs(1:predIdx-1), calibratedProbs(predIdx+1:end), 0]);

    stats = struct();
    stats.RawProbabilities = logitsOrProbs;
    stats.CalibratedProbabilities = calibratedProbs;
    stats.PredictedLevel = predictedLevel;
    stats.MaxProbability = max(logitsOrProbs);
    stats.CalibratedConfidence = maxProb;
    stats.NormalizedEntropy = entropy;
    stats.PredictionMargin = margin;
    stats.CalibrationMethod = "Temperature Scaling (T=" + num2str(options.Temperature) + ")";

    calibratedConf = maxProb;
end
