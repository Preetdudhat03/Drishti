function [predictionResult, isUsable] = classifyDR(imgInput, net, options)
% CLASSIFYDR Predicts DR Severity Level (0-4) and Referable status
%
% Complete Inference Workflow:
% 1. Quality Assessment Gate
% 2. Image Enhancement (if Borderline)
% 3. Preprocessing (Crop, Standardize, Resize to 224x224x3)
% 4. Deep Learning Inference (ResNet Softmax output)
% 5. Referable DR mapping (Level >= 2 -> YES, Level < 2 -> NO)
% 6. Calibrated Confidence calculation
%
% Outputs:
%   predictionResult - Comprehensive screening struct
%   isUsable         - Boolean indicating whether image passed quality gate
%
% EyeXpert — SIH 2026

    arguments
        imgInput
        net = []
        options.ModelPath (1,1) string = fullfile(fileparts(mfilename('fullpath')), '..', 'model', 'drModel.mat')
        options.AutoEnhanceBorderline (1,1) logical = true
        options.GoodThreshold (1,1) double = 0.70
        options.BorderlineThreshold (1,1) double = 0.45
    end

    % Initialize result structure
    predictionResult = struct();
    predictionResult.Timestamp = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    predictionResult.Status = "FAILED";
    predictionResult.IsGradable = false;
    predictionResult.PredictedLevel = -1;
    predictionResult.SeverityText = "Evaluation Incomplete";
    predictionResult.IsReferable = false;
    predictionResult.ReferableText = "UNCONFIRMED";
    predictionResult.ClassProbabilities = zeros(1, 5);
    predictionResult.ModelProbability = 0.0;
    predictionResult.CalibratedConfidence = 0.0;
    predictionResult.ClinicalRecommendation = "Recapture or manual review required.";
    predictionResult.ClinicalFindings = "None";
    predictionResult.EnhancementApplied = false;

    % 1. Quality Assessment Gate
    qualityReport = assessImageQuality(imgInput, ...
        'GoodThreshold', options.GoodThreshold, ...
        'BorderlineThreshold', options.BorderlineThreshold);

    predictionResult.Quality = qualityReport;

    if qualityReport.Status == "UNGRADABLE"
        predictionResult.Status = "REJECTED_UNGRADABLE";
        predictionResult.IsGradable = false;
        predictionResult.ClinicalRecommendation = "Image quality is ungradable. Please recapture according to feedback instructions.";
        predictionResult.RecaptureFeedback = qualityReport.RecaptureFeedback;
        isUsable = false;
        return;
    end

    % 2. Preprocess Fundus (Crop + Enhance if Borderline)
    applyEnhance = (qualityReport.Status == "BORDERLINE") && options.AutoEnhanceBorderline;
    [preprocessedImg, prepMeta] = preprocessFundus(imgInput, ...
        'ApplyEnhancement', applyEnhance, ...
        'TargetSize', [224, 224]);

    predictionResult.Preprocessing = prepMeta;
    predictionResult.EnhancementApplied = applyEnhance;

    % 3. Load Network if not provided
    if isempty(net)
        try
            [net, ~] = loadDRModel(options.ModelPath);
        catch ME
            predictionResult.Status = "ERROR_MODEL_LOAD";
            predictionResult.ErrorMessage = "Model load failure: " + string(ME.message);
            isUsable = false;
            return;
        end
    end

    % 4. Deep Learning Inference
    try
        % Predict softmax probabilities
        probs = predict(net, preprocessedImg);
        probs = double(probs(:)');

        if numel(probs) ~= 5
            error('EyeXpert:InvalidOutputSize', 'Expected 5 class probabilities, got %d', numel(probs));
        end

        % Normalization check
        probs = probs / sum(probs);

        [maxP, maxIdx] = max(probs);
        predLevel = maxIdx - 1;

        predictionResult.ClassProbabilities = probs;
        predictionResult.PredictedLevel = predLevel;
        predictionResult.ModelProbability = maxP;

        % Calibrated confidence estimation
        [calibratedConf, confStats] = calculateConfidence(probs);
        predictionResult.CalibratedConfidence = calibratedConf;
        predictionResult.ConfidenceStats = confStats;

        % 5. Referable DR Determination
        [isRef, sevText, recText, clinInfo] = determineReferableDR(predLevel);
        predictionResult.IsReferable = isRef;
        if isRef
            predictionResult.ReferableText = "YES (Referral Indicated)";
        else
            predictionResult.ReferableText = "NO (Non-Referable)";
        end
        predictionResult.SeverityText = sevText;
        predictionResult.ClinicalRecommendation = recText;
        predictionResult.ClinicalFindings = clinInfo.ClinicalFindings;
        predictionResult.ClinicalInfo = clinInfo;

        predictionResult.Status = "SUCCESS";
        predictionResult.IsGradable = true;
        isUsable = true;

    catch ME
        predictionResult.Status = "ERROR_INFERENCE";
        predictionResult.ErrorMessage = "Inference execution error: " + string(ME.message);
        isUsable = false;
    end
end
