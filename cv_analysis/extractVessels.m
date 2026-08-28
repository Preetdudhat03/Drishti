function [vesselMask, vesselEnhanced] = extractVessels(imgRGB, retinaMask)
% EXTRACTVESSELS Retinal blood vessel enhancement and segmentation
%
% Note:
%   This is an exploratory Computer Vision analysis module.
%   It does NOT alter deep learning classification outputs.
%
% EyeXpert — SIH 2026

    arguments
        imgRGB (:,:,3) uint8
        retinaMask (:,:) logical = logical.empty
    end

    if isempty(retinaMask)
        gray = rgb2gray(imgRGB);
        retinaMask = gray > 15;
    end

    % Blood vessels have highest absorption in the green channel
    greenD = double(imgRGB(:,:,2)) / 255.0;

    % 1. Invert green channel (vessels become bright)
    invGreen = 1.0 - greenD;

    % 2. Morphological top-hat filtering with disc structuring element
    se = strel('disk', 8);
    topHat = imtophat(invGreen, se);

    % 3. Contrast enhancement via CLAHE
    vesselEnhanced = adapthisteq(topHat, 'ClipLimit', 0.02);

    % 4. Adaptive thresholding
    t = graythresh(vesselEnhanced(retinaMask));
    vesselMask = (vesselEnhanced > (t * 0.85)) & retinaMask;

    % 5. Morphological cleanup (remove small noise islands)
    vesselMask = bwareaopen(vesselMask, 25);
end
