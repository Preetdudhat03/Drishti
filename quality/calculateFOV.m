function fov = calculateFOV(imgRGB)
% CALCULATEFOV Estimates retinal field of view and coverage
%
% Determines:
% - Retinal circular mask segmentation
% - Retinal area fraction relative to image frame
% - Centering and edge truncation of the fundus disc
%
% EyeXpert — SIH 2026

    arguments
        imgRGB (:,:,3) uint8
    end

    grayImg = double(rgb2gray(imgRGB));
    [h, w] = size(grayImg);
    totalPixels = h * w;

    % Retinal thresholding: fundus disc is typically > 18-25 luminance
    thresh = max(15, 0.08 * double(max(grayImg(:))));
    binMask = grayImg > thresh;

    % Morphological cleaning to fill vessels/holes and remove border artifacts
    binMask = bwareaopen(binMask, round(0.01 * totalPixels));
    binMask = imfill(binMask, 'holes');

    % Keep largest connected component (the retinal disc)
    cc = bwconncomp(binMask);
    if cc.NumObjects > 0
        numPixels = cellfun(@numel, cc.PixelIdxList);
        [~, maxIdx] = max(numPixels);
        retinaMask = false(size(binMask));
        retinaMask(cc.PixelIdxList{maxIdx}) = true;
    else
        retinaMask = false(size(binMask));
    end

    retinaArea = sum(retinaMask(:));
    coverageFraction = retinaArea / totalPixels;

    % Check if disc is severely truncated by checking perimeter border touches
    borderPixels = [
        retinaMask(1, :), ...
        retinaMask(end, :), ...
        retinaMask(:, 1)', ...
        retinaMask(:, end)'
    ];
    borderContactRatio = sum(borderPixels) / numel(borderPixels);

    % Score calculation
    % Ideal circular fundus in typical capture covers ~40% to 75% of frame
    if coverageFraction < 0.15
        coverageScore = 0.1;
    elseif coverageFraction < 0.35
        coverageScore = 0.1 + 0.9 * (coverageFraction - 0.15) / 0.20;
    else
        coverageScore = 1.0;
    end

    truncationPenalty = max(0, 1.0 - 1.5 * borderContactRatio);
    normScore = 0.7 * coverageScore + 0.3 * truncationPenalty;
    normScore = max(0.0, min(1.0, normScore));

    fov = struct();
    fov.RetinaMask = retinaMask;
    fov.CoverageFraction = coverageFraction;
    fov.BorderContactRatio = borderContactRatio;
    fov.NormalizedScore = normScore;
    fov.IsAdequate = (coverageFraction >= 0.20) && (borderContactRatio < 0.40);
end
