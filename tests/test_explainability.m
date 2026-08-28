function results = test_explainability()
% TEST_EXPLAINABILITY Tests Grad-CAM overlay and evidence generation
%
% EyeXpert — SIH 2026

    fprintf('--- Running test_explainability ---\n');
    results = struct('Name', 'Explainability & Evidence', 'Passed', 0, 'Total', 0, 'Details', {{}});

    sampleDir = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'sample_demo');
    if ~isfolder(sampleDir)
        generateSampleFundusData(sampleDir);
    end

    imgGood = imread(fullfile(sampleDir, 'sample_good_normal.png'));
    [h, w, ~] = size(imgGood);

    % Synthetic test activation heatmap
    [X, Y] = meshgrid(1:224, 1:224);
    testCAM = exp(-((X - 112).^2 + (Y - 112).^2) / (2 * 40^2));

    % Test 1: Evidence overlay generation
    [overlay, evData] = createEvidenceOverlay(imgGood, testCAM, 'Colormap', 'turbo');
    assert(isequal(size(overlay), size(imgGood)), 'Overlay dimensions must match original image');
    assert(isa(overlay, 'uint8'), 'Overlay must be uint8');
    assert(isfield(evData, 'CandidateRegions'), 'Evidence struct must contain candidate regions');
    assert(isfield(evData, 'ClinicalNotice'), 'Evidence struct must include clinical disclaimer');
    results.Total = results.Total + 1; results.Passed = results.Passed + 1;
    results.Details{end+1} = 'Test 1 Passed: Grad-CAM evidence overlay and disclaimer generation verified';

    % Test 2: Vessel extraction and Optic Disc localization CV helpers
    [vessels, ~] = extractVessels(imgGood);
    assert(size(vessels, 1) == h && size(vessels, 2) == w, 'Vessel mask must match image dimensions');
    [discCenter, discRadius, ~] = locateOpticDisc(imgGood);
    assert(numel(discCenter) == 2, 'Disc center must be [x, y]');
    assert(discRadius > 0, 'Disc radius must be positive');
    results.Total = results.Total + 1; results.Passed = results.Passed + 1;
    results.Details{end+1} = 'Test 2 Passed: Computer vision feature analysis tools verified';

    fprintf('Explainability Tests: %d/%d Passed.\n\n', results.Passed, results.Total);
end
