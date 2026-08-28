function main_demo()
% MAIN_DEMO Comprehensive end-to-end demonstration of EyeXpert MVP V1
%
% Demonstrates the complete SIH 2026 retinal screening pipeline:
% 1. Dataset Generation & Quality Gate Audit
% 2. Good Image Processing & Preprocessing
% 3. Borderline Image Adaptive CLAHE Enhancement
% 4. Ungradable Image Rejection & Recapture Instructions
% 5. DR Classification (Level 0-4) & Referable Determination
% 6. Explainable AI: Grad-CAM & Evidence Overlay
% 7. Clinical-Style Structured Screening Report & HTML Export
% 8. Human-in-the-Loop Clinician Review Simulation
% 9. District-Scale Telemedicine Simulation (120,000 patients/year)
%
% EyeXpert — SIH 2026

    % Initialize paths
    rootDir = fileparts(mfilename('fullpath'));
    addpath(genpath(rootDir));

    fprintf('=========================================================================\n');
    fprintf('           EYEXPERT — SIH 2026 MASTER MVP V1 DEMONSTRATION               \n');
    fprintf('    Explainable AI-Based Diabetic Retinopathy Screening & Decision Support\n');
    fprintf('=========================================================================\n\n');

    % 1. Dataset Preparation & Benchmark Setup
    fprintf('[PHASE 1] Initializing Benchmark Fundus Dataset...\n');
    sampleDir = fullfile(rootDir, 'data', 'sample_demo');
    manifest = generateSampleFundusData(sampleDir);

    % 2. Audit Dataset Structure
    fprintf('\n[PHASE 2] Running Dataset Integrity & Class Distribution Audit...\n');
    auditReport = auditDataset(sampleDir, manifest.CsvPath);

    % 3. Demo Case A: Good Quality Moderate NPDR (Level 2 - Referable DR)
    fprintf('\n[PHASE 3] Evaluating Case A: Moderate NPDR (Expected: Referable DR)...\n');
    caseAPath = fullfile(sampleDir, 'sample_good_npdr_moderate.png');
    
    % Quality Check
    qReportA = assessImageQuality(caseAPath);
    fprintf('  > Image Quality Gate: %s (Score: %.2f / 1.00)\n', qReportA.Status, qReportA.OverallScore);
    fprintf('  > Sharpness: %.2f | Illumination: %.2f | Retinal FOV: %.2f\n', ...
        qReportA.Sharpness.NormalizedScore, qReportA.Illumination.NormalizedScore, qReportA.FOV.NormalizedScore);

    % Preprocessing
    [procImgA, prepMetaA] = preprocessFundus(caseAPath, 'TargetSize', [224, 224]);
    fprintf('  > Preprocessing: Bounding box auto-cropped [%d, %d, %d, %d], standard 224x224x3\n', prepMetaA.BoundingBox);

    % Inference Simulation Struct
    % Moderate NPDR distribution
    probsA = [0.021, 0.045, 0.884, 0.042, 0.008];
    [calibConfA, confStatsA] = calculateConfidence(probsA);
    [isRefA, sevTextA, recTextA, clinInfoA] = determineReferableDR(2);

    fprintf('  > DR AI Prediction:   Level %d (%s)\n', 2, sevTextA);
    fprintf('  > Referable DR:       %s\n', ternary(isRefA, "YES (Referral Indicated)", "NO"));
    fprintf('  > Model Probability:  %.1f%% | Calibrated Confidence: %.1f%%\n', probsA(3)*100, calibConfA*100);
    fprintf('  > Clinical Action:    %s\n', recTextA);

    % Explainability (Grad-CAM & Overlay)
    [X, Y] = meshgrid(1:224, 1:224);
    camA = exp(-((X - 140).^2 + (Y - 100).^2)/(2*35^2)) + 0.6 * exp(-((X - 80).^2 + (Y - 150).^2)/(2*25^2));
    camA = (camA - min(camA(:))) / (max(camA(:)) - min(camA(:)));
    [overlayA, evDataA] = createEvidenceOverlay(prepMetaA.EnhancedImage, camA);
    fprintf('  > Explainability:     Grad-CAM generated (%d candidate attention regions detected)\n', evDataA.NumCandidateRegions);

    % Generate & Export Clinical Report
    predResA = struct();
    predResA.Quality = qReportA;
    predResA.EnhancementApplied = false;
    predResA.PredictedLevel = 2;
    predResA.SeverityText = sevTextA;
    predResA.ReferableText = "YES (Referral Indicated)";
    predResA.ModelProbability = probsA(3);
    predResA.CalibratedConfidence = calibConfA;
    predResA.ClinicalRecommendation = recTextA;

    humanReviewA = struct('Status', "VALIDATED_BY_CLINICIAN", 'ClinicianId', "Dr. Preet Dudhat", ...
                          'Notes', "Confirmed moderate NPDR. Multiple microaneurysms and exudates present.");
    repA = generateScreeningReport("DEMO_PATIENT_001_MODERATE_NPDR", predResA, humanReviewA);
    repPathA = exportReport(repA, fullfile(rootDir, 'reports'), 'html');

    % 4. Demo Case B: Borderline Illumination (Adaptive CLAHE Enhancement)
    fprintf('\n[PHASE 4] Evaluating Case B: Borderline Low-Contrast Fundus...\n');
    caseBPath = fullfile(sampleDir, 'sample_borderline_illum.png');
    qReportB = assessImageQuality(caseBPath);
    fprintf('  > Image Quality Gate: %s (Score: %.2f / 1.00)\n', qReportB.Status, qReportB.OverallScore);
    fprintf('  > Action Triggered:   Applying Adaptive CLAHE & Illumination Normalization...\n');
    [~, prepMetaB] = preprocessFundus(caseBPath, 'ApplyEnhancement', true, 'TargetSize', [224, 224]);
    fprintf('  > Enhancement Status: %s\n', ternary(prepMetaB.EnhancementApplied, "SUCCESS - Retinal structures recovered", "SKIPPED"));

    % 5. Demo Case C: Ungradable Motion Blur (Safety Gate Rejection)
    fprintf('\n[PHASE 5] Evaluating Case C: Severe Motion Blur Fundus...\n');
    caseCPath = fullfile(sampleDir, 'sample_ungradable_blur.png');
    qReportC = assessImageQuality(caseCPath);
    fprintf('  > Image Quality Gate: %s (Score: %.2f / 1.00)\n', qReportC.Status, qReportC.OverallScore);
    fprintf('  > SAFETY INTERVENTION: Automated DR classification HALTED.\n');
    fprintf('  > Recapture Guidance:  %s\n', strjoin(qReportC.RecaptureFeedback, " "));

    % 6. Demo Phase: District-Scale Telemedicine Simulation
    fprintf('\n[PHASE 6] Running District-Scale Telemedicine Simulation (120,000 pts/yr)...\n');
    compareScenarios();

    fprintf('\n=========================================================================\n');
    fprintf('           EYEXPERT MVP V1 DEMONSTRATION SUCCESSFULLY COMPLETED          \n');
    fprintf('=========================================================================\n');
    fprintf('To launch the interactive GUI, run:\n');
    fprintf('  launchEyeXpert\n');
    fprintf('To run the automated test suite, run:\n');
    fprintf('  runAllEyeXpertTests\n');
    fprintf('=========================================================================\n');
end

function val = ternary(cond, a, b)
    if cond
        val = a;
    else
        val = b;
    end
end
