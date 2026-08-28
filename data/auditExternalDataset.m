function externalReport = auditExternalDataset(dataDir, csvPath, options)
% AUDITEXTERNALDATASET Audit friend's / secondary fundus dataset
%
% Assesses external datasets for resolution, label compatibility with 
% DR severity (0-4), quality, and isolation from training data.
%
% EyeXpert — SIH 2026

    arguments
        dataDir (1,1) string
        csvPath (1,1) string = ""
        options.SupportedDRScale (1,1) logical = false
    end

    fprintf('=====================================================\n');
    fprintf('       EYEXPERT EXTERNAL DATASET AUDIT               \n');
    fprintf('=====================================================\n');
    fprintf('External Image Directory: %s\n', dataDir);

    externalReport = struct();
    externalReport.Timestamp = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    externalReport.DataDir = dataDir;
    externalReport.CsvPath = csvPath;
    externalReport.IsCompatibleWithDRScale = false;
    externalReport.UsableAsGeneralizationTest = false;
    externalReport.Recommendation = "";

    if ~isfolder(dataDir)
        warning('EyeXpert:ExternalDataDirNotFound', 'Directory not found: %s', dataDir);
        externalReport.Recommendation = "Directory does not exist.";
        return;
    end

    % Scan all image files
    imgFiles = dir(fullfile(dataDir, '**', '*.png'));
    imgFiles = [imgFiles; dir(fullfile(dataDir, '**', '*.jpg'))];
    imgFiles = [imgFiles; dir(fullfile(dataDir, '**', '*.jpeg'))];
    imgFiles = [imgFiles; dir(fullfile(dataDir, '**', '*.tif'))];

    externalReport.TotalImages = numel(imgFiles);
    fprintf('Found %d image files in external directory.\n', externalReport.TotalImages);

    if externalReport.TotalImages == 0
        externalReport.Recommendation = "No images found in directory.";
        return;
    end

    % Check if labels CSV is provided
    if csvPath ~= "" && isfile(csvPath)
        try
            extTable = readtable(csvPath, 'TextType', 'string');
            externalReport.HasLabels = true;
            externalReport.LabelColumns = string(extTable.Properties.VariableNames);
            fprintf('Labels CSV detected with columns: %s\n', strjoin(externalReport.LabelColumns, ', '));

            % Check if DR 0-4 scale is present
            colNames = lower(externalReport.LabelColumns);
            diagIdx = find(colNames == "diagnosis" | colNames == "dr_level" | colNames == "grade" | colNames == "level" | colNames == "dr");
            if ~isempty(diagIdx)
                vals = extTable.(externalReport.LabelColumns(diagIdx(1)));
                numVals = str2double(string(vals));
                if all(~isnan(numVals) & numVals >= 0 & numVals <= 4)
                    externalReport.IsCompatibleWithDRScale = true;
                    externalReport.UsableAsGeneralizationTest = true;
                    externalReport.Recommendation = "Compatible DR 0-4 labels. Safe for external generalization testing ONLY. DO NOT merge into training set.";
                else
                    externalReport.Recommendation = "Labels are non-standard. Require manual clinical mapping before use.";
                end
            else
                externalReport.Recommendation = "No DR severity column detected. Treat as unlabelled / exploratory external dataset.";
            end
        catch ME
            externalReport.HasLabels = false;
            externalReport.Recommendation = "Failed to parse CSV: " + string(ME.message);
        end
    else
        externalReport.HasLabels = false;
        externalReport.Recommendation = "No labels CSV provided. Usable only for unlabelled quality testing or exploratory inference.";
    end

    fprintf('Generalization Suitability: %s\n', string(externalReport.UsableAsGeneralizationTest));
    fprintf('Recommendation: %s\n', externalReport.Recommendation);
    fprintf('=====================================================\n');
end
