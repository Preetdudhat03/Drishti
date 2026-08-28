function [overallScore, qualityStatus, breakdown] = calculateQualityScore(sharpnessScore, illumScore, fovScore, config)
% CALCULATEQUALITYSCORE Weighted fusion of quality components
%
% Syntax:
%   [overallScore, qualityStatus, breakdown] = calculateQualityScore(sScore, iScore, fScore)
%   [overallScore, qualityStatus, breakdown] = calculateQualityScore(sScore, iScore, fScore, config)
%
% Quality Status:
%   'GOOD'       - High quality, proceed directly to DR classification
%   'BORDERLINE' - Mild degradation, proceed to adaptive enhancement
%   'UNGRADABLE' - Inadequate for safe automated diagnosis, stop and recapture
%
% EyeXpert — SIH 2026

    arguments
        sharpnessScore (1,1) double
        illumScore (1,1) double
        fovScore (1,1) double
        config (1,1) struct = struct(...
            'wSharpness', 0.45, ...
            'wIllumination', 0.35, ...
            'wFOV', 0.20, ...
            'GoodThreshold', 0.70, ...
            'BorderlineThreshold', 0.45)
    end

    % Normalize weights
    totalW = config.wSharpness + config.wIllumination + config.wFOV;
    wS = config.wSharpness / totalW;
    wI = config.wIllumination / totalW;
    wF = config.wFOV / totalW;

    % Core fusion
    overallScore = wS * sharpnessScore + wI * illumScore + wF * fovScore;
    overallScore = max(0.0, min(1.0, overallScore));

    % Safety critical rule: if sharpness is extremely low (<0.20) or illumination <0.15, force UNGRADABLE
    if sharpnessScore < 0.20 || illumScore < 0.15 || fovScore < 0.15
        qualityStatus = "UNGRADABLE";
    elseif overallScore >= config.GoodThreshold
        qualityStatus = "GOOD";
    elseif overallScore >= config.BorderlineThreshold
        qualityStatus = "BORDERLINE";
    else
        qualityStatus = "UNGRADABLE";
    end

    breakdown = struct();
    breakdown.SharpnessScore = sharpnessScore;
    breakdown.IlluminationScore = illumScore;
    breakdown.FOVScore = fovScore;
    breakdown.OverallScore = overallScore;
    breakdown.QualityStatus = qualityStatus;
    breakdown.Weights = struct('wSharpness', wS, 'wIllumination', wI, 'wFOV', wF);
end
