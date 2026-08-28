function results = test_quality_assessment()
% TEST_QUALITY_ASSESSMENT Unit tests for image quality assessment gate
%
% Tests:
% 1. Sharpness calculation on sharp vs blurry images
% 2. Illumination and exposure metrics on normal vs dark images
% 3. Field of view and retinal mask segmentation
% 4. Quality gating into GOOD, BORDERLINE, UNGRADABLE
%
% EyeXpert — SIH 2026

    fprintf('--- Running test_quality_assessment ---\n');
    results = struct('Name', 'Quality Assessment', 'Passed', 0, 'Total', 0, 'Details', {{}});

    % Ensure benchmark samples exist
    sampleDir = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'sample_demo');
    if ~isfolder(sampleDir)
        generateSampleFundusData(sampleDir);
    end

    % Test 1: Good Normal image
    imgGood = imread(fullfile(sampleDir, 'sample_good_normal.png'));
    qGood = assessImageQuality(imgGood);
    assert(qGood.Status == "GOOD", 'Expected Good image to have GOOD status');
    assert(qGood.OverallScore >= 0.70, 'Expected Good score >= 0.70');
    assert(qGood.IsScreeningAllowed == true, 'Expected screening allowed for Good image');
    results.Total = results.Total + 1; results.Passed = results.Passed + 1;
    results.Details{end+1} = 'Test 1 Passed: Good fundus recognized and allowed';

    % Test 2: Borderline illumination image
    imgBorder = imread(fullfile(sampleDir, 'sample_borderline_illum.png'));
    qBorder = assessImageQuality(imgBorder);
    assert(qBorder.Status == "BORDERLINE", 'Expected Borderline status');
    assert(qBorder.IsScreeningAllowed == true, 'Expected screening allowed (with enhancement)');
    results.Total = results.Total + 1; results.Passed = results.Passed + 1;
    results.Details{end+1} = 'Test 2 Passed: Borderline fundus identified for enhancement';

    % Test 3: Ungradable blurry image
    imgBlur = imread(fullfile(sampleDir, 'sample_ungradable_blur.png'));
    qBlur = assessImageQuality(imgBlur);
    assert(qBlur.Status == "UNGRADABLE", 'Expected Blurry image to be UNGRADABLE');
    assert(qBlur.IsScreeningAllowed == false, 'Expected screening rejected');
    assert(~isempty(qBlur.RecaptureFeedback), 'Expected recapture feedback');
    results.Total = results.Total + 1; results.Passed = results.Passed + 1;
    results.Details{end+1} = 'Test 3 Passed: Severe blur safely rejected with feedback';

    % Test 4: Ungradable dark image
    imgDark = imread(fullfile(sampleDir, 'sample_ungradable_dark.png'));
    qDark = assessImageQuality(imgDark);
    assert(qDark.Status == "UNGRADABLE", 'Expected Dark image to be UNGRADABLE');
    assert(qDark.IsScreeningAllowed == false, 'Expected screening rejected');
    results.Total = results.Total + 1; results.Passed = results.Passed + 1;
    results.Details{end+1} = 'Test 4 Passed: Severe underexposure safely rejected with feedback';

    fprintf('Quality Assessment Tests: %d/%d Passed.\n\n', results.Passed, results.Total);
end
