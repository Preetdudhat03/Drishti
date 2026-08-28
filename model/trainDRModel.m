function [trainedNet, trainInfo] = trainDRModel(trainCsvPath, valCsvPath, options)
% TRAINDRMODEL Fine-tunes ResNet transfer learning architecture on APTOS dataset
%
% Syntax:
%   [trainedNet, trainInfo] = trainDRModel()
%   [trainedNet, trainInfo] = trainDRModel(trainCsv, valCsv, 'MaxEpochs', 15, 'BaseLR', 1e-4)
%
% EyeXpert — SIH 2026

    arguments
        trainCsvPath (1,1) string = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'splits', 'train_split.csv')
        valCsvPath (1,1) string = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'splits', 'val_split.csv')
        options.Architecture (1,1) string = "resnet18"
        options.MaxEpochs (1,1) double = 12
        options.MiniBatchSize (1,1) double = 32
        options.BaseLR (1,1) double = 1e-4
        options.WeightDecay (1,1) double = 1e-4
        options.ModelSavePath (1,1) string = fullfile(fileparts(mfilename('fullpath')), 'drModel.mat')
        options.ExecutionEnvironment (1,1) string = "auto"
    end

    fprintf('=====================================================\n');
    fprintf('           EYEXPERT DR MODEL TRAINING PIPELINE        \n');
    fprintf('=====================================================\n');

    if ~isfile(trainCsvPath) || ~isfile(valCsvPath)
        error('EyeXpert:SplitNotFound', ...
            ['Split CSV files not found. Run prepareDataset.m first:\n' ...
             '  prepareDataset(dataDir, csvPath);']);
    end

    trainTable = readtable(trainCsvPath, 'TextType', 'string');
    valTable = readtable(valCsvPath, 'TextType', 'string');

    fprintf('Training Samples:   %d\n', height(trainTable));
    fprintf('Validation Samples: %d\n', height(valTable));

    % Convert diagnosis to categorical labels (Level_0 to Level_4)
    classLabels = categorical(["Level 0"; "Level 1"; "Level 2"; "Level 3"; "Level 4"]);
    trainLabels = categorical("Level " + string(trainTable.diagnosis_clean), categories(classLabels));
    valLabels = categorical("Level " + string(valTable.diagnosis_clean), categories(classLabels));

    % Calculate inverse frequency class weights to combat severe class imbalance
    uniqueCategories = categories(classLabels);
    numClasses = numel(uniqueCategories);
    counts = countcats(trainLabels);
    totalSamples = sum(counts);
    classWeights = totalSamples ./ (numClasses * max(1, counts));
    classWeights = classWeights / mean(classWeights); % Normalize mean to 1.0

    fprintf('Computed Class Weights for Imbalance Compensation:\n');
    for c = 1:numClasses
        fprintf('  %s: weight = %.3f (n=%d)\n', uniqueCategories{c}, classWeights(c), counts(c));
    end

    % 1. Create Image Datastores with on-the-fly preprocessing
    inputSize = [224, 224, 3];
    trainImds = imageDatastore(trainTable.ImagePath, 'Labels', trainLabels);
    valImds = imageDatastore(valTable.ImagePath, 'Labels', valLabels);

    % 2. Safe Retinal Data Augmentation
    imageAugmenter = imageDataAugmenter(...
        'RandRotation', [-15, 15], ...          % Clinical small rotation tolerance
        'RandXReflection', true, ...            % Horizontal reflection (nasal/temporal flip)
        'RandYReflection', false, ...           % Avoid vertical upside-down fundus
        'RandScale', [0.92, 1.08], ...          % Moderate scaling
        'RandXTranslation', [-8, 8], ...
        'RandYTranslation', [-8, 8]);

    trainAugImds = augmentedImageDatastore(inputSize, trainImds, ...
        'DataAugmentation', imageAugmenter, ...
        'ColorPreprocessing', 'gray2rgb');

    valAugImds = augmentedImageDatastore(inputSize, valImds, ...
        'ColorPreprocessing', 'gray2rgb');

    % 3. Load Backbone and Adapt Classification Head
    fprintf('Initializing %s transfer learning backbone...\n', options.Architecture);
    try
        if options.Architecture == "resnet18"
            net = resnet18();
        elseif options.Architecture == "resnet50"
            net = resnet50();
        else
            net = resnet18();
        end
        lgraph = layerGraph(net);
    catch ME
        warning('EyeXpert:PretrainedDownload', 'Could not load online pretrained weights: %s. Building native ResNet architecture.', ME.message);
        % Fallback architectural graph for offline environments
        lgraph = createStandardResNetGraph(inputSize, numClasses);
    end

    % Replace final layers if using DAG network
    if isprop(lgraph, 'Layers')
        [learnableLayer, classLayer] = findSubmittableLayers(lgraph);
        
        newLearnableLayer = fullyConnectedLayer(numClasses, ...
            'Name', 'eyexpert_fc', ...
            'WeightLearnRateFactor', 10, ...
            'BiasLearnRateFactor', 10);
        
        newClassLayer = classificationLayer(...
            'Name', 'eyexpert_output', ...
            'Classes', classLabels, ...
            'ClassWeights', classWeights);

        lgraph = replaceLayer(lgraph, learnableLayer.Name, newLearnableLayer);
        lgraph = replaceLayer(lgraph, classLayer.Name, newClassLayer);
    end

    % 4. Training Options
    trainOpts = trainingOptions('adam', ...
        'InitialLearnRate', options.BaseLR, ...
        'MaxEpochs', options.MaxEpochs, ...
        'MiniBatchSize', options.MiniBatchSize, ...
        'Shuffle', 'every-epoch', ...
        'ValidationData', valAugImds, ...
        'ValidationFrequency', max(10, floor(height(trainTable) / options.MiniBatchSize)), ...
        'ValidationPatience', 4, ...
        'L2Regularization', options.WeightDecay, ...
        'ExecutionEnvironment', options.ExecutionEnvironment, ...
        'Plots', 'none', ...
        'Verbose', true);

    % 5. Execute Training
    fprintf('Starting model training...\n');
    startTime = tic;
    [trainedNet, trainInfo] = trainNetwork(trainAugImds, lgraph, trainOpts);
    trainDurationSec = toc(startTime);
    fprintf('Training completed in %.2f seconds.\n', trainDurationSec);

    % 6. Save Model Artifact
    modelInfo = struct();
    modelInfo.Architecture = options.Architecture;
    modelInfo.InputSize = inputSize;
    modelInfo.NumClasses = numClasses;
    modelInfo.ClassNames = string(uniqueCategories);
    modelInfo.ClassWeights = classWeights;
    modelInfo.TrainSamples = height(trainTable);
    modelInfo.ValSamples = height(valTable);
    modelInfo.TrainDurationSec = trainDurationSec;
    modelInfo.TrainedDate = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

    save(options.ModelSavePath, 'trainedNet', 'modelInfo', 'trainInfo');
    fprintf('Trained model and metadata saved to: %s\n', options.ModelSavePath);
    fprintf('=====================================================\n');
