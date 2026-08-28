function splitData = prepareDataset(dataDir, csvPath, outputDir, options)
% PREPAREDATASET Creates stratified train/val/test split tables
%
% Splits dataset into 70% train, 15% val, 15% test while strictly preserving
% the DR class distribution (0 to 4) and ensuring zero data leakage.
%
% Syntax:
%   splitData = prepareDataset(dataDir, csvPath, outputDir)
%   splitData = prepareDataset(dataDir, csvPath, outputDir, 'TrainRatio', 0.70, 'ValRatio', 0.15, 'TestRatio', 0.15, 'Seed', 42)
%
% EyeXpert — SIH 2026

    arguments
        dataDir (1,1) string
        csvPath (1,1) string
        outputDir (1,1) string = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'splits')
        options.TrainRatio (1,1) double = 0.70
        options.ValRatio (1,1) double = 0.15
        options.TestRatio (1,1) double = 0.15
        options.Seed (1,1) double = 42
    end

    rng(options.Seed);

    if ~isfolder(outputDir)
        mkdir(outputDir);
    end

    labelsTable = readtable(csvPath, 'TextType', 'string');
    colNames = lower(string(labelsTable.Properties.VariableNames));
    idColIdx = find(colNames == "id_code" | colNames == "image_id" | colNames == "id" | colNames == "image");
    diagColIdx = find(colNames == "diagnosis" | colNames == "dr_level" | colNames == "grade" | colNames == "label" | colNames == "level");

    if isempty(idColIdx) || isempty(diagColIdx)
        error('EyeXpert:InvalidCSV', 'CSV must contain id and diagnosis columns');
    end

    idCol = labelsTable.Properties.VariableNames{idColIdx(1)};
    diagCol = labelsTable.Properties.VariableNames{diagColIdx(1)};

    % Normalize diagnosis to numeric double
    rawDiag = labelsTable.(diagCol);
    if iscell(rawDiag) || isstring(rawDiag)
        labelsTable.diagnosis_clean = str2double(rawDiag);
    else
        labelsTable.diagnosis_clean = double(rawDiag);
    end

    % Verify file existence on disk
    validRows = false(height(labelsTable), 1);
    resolvedPaths = strings(height(labelsTable), 1);
    supportedExts = [".png", ".jpg", ".jpeg", ".tif"];

    for i = 1:height(labelsTable)
        rawId = string(labelsTable.(idCol)(i));
        for ext = supportedExts
            testP = fullfile(dataDir, rawId + ext);
            if isfile(testP)
                validRows(i) = true;
                resolvedPaths(i) = testP;
                break;
            end
            testDirect = fullfile(dataDir, rawId);
            if isfile(testDirect)
                validRows(i) = true;
                resolvedPaths(i) = testDirect;
                break;
            end
        end
    end

    cleanTable = labelsTable(validRows, :);
    cleanTable.ImagePath = resolvedPaths(validRows);
    cleanTable.is_referable = cleanTable.diagnosis_clean >= 2;

    totalValid = height(cleanTable);
    fprintf('Valid images available for stratified split: %d\n', totalValid);

    trainIndices = [];
    valIndices = [];
    testIndices = [];

    % Stratified split across classes 0 to 4
    for c = 0:4
        classIdx = find(cleanTable.diagnosis_clean == c);
        numInClass = numel(classIdx);
        if numInClass == 0
            continue;
        end

        perm = classIdx(randperm(numInClass));
        nTrain = round(options.TrainRatio * numInClass);
        nVal = round(options.ValRatio * numInClass);
        
        % Ensure at least 1 in val and test if class has enough samples
        if numInClass >= 3
            nTrain = max(1, min(nTrain, numInClass - 2));
            nVal = max(1, min(nVal, numInClass - nTrain - 1));
        end

        trainIdx = perm(1:nTrain);
        valIdx = perm((nTrain + 1):(nTrain + nVal));
        testIdx = perm((nTrain + nVal + 1):end);

        trainIndices = [trainIndices; trainIdx]; %#ok<AGROW>
        valIndices = [valIndices; valIdx]; %#ok<AGROW>
        testIndices = [testIndices; testIdx]; %#ok<AGROW>
    end

    trainTable = cleanTable(trainIndices, :);
    valTable = cleanTable(valIndices, :);
    testTable = cleanTable(testIndices, :);

    % Save splits
    trainPath = fullfile(outputDir, 'train_split.csv');
    valPath = fullfile(outputDir, 'val_split.csv');
    testPath = fullfile(outputDir, 'test_split.csv');

    writetable(trainTable, trainPath);
    writetable(valTable, valPath);
    writetable(testTable, testPath);

    splitData = struct();
    splitData.TrainTable = trainTable;
    splitData.ValTable = valTable;
    splitData.TestTable = testTable;
    splitData.TrainPath = trainPath;
    splitData.ValPath = valPath;
    splitData.TestPath = testPath;
    splitData.Counts = struct(...
        'Train', height(trainTable), ...
        'Val', height(valTable), ...
        'Test', height(testTable), ...
        'Total', totalValid);

    fprintf('Stratified Split Complete:\n');
    fprintf('  Train: %d (%4.1f%%)\n', splitData.Counts.Train, 100*splitData.Counts.Train/totalValid);
    fprintf('  Val:   %d (%4.1f%%)\n', splitData.Counts.Val, 100*splitData.Counts.Val/totalValid);
    fprintf('  Test:  %d (%4.1f%%)\n', splitData.Counts.Test, 100*splitData.Counts.Test/totalValid);
    fprintf('Saved split tables to: %s\n', outputDir);
end
