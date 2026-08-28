function sharpness = calculateSharpness(imgRGB, retinaMask)
% CALCULATESHARPNESS Computes retinal sharpness using Laplacian variance
%
% Syntax:
%   sharpness = calculateSharpness(imgRGB)
%   sharpness = calculateSharpness(imgRGB, retinaMask)
%
% Returns:
%   sharpness.RawLaplacianVar - Variance of Laplacian on green channel
%   sharpness.NormalizedScore - Normalized sharpness score [0, 1]
%   sharpness.IsSharpEnough   - Boolean flag against prototype threshold
%
% EyeXpert — SIH 2026

    arguments
        imgRGB (:,:,3) uint8
        retinaMask (:,:) logical = true(size(imgRGB, 1), size(imgRGB, 2))
    end

    % Retinal blood vessels and lesions have highest contrast in the Green channel
    greenChannel = double(imgRGB(:,:,2)) / 255.0;

    % Laplacian filter kernel (3x3 second-order derivative)
    lapKernel = [0, 1, 0; 1, -4, 1; 0, 1, 0];
    lapImg = imfilter(greenChannel, lapKernel, 'replicate', 'same');

    % Compute variance within valid retinal area
    if any(retinaMask(:))
        validLap = lapImg(retinaMask);
    else
        validLap = lapImg(:);
    end

    rawVar = var(validLap);

    % Sigmoidal / non-linear normalization to [0, 1]
    % Typical sharp fundus has Laplacian variance >= 0.0008 (on [0,1] scale)
    % Severe blur drops to < 0.00015
    k = 3500; % Scaling slope
    t0 = 0.00040; % Midpoint inflection threshold
    normalizedScore = 1.0 / (1.0 + exp(-k * (rawVar - t0)));
    normalizedScore = max(0.0, min(1.0, normalizedScore));

    sharpness = struct();
    sharpness.RawLaplacianVar = rawVar;
    sharpness.NormalizedScore = normalizedScore;
    sharpness.BlurThreshold = t0;
    sharpness.IsSharp = normalizedScore >= 0.50;
end
