function evalResults = evaluateDRModel(testCsvPath, net, options)
% EVALUATEDRMODEL Evaluates trained EyeXpert model on held-out test split
%
% Generates:
% 1. 5-Class Confusion Matrix and Macro-F1 / Kappa
% 2. Referable DR Sensitivity, Specificity, Precision, Recall, F1, ROC/AUC
% 3. Quality Gate Statistics (Good / Borderline / Ungradable)
%
% EyeXpert — SIH 2026

    arguments
        testCsvPath (1,1) string = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'splits', 'test_split.csv')
        net = []
        options.ModelPath (1,1) string = fullfile(fileparts(mfilename('fullpath')), 'drModel.mat')
        options.Plots (1,1) logical = false
    end

    fprintf('=====================================================\n');
    fprintf('           EYEXPERT HELD-OUT TEST EVALUATION          \n');
    fprintf('=====================================================\n');

    if ~isfile(testCsvPath)
        error('EyeXpert:TestSplitNotFound', 'Test split CSV not found: %s', testCsvPath);
    end

    testTable = readtable(testCsvPath, 'TextType', 'string');
    totalTest = height(testTable);
    fprintf('Evaluating on %d test images...\n', totalTest);

    if isempty(net)
        [net, ~] = loadDRModel(options.ModelPath);
    end

    yTrue = double(testTable.diagnosis_clean);
    yPred = zeros(totalTest, 1);
    refProbs = zeros(totalTest, 1);
    qualityStates = strings(totalTest, 1);

    for i = 1:totalTest
        imgPath = testTable.ImagePath(i);
        imgRGB = imread(char(imgPath));

        % Step 1: Image Quality Assessment Gate
        qReport = assessImageQuality(imgRGB);
        qualityStates(i) = qReport.Status;

        % Step 2: Preprocess Fundus (auto-enhance if borderline)
        applyEnh = (qReport.Status == "BORDERLINE");
        preprocImg = preprocessFundus(imgRGB, 'ApplyEnhancement', applyEnh, 'TargetSize', [224, 224]);

        % Step 3: Model Inference
        probs = predict(net, preprocImg);
        probs = double(probs(:)');
        probs = probs / sum(probs);

        [~, maxIdx] = max(probs);
        yPred(i) = maxIdx - 1;

        % Referable probability = sum of probs for Level 2, 3, 4
        refProbs(i) = sum(probs(3:5));
    end

    % 1. Compute 5-Class Multi-class Metrics
    fiveClassMetrics = calculateMetrics(yTrue, yPred);

    % 2. Compute Binary Referable DR Metrics
    refMetrics = evaluateReferableDR(yTrue, refProbs);

    % 3. Quality Gate Distribution
    qGoodCount = sum(qualityStates == "GOOD");
    qBorderCount = sum(qualityStates == "BORDERLINE");
    qUngradCount = sum(qualityStates == "UNGRADABLE");

    evalResults = struct();
    evalResults.TotalSamples = totalTest;
    evalResults.FiveClassMetrics = fiveClassMetrics;
    evalResults.ReferableMetrics = refMetrics;
    evalResults.QualityDistribution = struct(...
        'GoodPercent', 100 * qGoodCount / totalTest, ...
        'BorderlinePercent', 100 * qBorderCount / totalTest, ...
        'UngradablePercent', 100 * qUngradCount / totalTest);

    % Print Evaluation Summary
    fprintf('\n--- 5-CLASS DR EVALUATION SUMMARY ---\n');
    fprintf('Accuracy:                     %5.2f%%\n', 100 * fiveClassMetrics.Accuracy);
    fprintf('Macro-Precision:              %5.2f%%\n', 100 * fiveClassMetrics.MacroPrecision);
    fprintf('Macro-Recall:                 %5.2f%%\n', 100 * fiveClassMetrics.MacroRecall);
    fprintf('Macro-F1 Score:               %5.2f%%\n', 100 * fiveClassMetrics.MacroF1);
    fprintf('Quadratic Weighted Kappa:     %5.3f\n',   fiveClassMetrics.QuadraticWeightedKappa);
    fprintf('-----------------------------------------------------\n');
    fprintf('--- REFERABLE DR SCREENING METRICS (LEVEL >= 2) ---\n');
    fprintf('Sensitivity (Recall):         %5.2f%%\n', 100 * refMetrics.Sensitivity);
    fprintf('Specificity:                  %5.2f%%\n', 100 * refMetrics.Specificity);
    fprintf('Precision (PPV):              %5.2f%%\n', 100 * refMetrics.Precision);
    fprintf('F1-Score:                     %5.2f%%\n', 100 * refMetrics.F1);
    fprintf('Area Under Curve (ROC AUC):   %5.3f\n',   refMetrics.AUC);
    fprintf('-----------------------------------------------------\n');
    fprintf('Quality Gate Distribution: Good: %.1f%%, Borderline: %.1f%%, Ungradable: %.1f%%\n', ...
        evalResults.QualityDistribution.GoodPercent, ...
        evalResults.QualityDistribution.BorderlinePercent, ...
        evalResults.QualityDistribution.UngradablePercent);
    fprintf('=====================================================\n');

    if options.Plots
        plotConfusionMatrix(fiveClassMetrics.ConfusionMatrix);
        plotROC(refMetrics.ROC, refMetrics.AUC);
    end
end
