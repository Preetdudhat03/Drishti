function [processedImg, meta] = preprocessFundus(imgInput, options)
% PREPROCESSFUNDUS Retinal preprocessing pipeline for EyeXpert MVP V1
%
% Complete pipeline:
% 1. Image loading and format validation (RGB uint8)
% 2. Retinal field detection and auto-cropping
% 3. Conditional enhancement (if Quality = BORDERLINE or ForceEnhance = true)
% 4. Standardized resizing to model input dimensions (e.g. [224, 224, 3])
% 5. Scaling/normalization to model tensor format
%
% Outputs:
%   processedImg - Preprocessed image (uint8 or single tensor [0, 1])
%   meta         - Traceability struct containing original image, cropped,
%                  bounding box, and enhancement flags.
%
% EyeXpert — SIH 2026

    arguments
        imgInput
        options.TargetSize (1,2) double = [224, 224]
        options.ApplyEnhancement (1,1) logical = false
        options.ApplyIllumNorm (1,1) logical = false
        options.CropBorders (1,1) logical = true
        options.OutputType (1,1) string = "uint8" % "uint8" or "single"
    end

    % 1. Load Image
    if ischar(imgInput) || isstring(imgInput)
        rawRGB = imread(char(imgInput));
        meta.SourcePath = string(imgInput);
    else
        rawRGB = imgInput;
        meta.SourcePath = "In-memory array";
    end

    % Validate 3 channels
    if size(rawRGB, 3) == 1
        rawRGB = repmat(rawRGB, [1 1 3]);
    elseif size(rawRGB, 3) > 3
        rawRGB = rawRGB(:,:,1:3);
    end

    if ~isa(rawRGB, 'uint8')
        if max(rawRGB(:)) <= 1.0
            rawRGB = uint8(rawRGB * 255);
        else
            rawRGB = uint8(rawRGB);
        end
    end

    meta.OriginalImage = rawRGB;
    meta.OriginalSize = size(rawRGB);

    % 2. Auto-crop black borders
    if options.CropBorders
        [croppedImg, bbox, cropMask] = cropFundus(rawRGB);
        meta.CroppedImage = croppedImg;
        meta.BoundingBox = bbox;
        meta.CropMask = cropMask;
    else
        croppedImg = rawRGB;
        meta.CroppedImage = rawRGB;
        meta.BoundingBox = [1, 1, size(rawRGB, 2), size(rawRGB, 1)];
        meta.CropMask = true(size(rawRGB, 1), size(rawRGB, 2));
    end

    % 3. Illumination Normalization & Enhancement
    curImg = croppedImg;
    meta.EnhancementApplied = false;
    meta.IllumNormApplied = false;

    if options.ApplyIllumNorm
        curImg = normalizeIllumination(curImg, meta.CropMask);
        meta.IllumNormApplied = true;
    end

    if options.ApplyEnhancement
        curImg = enhanceFundus(curImg, meta.CropMask);
        meta.EnhancementApplied = true;
    end

    meta.EnhancedImage = curImg;

    % 4. Resize to target dimension
    resizedImg = imresize(curImg, options.TargetSize, 'bilinear');
    meta.ResizedImage = resizedImg;

    % 5. Convert to requested output type
    if options.OutputType == "single"
        % Normalized to [0, 1] single floating point
        processedImg = single(resizedImg) / 255.0;
    else
        processedImg = resizedImg;
    end

    meta.FinalOutputSize = size(processedImg);
    meta.Timestamp = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
end
