function [net, modelInfo] = loadDRModel(modelPath)
% LOADDRMODEL Loads the trained EyeXpert Diabetic Retinopathy ResNet Model
%
% Syntax:
%   [net, modelInfo] = loadDRModel()
%   [net, modelInfo] = loadDRModel(customModelPath)
%
% Returns:
%   net       - Trained DAGNetwork / dlnetwork / SeriesNetwork
%   modelInfo - Metadata struct with architecture, training date, input size, classes
%
% EyeXpert — SIH 2026

    arguments
        modelPath (1,1) string = fullfile(fileparts(mfilename('fullpath')), 'drModel.mat')
    end

    if ~isfile(modelPath)
        error('EyeXpert:ModelNotFound', ...
            ['Trained DR model file not found at: %s\n' ...
             'Please run trainDRModel.m on the APTOS dataset to produce drModel.mat.'], ...
            modelPath);
    end

    fprintf('Loading EyeXpert DR classification model from: %s ...\n', modelPath);
    loadedData = load(modelPath);

    if isfield(loadedData, 'net')
        net = loadedData.net;
    elseif isfield(loadedData, 'trainedNet')
        net = loadedData.trainedNet;
    elseif isfield(loadedData, 'drModel')
        net = loadedData.drModel;
    else
        error('EyeXpert:InvalidModelFile', 'Model file does not contain a recognized network variable (net/trainedNet/drModel).');
    end

    if isfield(loadedData, 'modelInfo')
        modelInfo = loadedData.modelInfo;
    else
        modelInfo = struct();
        modelInfo.Architecture = "ResNet Transfer Learning";
        modelInfo.InputSize = [224, 224, 3];
        modelInfo.NumClasses = 5;
        modelInfo.ClassNames = ["Level 0", "Level 1", "Level 2", "Level 3", "Level 4"];
        modelInfo.LoadedFrom = modelPath;
    end

    fprintf('Successfully loaded %s model (%d classes).\n', modelInfo.Architecture, modelInfo.NumClasses);
end
