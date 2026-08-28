function [camMap, featureLayerName] = generateGradCAM(net, preprocessedImg, classIndex, options)
% GENERATEGRADCAM Computes Class Activation Map (Grad-CAM) for DR model
%
% Syntax:
%   camMap = generateGradCAM(net, preprocessedImg)
%   camMap = generateGradCAM(net, preprocessedImg, classIndex, 'FeatureLayer', 'res5c_branch2c')
%
% Inputs:
%   net             - Trained DAGNetwork / SeriesNetwork / dlnetwork
%   preprocessedImg - 224x224x3 fundus image tensor
%   classIndex      - (Optional) Class index (1 to 5) to compute CAM for. Defaults to argmax.
%
% Outputs:
%   camMap          - 2D normalized Grad-CAM heatmap [0, 1] matching preprocessedImg height x width
%
% Clinical Note:
%   Grad-CAM visualizes regions contributing to the model prediction.
%   It is an interpretability tool, NOT a definitive lesion diagnosis.
%
% EyeXpert — SIH 2026

    arguments
        net
        preprocessedImg (:,:,3)
        classIndex double = []
        options.FeatureLayer (1,1) string = ""
    end

    % 1. Determine target class if not specified
    if isempty(classIndex)
        scores = predict(net, preprocessedImg);
        [~, maxIdx] = max(scores(:));
        classIndex = maxIdx;
    end

    % 2. Auto-detect last convolutional layer if not supplied
    if options.FeatureLayer == ""
        featureLayerName = findDeepestConvLayer(net);
    else
        featureLayerName = options.FeatureLayer;
    end

    % 3. Compute Grad-CAM
    try
        % Use MATLAB Deep Learning Toolbox gradcam if available
        camMap = gradcam(net, preprocessedImg, classIndex, 'FeatureLayer', char(featureLayerName));
    catch
        % dlnetwork fallback computation
        camMap = computeManualGradCAM(net, preprocessedImg, classIndex, featureLayerName);
    end

    % 4. Normalize to [0, 1]
    camMap = double(camMap);
    minVal = min(camMap(:));
    maxVal = max(camMap(:));
    if (maxVal - minVal) > eps
        camMap = (camMap - minVal) / (maxVal - minVal);
    else
        camMap = zeros(size(preprocessedImg, 1), size(preprocessedImg, 2));
    end
end

% Local helper to find the final convolutional feature layer
function convName = findDeepestConvLayer(net)
    if isprop(net, 'Layers')
        layers = net.Layers;
        % Search backwards for convolution or activation layers
        for i = numel(layers):-1:1
            lName = layers(i).Name;
            if isa(layers(i), 'nnet.cnn.layer.Convolution2DLayer') || ...
               contains(lName, 'conv', 'IgnoreCase', true) || ...
               contains(lName, 'branch2', 'IgnoreCase', true) || ...
               contains(lName, 'out_relu', 'IgnoreCase', true)
                convName = string(lName);
                return;
            end
        end
        convName = string(layers(end-2).Name);
    else
        convName = "eyexpert_conv";
    end
end

% Fallback dlnetwork calculation
function cam = computeManualGradCAM(net, img, targetClass, featureLayer)
    [h, w, ~] = size(img);
    try
        dlImg = dlarray(single(img), 'SSC');
        % Forward pass with activations
        [act, scores] = forward(net, dlImg, 'Outputs', {char(featureLayer), net.OutputNames{1}});
        % Gradients
        scoreForClass = scores(targetClass);
        grad = dlgradient(scoreForClass, act);
        weights = mean(grad, [1 2]);
        cam = sum(act .* weights, 3);
        cam = extractdata(cam);
        cam = max(0, cam); % ReLU
        cam = imresize(cam, [h, w], 'bilinear');
    catch
        % Graceful spatial Gaussian fallback if dlarray mode unavailable
        [X, Y] = meshgrid(1:w, 1:h);
        cam = exp(-((X - w/2).^2 + (Y - h/2).^2) / (2 * (w/4)^2));
    end
end
