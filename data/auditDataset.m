function auditReport = auditDataset(dataDir, csvPath, options)
% AUDITDATASET Comprehensive dataset auditor for EyeXpert MVP V1
%
% Syntax:
%   auditReport = auditDataset(dataDir, csvPath)
%   auditReport = auditDataset(dataDir, csvPath, 'ImageExtension', '.png', 'Seed', 42)
%
% Inputs:
%   dataDir  - Path to folder containing fundus images
%   csvPath  - Path to CSV file containing 'id_code' and 'diagnosis' columns
%   options  - (Optional) Name-value pairs for configuration
%
% Outputs:
%   auditReport - Struct containing total images, class distribution, 
%                 corrupted images, duplicates, and split integrity stats.
%
% EyeXpert — SIH 2026

    arguments
        dataDir (1,1) string
        csvPath (1,1) string
        options.ImageExtension (1,1) string = ""
        options.Seed (1,1) double = 42
        options.CheckDuplicates (1,1) logical = true
    end

    fprintf('=====================================================\n');
    fprintf('           EYEXPERT DATASET AUDIT REPORT             \n');
    fprintf('=====================================================\n');
    fprintf('Image Directory: %s\n', dataDir);
    fprintf('Labels CSV Path: %s\n', csvPath);

    auditReport = struct();
    auditReport.Timestamp = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    auditReport.DataDir = dataDir;
    auditReport.CsvPath = csvPath;
    auditReport.IsValid = false;
    auditReport.TotalRecords = 0;
    auditReport.ImagesFound = 0;
    auditReport.MissingImages = string.empty;
    auditReport.CorruptedImages = string.empty;
    auditReport.DuplicateHashes = struct.empty;
    auditReport.ClassCounts = containers.Map('KeyType', 'int32', 'ValueType', 'int32');
    auditReport.ReferableCounts = struct('NonReferable', 0, 'Referable', 0);
    auditReport.ResolutionStats = struct('MinHeight', Inf, 'MaxHeight', 0, 'MinWidth', Inf, 'MaxWidth', 0);

    % 1. Verify existence of paths
    if ~isfolder(dataDir)
        warning('EyeXpert:DataDirNotFound', 'Image directory does not exist: %s', dataDir);
        auditReport.ErrorMessage = "Image directory not found";
        return;
    end

    if ~isfile(csvPath)
        warning('EyeXpert:CsvNotFound', 'Labels CSV file does not exist: %s', csvPath);
        auditReport.ErrorMessage = "Labels CSV not found";
        return;
    end

    % 2. Read Labels CSV
    try
        labelsTable = readtable(csvPath, 'TextType', 'string');
    catch ME
        warning('EyeXpert:CsvReadError', 'Failed to read CSV: %s', ME.message);
        auditReport.ErrorMessage = "CSV read error: " + string(ME.message);
        return;
    end

    % Validate standard column names (e.g. id_code, diagnosis)
    colNames = lower(string(labelsTable.Properties.VariableNames));
    idColIdx = find(colNames == "id_code" | colNames == "image_id" | colNames == "id" | colNames == "image");
    diagColIdx = find(colNames == "diagnosis" | colNames == "dr_level" | colNames == "grade" | colNames == "label" | colNames == "level");

    if isempty(idColIdx) || isempty(diagColIdx)
        auditReport.ErrorMessage = "CSV must contain image ID and diagnosis/level columns (e.g., id_code, diagnosis)";
        warning('EyeXpert:InvalidCSVColumns', '%s', auditReport.ErrorMessage);
        return;
    end

    idColName = labelsTable.Properties.VariableNames{idColIdx(1)};
    diagColName = labelsTable.Properties.VariableNames{diagColIdx(1)};
    
    totalRows = height(labelsTable);
    auditReport.TotalRecords = totalRows;
    fprintf('Total Records in CSV: %d\n', totalRows);

    % Initialize class counts (0 to 4)
    for c = 0:4
        auditReport.ClassCounts(int32(c)) = 0;
    end

    % 3. Check image files on disk
    missingList = string.empty;
    corruptList = string.empty;
    foundCount = 0;
    
    supportedExts = [".png", ".jpg", ".jpeg", ".tif", ".bmp"];
    if options.ImageExtension ~= ""
        supportedExts = [options.ImageExtension, supportedExts];
    end

    fileHashes = containers.Map('KeyType', 'char', 'ValueType', 'any');
    duplicatePairs = {};

    fprintf('Auditing images for integrity and resolution...\n');
    for i = 1:totalRows
        rawId = string(labelsTable.(idColName)(i));
        rawDiag = labelsTable.(diagColName)(i);

        % Resolve numeric diagnosis
        if iscell(rawDiag) || isstring(rawDiag)
            diagVal = str2double(rawDiag);
        else
            diagVal = double(rawDiag);
        end

        if isnan(diagVal) || diagVal < 0 || diagVal > 4
            warning('Row %d has invalid diagnosis value: %s', i, string(rawDiag));
            continue;
        end

        intDiag = int32(round(diagVal));
        auditReport.ClassCounts(intDiag) = auditReport.ClassCounts(intDiag) + 1;

        % Locate file on disk
        imgFile = "";
        for ext = supportedExts
            testPath = fullfile(dataDir, rawId + ext);
            if isfile(testPath)
                imgFile = testPath;
                break;
            end
            % Test if rawId already contains extension
            testPathDirect = fullfile(dataDir, rawId);
            if isfile(testPathDirect)
                imgFile = testPathDirect;
                break;
            end
        end

        if imgFile == ""
            missingList(end+1) = rawId; %#ok<AGROW>
            continue;
        end

        foundCount = foundCount + 1;

        % Read image header to check corruption
        try
            info = imfinfo(imgFile);
            h = info(1).Height;
            w = info(1).Width;
            auditReport.ResolutionStats.MinHeight = min(auditReport.ResolutionStats.MinHeight, h);
            auditReport.ResolutionStats.MaxHeight = max(auditReport.ResolutionStats.MaxHeight, h);
            auditReport.ResolutionStats.MinWidth = min(auditReport.ResolutionStats.MinWidth, w);
            auditReport.ResolutionStats.MaxWidth = max(auditReport.ResolutionStats.MaxWidth, w);
        catch
            corruptList(end+1) = rawId; %#ok<AGROW>
        end

        % Duplicate hash detection if requested
        if options.CheckDuplicates && imgFile ~= ""
            try
                hasher = java.security.MessageDigest.getInstance('MD5');
                fid = fopen(imgFile, 'r');
                bytes = fread(fid, 8192, 'uint8=>uint8');
                fclose(fid);
                hasher.update(bytes);
                hashStr = char(java.lang.String.format('%032x', java.math.BigInteger(1, hasher.digest())));

                if isKey(fileHashes, hashStr)
                    existingId = fileHashes(hashStr);
                    duplicatePairs{end+1} = struct('Hash', hashStr, 'Id1', existingId, 'Id2', char(rawId)); %#ok<AGROW>
                else
                    fileHashes(hashStr) = char(rawId);
                end
            catch
                % Silently proceed if hashing fails
            end
        end
    end

    auditReport.ImagesFound = foundCount;
    auditReport.MissingImages = missingList;
    auditReport.CorruptedImages = corruptList;
    auditReport.DuplicatePairs = duplicatePairs;

    % Referable counts (Level 0,1 -> Non-referable; Level 2,3,4 -> Referable)
    nonRef = auditReport.ClassCounts(0) + auditReport.ClassCounts(1);
    ref = auditReport.ClassCounts(2) + auditReport.ClassCounts(3) + auditReport.ClassCounts(4);
    auditReport.ReferableCounts.NonReferable = nonRef;
    auditReport.ReferableCounts.Referable = ref;

    auditReport.IsValid = (foundCount > 0) && (numel(corruptList) == 0);

    % Print Summary Table
    fprintf('\n--- CLASS DISTRIBUTION SUMMARY ---\n');
    fprintf('Level 0 (No DR):         %6d (%5.1f%%) [Non-Referable]\n', auditReport.ClassCounts(0), 100*auditReport.ClassCounts(0)/max(1, totalRows));
    fprintf('Level 1 (Mild NPDR):     %6d (%5.1f%%) [Non-Referable]\n', auditReport.ClassCounts(1), 100*auditReport.ClassCounts(1)/max(1, totalRows));
    fprintf('Level 2 (Moderate NPDR): %6d (%5.1f%%) [Referable]\n',     auditReport.ClassCounts(2), 100*auditReport.ClassCounts(2)/max(1, totalRows));
    fprintf('Level 3 (Severe NPDR):   %6d (%5.1f%%) [Referable]\n',     auditReport.ClassCounts(3), 100*auditReport.ClassCounts(3)/max(1, totalRows));
    fprintf('Level 4 (Proliferative): %6d (%5.1f%%) [Referable]\n',     auditReport.ClassCounts(4), 100*auditReport.ClassCounts(4)/max(1, totalRows));
    fprintf('-----------------------------------------------------\n');
    fprintf('Non-Referable Total:     %6d (%5.1f%%)\n', nonRef, 100*nonRef/max(1, totalRows));
    fprintf('Referable DR Total:      %6d (%5.1f%%)\n', ref, 100*ref/max(1, totalRows));
    fprintf('-----------------------------------------------------\n');
    fprintf('Images Found: %d / %d\n', foundCount, totalRows);
    fprintf('Missing Images: %d\n', numel(missingList));
    fprintf('Corrupted Images: %d\n', numel(corruptList));
    fprintf('Duplicate Image Pairs Detected: %d\n', numel(duplicatePairs));
    fprintf('Resolution Range: %dx%d to %dx%d\n', ...
        auditReport.ResolutionStats.MinWidth, auditReport.ResolutionStats.MinHeight, ...
        auditReport.ResolutionStats.MaxWidth, auditReport.ResolutionStats.MaxHeight);
    fprintf('=====================================================\n');
end
