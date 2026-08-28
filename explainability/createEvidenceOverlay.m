function [overlayImg, evidenceData] = createEvidenceOverlay(origImg, camMap, options)
% CREATEEVIDENCEOVERLAY Blends Grad-CAM heatmap with fundus photograph
%
% Syntax:
%   [overlayImg, evidenceData] = createEvidenceOverlay(origImg, camMap)
%   [overlayImg, evidenceData] = createEvidenceOverlay(origImg, camMap, 'Alpha', 0.45, 'Colormap', 'turbo')
%
% EyeXpert — SIH 2026

    arguments
        origImg (:,:,3) uint8
        camMap (:,:) double
        options.Alpha (1,1) double = 0.45
        options.Colormap (1,1) string = "turbo"
        options.ThresholdHighActivation (1,1) double = 0.65
    end

    [h, w, ~] = size(origImg);

    % 1. Resize heatmap to match original fundus image dimensions
    if size(camMap, 1) ~= h || size(camMap, 2) ~= w
        resizedCAM = imresize(camMap, [h, w], 'bilinear');
    else
        resizedCAM = camMap;
    end

    resizedCAM = max(0, min(1, resizedCAM));

    % 2. Generate Colormap RGB representation
    numColors = 256;
    if options.Colormap == "turbo"
        cmap = turbo(numColors);
    elseif options.Colormap == "jet"
        cmap = jet(numColors);
    elseif options.Colormap == "hot"
        cmap = hot(numColors);
    else
        cmap = parula(numColors);
    end

    camIndexed = round(resizedCAM * (numColors - 1)) + 1;
    rgbCAM = ind2rgb(camIndexed, cmap);
    rgbCAM = uint8(rgbCAM * 255);

    % 3. Alpha Blending
    origD = double(origImg);
    camD = double(rgbCAM);
    alphaMask = options.Alpha * repmat(resizedCAM, [1 1 3]);

    blendedD = (1.0 - alphaMask) .* origD + alphaMask .* camD;
    overlayImg = uint8(max(0, min(255, blendedD)));

    % 4. Identify high-attention bounding boxes
    highAttMask = resizedCAM >= options.ThresholdHighActivation;
    highAttMask = bwareaopen(highAttMask, round(0.002 * h * w));
    cc = bwconncomp(highAttMask);
    props = regionprops(cc, 'BoundingBox', 'Area', 'Centroid');

    evidenceData = struct();
    evidenceData.CandidateRegions = props;
    evidenceData.NumCandidateRegions = numel(props);
    evidenceData.PeakActivation = max(resizedCAM(:));
    evidenceData.MeanActivation = mean(resizedCAM(:));
    evidenceData.HighActivationAreaRatio = sum(highAttMask(:)) / (h * w);
    evidenceData.ClinicalNotice = "Model attention concentrated in highlighted retinal regions. Interpretability tool — not a definitive lesion diagnosis.";
end