end

% Local helper to identify terminal layers
function [learnableLayer, classLayer] = findSubmittableLayers(lgraph)
    layers = lgraph.Layers;
    fcIdx = find(arrayfun(@(l) isa(l, 'nnet.cnn.layer.FullyConnectedLayer'), layers), 1, 'last');
    classIdx = find(arrayfun(@(l) isa(l, 'nnet.cnn.layer.ClassificationOutputLayer'), layers), 1, 'last');
    learnableLayer = layers(fcIdx);
    classLayer = layers(classIdx);
end

% Local fallback architecture generator
function lgraph = createStandardResNetGraph(inputSize, numClasses)
    layers = [
        imageInputLayer(inputSize, 'Name', 'input')
        convolution2dLayer(7, 64, 'Stride', 2, 'Padding', 'same', 'Name', 'conv1')
        batchNormalizationLayer('Name', 'bn_conv1')
        reluLayer('Name', 'conv1_relu')
        maxPooling2dLayer(3, 'Stride', 2, 'Padding', 'same', 'Name', 'pool1')
        
        convolution2dLayer(3, 64, 'Padding', 'same', 'Name', 'res2a_branch2a')
        batchNormalizationLayer('Name', 'bn2a_branch2a')
        reluLayer('Name', 'res2a_branch2a_relu')
        convolution2dLayer(3, 64, 'Padding', 'same', 'Name', 'res2a_branch2b')
        batchNormalizationLayer('Name', 'bn2a_branch2b')
        
        globalAveragePooling2dLayer('Name', 'gap')
        fullyConnectedLayer(numClasses, 'Name', 'eyexpert_fc')
        softmaxLayer('Name', 'eyexpert_softmax')
        classificationLayer('Name', 'eyexpert_output')
    ];
    lgraph = layerGraph(layers);
end
