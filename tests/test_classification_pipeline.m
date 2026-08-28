function results = test_classification_pipeline()
% TEST_CLASSIFICATION_PIPELINE Tests DR level mapping, referable rules, and confidence
%
% EyeXpert — SIH 2026

    fprintf('--- Running test_classification_pipeline ---\n');
    results = struct('Name', 'Classification Rules & Metrics', 'Passed', 0, 'Total', 0, 'Details', {{}});

    % Test 1: Referable DR mapping rules (0,1 Non-referable vs 2,3,4 Referable)
    [ref0, ~, ~, ~] = determineReferableDR(0);
    [ref1, ~, ~, ~] = determineReferableDR(1);
    [ref2, ~, ~, ~] = determineReferableDR(2);
    [ref3, ~, ~, ~] = determineReferableDR(3);
    [ref4, ~, ~, ~] = determineReferableDR(4);

    assert(ref0 == false, 'Level 0 must be Non-referable');
    assert(ref1 == false, 'Level 1 must be Non-referable');
    assert(ref2 == true,  'Level 2 must be Referable');
    assert(ref3 == true,  'Level 3 must be Referable');
    assert(ref4 == true,  'Level 4 must be Referable');
    results.Total = results.Total + 1; results.Passed = results.Passed + 1;
    results.Details{end+1} = 'Test 1 Passed: 5-level to Referable DR clinical mapping strictly verified';

    % Test 2: Calibrated Confidence calculation
    testProbs = [0.05, 0.10, 0.75, 0.08, 0.02];
    [calibConf, stats] = calculateConfidence(testProbs, 'Temperature', 1.25);
    assert(calibConf > 0 && calibConf <= 1.0, 'Calibrated confidence must be in (0, 1]');
    assert(stats.PredictedLevel == 2, 'Predicted level must be 2');
    assert(isfield(stats, 'NormalizedEntropy'), 'Entropy uncertainty metric must be present');
    results.Total = results.Total + 1; results.Passed = results.Passed + 1;
    results.Details{end+1} = 'Test 2 Passed: Temperature-scaled calibrated confidence verified';

    % Test 3: Validation Metrics calculation (Sensitivity, Specificity, AUC)
    yTrue = [0; 0; 1; 1; 2; 2; 3; 4];
    refProbs = [0.1; 0.2; 0.3; 0.15; 0.85; 0.90; 0.95; 0.99];
    refMetrics = evaluateReferableDR(yTrue, refProbs, 0.50);
    assert(refMetrics.TP == 4, 'Expected 4 True Positives');
    assert(refMetrics.TN == 4, 'Expected 4 True Negatives');
    assert(refMetrics.Sensitivity == 1.0, 'Expected 100% Sensitivity');
    assert(refMetrics.Specificity == 1.0, 'Expected 100% Specificity');
    assert(refMetrics.AUC == 1.0, 'Expected AUC 1.0');
    results.Total = results.Total + 1; results.Passed = results.Passed + 1;
    results.Details{end+1} = 'Test 3 Passed: Referable DR validation math strictly verified';

    fprintf('Classification Tests: %d/%d Passed.\n\n', results.Passed, results.Total);
end
