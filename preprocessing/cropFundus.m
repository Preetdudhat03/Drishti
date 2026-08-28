function [croppedImg, bbox, cropMask] = cropFundus(imgRGB, retinaMask, options)
% CROPFUNDUS Automatically removes black background borders from fundus images
%
% Syntax:
%   [croppedImg, bbox, cropMask] = cropFundus(imgRGB)
%   [croppedImg, bbox, cropMask] = cropFundus(imgRGB, retinaMask, 'SquareAspect', true)
%
% Inputs:
%   imgRGB     - Input RGB fundus image (uint8)
%   retinaMask - (Optional) Logical mask of the retina
%   options    - Name-value arguments (SquareAspect, MarginFraction)
%
% Outputs:
%   croppedImg - Bounding box cropped retinal image
%   bbox       - [xMin, yMin, width, height] for spatial traceability
%   cropMask   - Corresponding cropped retinal mask
%
% EyeXpert — SIH 2026

    arguments
        imgRGB (:,:,3) uint8
        retinaMask (:,:) logical = logical.empty
        options.SquareAspect (1,1) logical = true
        options.MarginFraction (1,1) double = 0.02
    end

    [h, w, ~] = size(imgRGB);

    % 1. Derive mask if not provided
    if isempty(retinaMask)
        grayImg = rgb2gray(imgRGB);
        thresh = max(12, 0.07 * double(max(grayImg(:))));
        binMask = grayImg > thresh;
        binMask = bwareaopen(binMask, round(0.01 * h * w));
        binMask = imfill(binMask, 'holes');
        
        cc = bwconncomp(binMask);
        if cc.NumObjects > 0
            numPixels = cellfun(@numel, cc.PixelIdxList);
            [~, maxIdx] = max(numPixels);
            retinaMask = false(size(binMask));
            retinaMask(cc.PixelIdxList{maxIdx}) = true;
        else
            retinaMask = true(h, w);
        end
    end

    % 2. Find bounding box of the illuminated retina
    [rowIdx, colIdx] = find(retinaMask);
    if isempty(rowIdx)
        croppedImg = imgRGB;
        bbox = [1, 1, w, h];
        cropMask = retinaMask;
        return;
    end

    rMin = min(rowIdx);
    rMax = max(rowIdx);
    cMin = min(colIdx);
    cMax = max(colIdx);

    boxH = rMax - rMin + 1;
    boxW = cMax - cMin + 1;

    % Add slight margin
    mH = round(boxH * options.MarginFraction);
    mW = round(boxW * options.MarginFraction);

    rMin = max(1, rMin - mH);
    rMax = min(h, rMax + mH);
    cMin = max(1, cMin - mW);
    cMax = min(w, cMax + mW);

    boxH = rMax - rMin + 1;
    boxW = cMax - cMin + 1;

    % Enforce square aspect ratio if requested
    if options.SquareAspect && (boxH ~= boxW)
        maxSide = max(boxH, boxW);
        centerR = round((rMin + rMax) / 2);
        centerC = round((cMin + cMax) / 2);

        rMin = max(1, round(centerR - maxSide / 2));
        rMax = min(h, rMin + maxSide - 1);
        if (rMax - rMin + 1) < maxSide
            rMin = max(1, rMax - maxSide + 1);
        end

        cMin = max(1, round(centerC - maxSide / 2));
        cMax = min(w, cMin + maxSide - 1);
        if (cMax - cMin + 1) < maxSide
            cMin = max(1, cMax - maxSide + 1);
        end
    end

    croppedImg = imgRGB(rMin:rMax, cMin:cMax, :);
    cropMask = retinaMask(rMin:rMax, cMin:cMax);
    bbox = [cMin, rMin, (cMax - cMin + 1), (rMax - rMin + 1)];
end
