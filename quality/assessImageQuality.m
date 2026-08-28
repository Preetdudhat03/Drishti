function qualityReport = assessImageQuality(imgInput, options)
% ASSESSIMAGEQUALITY Master entrypoint for retinal image quality gating
%
% Syntax:
%   qualityReport = assessImageQuality(imgInput)
%   qualityReport = assessImageQuality(imgInput, 'BlurThreshold', 0.5, 'GoodThreshold', 0.70)
%
% Inputs:
%   imgInput - RGB image array (uint8) or filepath string
%
% Outputs:
%   qualityReport:
%     .Status              - 'GOOD' | 'BORDERLINE' | 'UNGRADABLE'
%     .OverallScore        - Normalized score [0.0 - 1.0]
%     .Sharpness           - Sharpness struct with Laplacian variance & score
%     .Illumination        - Illumination struct with mean & percentile stats
%     .FOV                 - Retinal field of view struct & segmentation mask
%     .RecaptureFeedback   - Actionable user instructions if borderline/ungradable
%     .IsScreeningAllowed  - Logical boolean (true for GOOD and enhanced BORDERLINE)
%
% EyeXpert — SIH 2026

    arguments
        imgInput
        options.GoodThreshold (1,1) double = 0.70
        options.BorderlineThreshold (1,1) double = 0.45
        options.wSharpness (1,1) double = 0.45
        options.wIllumination (1,1) double = 0.35
        options.wFOV (1,1) double = 0.20
    end

    qualityReport = struct();
    qualityReport.Timestamp = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    qualityReport.Status = "UNGRADABLE";
    qualityReport.OverallScore = 0.0;
    qualityReport.RecaptureFeedback = string.empty;
    qualityReport.IsScreeningAllowed = false;

    % 1. Load image if string path provided
    if ischar(imgInput) || isstring(imgInput)
        imgPath = string(imgInput);
        if ~isfile(imgPath)
            qualityReport.Status = "UNGRADABLE";
            qualityReport.RecaptureFeedback = "Error: Image file does not exist on disk.";
            return;
        end
        try
            imgRGB = imread(imgPath);
        catch ME
            qualityReport.Status = "UNGRADABLE";
            qualityReport.RecaptureFeedback = "Error: Failed to read image file: " + string(ME.message);
            return;
        end
    else
        imgRGB = imgInput;
    end

    % 2. Ensure 3-channel RGB uint8
    if size(imgRGB, 3) == 1
        imgRGB = repmat(imgRGB, [1 1 3]);
    elseif size(imgRGB, 3) > 3
        imgRGB = imgRGB(:,:,1:3);
    end

    if ~isa(imgRGB, 'uint8')
        if max(imgRGB(:)) <= 1.0
            imgRGB = uint8(imgRGB * 255);
        else
            imgRGB = uint8(imgRGB);
        end
    end

    % 3. Calculate Field of View & Retinal Mask
    fovResult = calculateFOV(imgRGB);
    qualityReport.FOV = fovResult;

    % 4. Calculate Sharpness on retinal mask
    sharpResult = calculateSharpness(imgRGB, fovResult.RetinaMask);
    qualityReport.Sharpness = sharpResult;

    % 5. Calculate Illumination & Exposure
    illumResult = calculateIllumination(imgRGB, fovResult.RetinaMask);
    qualityReport.Illumination = illumResult;

    % 6. Overall Quality Score Fusion
    cfg = struct(...
        'wSharpness', options.wSharpness, ...
        'wIllumination', options.wIllumination, ...
        'wFOV', options.wFOV, ...
        'GoodThreshold', options.GoodThreshold, ...
        'BorderlineThreshold', options.BorderlineThreshold);

    [overallScore, status, breakdown] = calculateQualityScore(...
        sharpResult.NormalizedScore, ...
        illumResult.NormalizedScore, ...
        fovResult.NormalizedScore, ...
        cfg);

    qualityReport.OverallScore = overallScore;
    qualityReport.Status = status;
    qualityReport.Breakdown = breakdown;

    % 7. Generate Actionable Recapture Feedback
    feedbackItems = strings(0, 1);

    if sharpResult.NormalizedScore < 0.45
        feedbackItems(end+1) = "Retinal image appears blurred. Please stabilize camera focus and patient head position."; %#ok<AGROW>
    end

    if illumResult.MeanIntensity < 55 || illumResult.UnderExposureRatio > 0.30
        feedbackItems(end+1) = "Image is underexposed/too dark. Please increase illumination or adjust flash intensity."; %#ok<AGROW>
    elseif illumResult.MeanIntensity > 200 || illumResult.OverExposureRatio > 0.20
        feedbackItems(end+1) = "Image is overexposed/saturated. Please reduce flash intensity or adjust aperture."; %#ok<AGROW>
    end

    if fovResult.CoverageFraction < 0.25 || fovResult.BorderContactRatio > 0.35
        feedbackItems(end+1) = "Insufficient retinal field detected. Please center the optic disc and macula within the frame."; %#ok<AGROW>
    end

    if isempty(feedbackItems)
        if status == "GOOD"
            feedbackItems(end+1) = "Image quality is optimal for automated DR screening.";
        elseif status == "BORDERLINE"
            feedbackItems(end+1) = "Image is borderline acceptable. Adaptive enhancement (CLAHE/illumination normalization) will be applied.";
        else
            feedbackItems(end+1) = "Image quality is insufficient for reliable screening. Recapture required.";
        end
    end

    qualityReport.RecaptureFeedback = feedbackItems;
    qualityReport.IsScreeningAllowed = (status == "GOOD" || status == "BORDERLINE");
end
