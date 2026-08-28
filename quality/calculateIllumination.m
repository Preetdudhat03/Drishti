function illumination = calculateIllumination(imgRGB, retinaMask)
% CALCULATEILLUMINATION Assesses fundus exposure, brightness, and uniformity
%
% Evaluates:
% - Mean & median retinal luminance
% - Underexposure ratio (fraction of pixels < 25)
% - Overexposure ratio (fraction of pixels > 240)
% - Spatial uniformity across retinal quadrants
%
% EyeXpert — SIH 2026

    arguments
        imgRGB (:,:,3) uint8
        retinaMask (:,:) logical = true(size(imgRGB, 1), size(imgRGB, 2))
    end

    % Convert to Lab / Grayscale intensity
    grayImg = double(rgb2gray(imgRGB));

    if ~any(retinaMask(:))
        retinaMask = grayImg > 15; % fallback automatic mask
    end

    validPixels = grayImg(retinaMask);
    if isempty(validPixels)
        validPixels = grayImg(:);
    end

    meanVal = mean(validPixels);
    medianVal = median(validPixels);
    p5 = prctile(validPixels, 5);
    p95 = prctile(validPixels, 95);

    % Exposure ratios
    underExposureRatio = sum(validPixels < 25) / numel(validPixels);
    overExposureRatio = sum(validPixels > 240) / numel(validPixels);

    % Ideal mean luminance for fundus is roughly [90, 160] out of 255
    if meanVal < 45 || meanVal > 225
        scoreMean = 0.1;
    elseif meanVal < 90
        scoreMean = 0.1 + 0.9 * (meanVal - 45) / 45;
    elseif meanVal > 175
        scoreMean = 0.1 + 0.9 * (225 - meanVal) / 50;
    else
        scoreMean = 1.0;
    end

    % Penalty for excessive clipping
    clipPenalty = 1.0 - min(1.0, 2.0 * (underExposureRatio + overExposureRatio));

    % Quadrant uniformity check
    [h, w] = size(grayImg);
    midH = round(h / 2);
    midW = round(w / 2);
    q1 = grayImg(1:midH, 1:midW); m1 = retinaMask(1:midH, 1:midW);
    q2 = grayImg(1:midH, (midW+1):w); m2 = retinaMask(1:midH, (midW+1):w);
    q3 = grayImg((midH+1):h, 1:midW); m3 = retinaMask((midH+1):h, 1:midW);
    q4 = grayImg((midH+1):h, (midW+1):w); m4 = retinaMask((midH+1):h, (midW+1):w);

    qMeans = [
        mean(q1(m1)), mean(q2(m2)), ...
        mean(q3(m3)), mean(q4(m4))
    ];
    validQ = qMeans(~isnan(qMeans));
    if numel(validQ) >= 2
        uniformityCoeff = 1.0 - min(1.0, std(validQ) / (mean(validQ) + eps));
    else
        uniformityCoeff = 0.8;
    end

    normScore = 0.5 * scoreMean + 0.3 * clipPenalty + 0.2 * uniformityCoeff;
    normScore = max(0.0, min(1.0, normScore));

    illumination = struct();
    illumination.MeanIntensity = meanVal;
    illumination.MedianIntensity = medianVal;
    illumination.Percentile5 = p5;
    illumination.Percentile95 = p95;
    illumination.UnderExposureRatio = underExposureRatio;
    illumination.OverExposureRatio = overExposureRatio;
    illumination.UniformityScore = uniformityCoeff;
    illumination.NormalizedScore = normScore;
    illumination.IsAdequate = (meanVal >= 55) && (underExposureRatio < 0.35) && (overExposureRatio < 0.25);
end
