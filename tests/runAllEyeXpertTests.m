function allPassed = runAllEyeXpertTests()
% RUNALLEYEXPERTESTS Master test runner for EyeXpert MVP V1
%
% Executes:
% - Image Quality Assessment unit tests
% - Preprocessing & Enhancement tests
% - Classification & Referable DR mapping tests
% - Explainability & Grad-CAM overlay tests
% - End-to-end integration test
%
% EyeXpert — SIH 2026

    % Add project directories to path
    rootDir = fullfile(fileparts(mfilename('fullpath')), '..');
    addpath(genpath(rootDir));

    fprintf('=================================================================\n');
    fprintf('           EYEXPERT MVP V1 — AUTOMATED TEST SUITE RUNNER         \n');
    fprintf('=================================================================\n\n');

    suiteResults = {};
    suiteResults{end+1} = test_quality_assessment();
    suiteResults{end+1} = test_preprocessing();
    suiteResults{end+1} = test_classification_pipeline();
    suiteResults{end+1} = test_explainability();
    suiteResults{end+1} = test_end_to_end_screening();

    totalPassed = 0;
    totalTests = 0;

    fprintf('=================================================================\n');
    fprintf('                      TEST EXECUTION SUMMARY                     \n');
    fprintf('=================================================================\n');
    for i = 1:numel(suiteResults)
        res = suiteResults{i};
        totalPassed = totalPassed + res.Passed;
        totalTests = totalTests + res.Total;
        statusStr = sprintf('[%d/%d]', res.Passed, res.Total);
        if res.Passed == res.Total
            fprintf('  ✔ %-35s %s PASSED\n', res.Name, statusStr);
        else
            fprintf('  ✖ %-35s %s FAILED\n', res.Name, statusStr);
        end
    end
    fprintf('-----------------------------------------------------------------\n');
    fprintf('TOTAL SCORE: %d / %d Tests Passed (%.1f%%)\n', totalPassed, totalTests, (totalPassed/totalTests)*100);
    fprintf('=================================================================\n');

    allPassed = (totalPassed == totalTests);
end
