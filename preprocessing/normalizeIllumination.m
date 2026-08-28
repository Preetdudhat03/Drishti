function normImg = normalizeIllumination(imgRGB, retinaMask, options)
% NORMALIZEILLUMINATION Corrects non-uniform illumination and vignetting
%
% Implements Graham's fundus normalization method:
%   I_norm = alpha * I_orig + beta * G_sigma(I_orig) + gamma
%
% EyeXpert — SIH 2026

    arguments
        imgRGB (:,:,3) uint8
        retinaMask (:,:) logical = logical.empty
        options.Sigma (1,1) double = 30
        options.Alpha (1,1) double = 4.0
        options.Beta (1,1) double = -4.0
        options.Gamma (1,1) double = 128.0
    end

    if isempty(retinaMask)
        gray = rgb2gray(imgRGB);
        retinaMask = gray > 15;
    end

    imgD = double(imgRGB);
    
    % Gaussian blur background approximation
    % Using imgaussfilt for 2D Gaussian filter per channel
    bgR = imgaussfilt(imgD(:,:,1), options.Sigma);
    bgG = imgaussfilt(imgD(:,:,2), options.Sigma);
    bgB = imgaussfilt(imgD(:,:,3), options.Sigma);
    bg = cat(3, bgR, bgG, bgB);

    % Linear combination
    normD = options.Alpha * imgD + options.Beta * bg + options.Gamma;

    % Zero out non-retinal region
    for c = 1:3
        ch = normD(:,:,c);
        ch(~retinaMask) = 0;
        normD(:,:,c) = ch;
    end

    normD = max(0, min(255, normD));
    normImg = uint8(normD);
end
