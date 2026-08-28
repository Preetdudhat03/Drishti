function enhancedImg = enhanceFundus(imgRGB, retinaMask, options)
% ENHANCEFUNDUS Adaptive enhancement for borderline retinal fundus images
%
% Applies:
% 1. Conversion to L*a*b* color space
% 2. Contrast-Limited Adaptive Histogram Equalization (CLAHE) on L* channel
% 3. Mild 2D Gaussian/median smoothing to suppress sensor noise
% 4. Unsharp masking to preserve delicate microvascular structures
%
% EyeXpert — SIH 2026

    arguments
        imgRGB (:,:,3) uint8
        retinaMask (:,:) logical = logical.empty
        options.ClipLimit (1,1) double = 0.015
        options.NumTiles (1,2) double = [8, 8]
        options.Denoise (1,1) logical = true
        options.SharpenStrength (1,1) double = 0.4
    end

    if isempty(retinaMask)
        gray = rgb2gray(imgRGB);
        retinaMask = gray > 15;
    end

    % 1. Convert to Lab space
    labImg = rgb2lab(imgRGB);
    L = labImg(:,:,1) / 100.0; % scale L to [0, 1]

    % 2. Apply CLAHE to L channel
    L_clahe = adapthisteq(L, ...
        'ClipLimit', options.ClipLimit, ...
        'NumTiles', options.NumTiles, ...
        'Distribution', 'uniform');

    % 3. Denoising on L channel if requested
    if options.Denoise
        L_clahe = medfilt2(L_clahe, [3 3]);
    end

    % 4. Subtle unsharp masking for vascular definition
    if options.SharpenStrength > 0
        L_sharp = imsharpen(L_clahe, ...
            'Radius', 1.0, ...
            'Amount', options.SharpenStrength);
        L_clahe = max(0, min(1, L_sharp));
    end

    % 5. Reconstruct RGB
    labImg(:,:,1) = L_clahe * 100.0;
    enhancedImg = lab2rgb(labImg, 'OutputType', 'uint8');

    % Ensure background outside retina remains clean black
    for c = 1:3
        ch = enhancedImg(:,:,c);
        ch(~retinaMask) = 0;
        enhancedImg(:,:,c) = ch;
    end
end
