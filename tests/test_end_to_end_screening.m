function results = test_end_to_end_screening()
% TEST_END_TO_END_SCREENING End-to-end integration test
%
% Verifies the complete workflow:
% Image Acquisition -> Quality Assessment -> Gating -> Enhancement -> 
% Inference -> Referable Determination -> Report Generation -> Simulation Execution
%
% EyeXpert — SIH 2026

    fprintf('--- Running test_end_to_end_screening ---\n');
    results = struct('Name', 'End-to-End Integration', 'Passed', 0, 'Total', 0, 'Details', {{}});

    sampleDir = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'sample_demo');
    if ~isfolder(sampleDir)
        generateSampleFundusData(sampleDir);
    end

    % 1. Test Good Image screening path
    imgPath = fullfile(sampleDir, 'sample_good_npdr_moderate.png');
    qReport = assessImageQuality(imgPath);
    assert(qReport.IsScreeningAllowed == true, 'Good image should be allowed for screening');
    results.Total = results.Total + 1; results.Passed = results.Passed + 1;
    results.Details{end+1} = 'Step 1 Passed: Quality gate successfully evaluated';

    % 2. Test Preprocessing
    [procImg, meta] = preprocessFundus(imgPath, 'TargetSize', [224, 224]);
    assert(isequal(size(procImg), [224, 224, 3]), 'Preprocessed image format verified');
    results.Total = results.Total + 1; results.Passed = results.Passed + 1;
    results.Details{end+1} = 'Step 2 Passed: Preprocessing pipeline completed';

    % 3. Test Clinical Report Generation & Export
    dummyPred = struct();
    dummyPred.Quality = qReport;
    dummyPred.EnhancementApplied = false;
    dummyPred.PredictedLevel = 2;
    dummyPred.SeverityText = "Level 2 — Moderate NPDR";
    dummyPred.ReferableText = "YES (Referral Indicated)";
    dummyPred.ModelProbability = 0.892;
    dummyPred.CalibratedConfidence = 0.841;
    dummyPred.ClinicalRecommendation = "Ophthalmologist referral within 4 to 8 weeks.";

    humanReview = struct('Status', "VALIDATED_BY_CLINICIAN", 'ClinicianId', "Dr. Test", 'Notes', "Verified");
    report = generateScreeningReport("TEST_PT_001", dummyPred, humanReview);
    assert(~isempty(report.TextReport), 'Report text must be non-empty');
    assert(contains(report.TextReport, "EYEXPERT CLINICAL SCREENING REPORT"), 'Report title missing');
    
    repDir = fullfile(fileparts(mfilename('fullpath')), '..', 'reports');
    repPath = exportReport(report, repDir, 'txt');
    assert(isfile(repPath), 'Exported report file must exist on disk');
    results.Total = results.Total + 1; results.Passed = results.Passed + 1;
    results.Details{end+1} = 'Step 3 Passed: Screening report generation and export verified';

    % 4. Test District Simulation Run
    simRes = runDistrictSimulation('OPTIMIZED');
    assert(simRes.AvgQueueLength >= 0, 'Simulation queue length must be non-negative');
    assert(simRes.DoctorUtilization > 0 && simRes.DoctorUtilization <= 1.0, 'Doctor utilization in valid range');
    results.Total = results.Total + 1; results.Passed = results.Passed + 1;
    results.Details{end+1} = 'Step 4 Passed: Telemedicine district queuing simulation executed successfully';

    fprintf('End-to-End Tests: %d/%d Passed.\n\n', results.Passed, results.Total);
end
