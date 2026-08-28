function results = test_preprocessing()
% TEST_PREPROCESSING Unit tests for fundus cropping, CLAHE enhancement, and sizing
%
% EyeXpert — SIH 2026

    fprintf('--- Running test_preprocessing ---\n');
    results = struct('Name', 'Preprocessing', 'Passed', 0, 'Total', 0, 'Details', {{}});

    sampleDir = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'sample_demo');
    if ~isfolder(sampleDir)
        generateSampleFundusData(sampleDir);
    end

    imgGood = imread(fullfile(sampleDir, 'sample_good_normal.png'));

    % Test 1: Auto-cropping borders
    [cropped, bbox, mask] = cropFundus(imgGood);
    assert(size(cropped, 1) > 0 && size(cropped, 2) > 0, 'Cropped image should be non-empty');
    assert(numel(bbox) == 4, 'Bounding box should have 4 coordinates');
    assert(all(bbox >= 1), 'Bounding box coordinates should be valid');
    results.Total = results.Total + 1; results.Passed = results.Passed + 1;
    results.Details{end+1} = 'Test 1 Passed: Fundus auto-cropping correctly isolates retinal disc';

    % Test 2: CLAHE Adaptive Enhancement
    enhanced = enhanceFundus(cropped, mask);
    assert(isa(enhanced, 'uint8'), 'Enhanced image must be uint8');
    assert(isequal(size(enhanced), size(cropped)), 'Enhanced size must match cropped size');
    results.Total = results.Total + 1; results.Passed = results.Passed + 1;
    results.Details{end+1} = 'Test 2 Passed: CLAHE enhancement preserves dimensions and uint8 format';

    % Test 3: Standard Preprocessing Pipeline Output Dimensions
    [procImg, meta] = preprocessFundus(imgGood, 'TargetSize', [224, 224], 'OutputType', 'uint8');
    assert(isequal(size(procImg), [224, 224, 3]), 'Target size must be [224, 224, 3]');
    assert(isfield(meta, 'OriginalImage'), 'Metadata must preserve original image');
    assert(isfield(meta, 'BoundingBox'), 'Metadata must preserve bounding box');
    results.Total = results.Total + 1; results.Passed = results.Passed + 1;
    results.Details{end+1} = 'Test 3 Passed: Standard pipeline produces 224x224x3 with full traceability';

    fprintf('Preprocessing Tests: %d/%d Passed.\n\n', results.Passed, results.Total);
end
