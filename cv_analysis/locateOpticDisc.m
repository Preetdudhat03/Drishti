function [discCenter, discRadius, discMask] = locateOpticDisc(imgRGB, retinaMask)
% LOCATEOPTICDISC Detects candidate optic disc location in fundus image
%
% Note:
%   Computer Vision exploratory localization.
%   Provides anatomical reference for clinical decision support.
%
% EyeXpert — SIH 2026

    arguments
        imgRGB (:,:,3) uint8
        retinaMask (:,:) logical = logical.empty
    end

    [h, w, ~] = size(imgRGB);

    if isempty(retinaMask)
        gray = rgb2gray(imgRGB);
        retinaMask = gray > 15;
    end

    % Optic disc is brightest in Red channel with high local intensity
    redD = double(imgRGB(:,:,1)) / 255.0;

    % Gaussian smoothing to remove small bright exudates
    smoothRed = imgaussfilt(redD, 12);
    smoothRed(~retinaMask) = 0;

    % Find peak regional intensity
    [~, maxIdx] = max(smoothRed(:));
    [cY, cX] = ind2sub([h, w], maxIdx);

    % Estimated diameter is roughly 1/12 to 1/16 of image height
    rEst = round(h / 14);

    [X, Y] = meshgrid(1:w, 1:h);
    discMask = ((X - cX).^2 + (Y - cY).^2) <= rEst^2;

    discCenter = [cX, cY];
    discRadius = rEst;
end
