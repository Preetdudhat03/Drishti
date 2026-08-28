function refMetrics = evaluateReferableDR(yTrueLevels, refProbabilities, threshold)
% EVALUATEREFERABLEDR Evaluates binary Referable DR screening metrics
%
% Referable DR Definition:
%   Level 0, 1 -> Non-Referable (Class 0)
%   Level 2, 3, 4 -> Referable DR (Class 1)
%
% Syntax:
%   refMetrics = evaluateReferableDR(yTrueLevels, refProbabilities)
%   refMetrics = evaluateReferableDR(yTrueLevels, refProbabilities, 0.50)
%
% Outputs:
%   refMetrics:
%     .TP, .TN, .FP, .FN
%     .Sensitivity    (Recall) = TP / (TP + FN)
%     .Specificity             = TN / (TN + FP)
%     .Precision               = TP / (TP + FP)
%     .Recall                  = TP / (TP + FN)
%     .F1                      = 2*P*R / (P+R)
%     .Accuracy                = (TP + TN) / Total
%     .ROC                     = Struct with FPR, TPR, Thresholds
%     .AUC                     = Area Under ROC Curve
%
% EyeXpert — SIH 2026

    arguments
        yTrueLevels (:,1) double
        refProbabilities (:,1) double
        threshold (1,1) double = 0.50
    end

    % 1. Convert ground truth to binary (1 = Referable, 0 = Non-referable)
    yTrueBinary = double(yTrueLevels >= 2);
    yPredBinary = double(refProbabilities >= threshold);

    % 2. Confusion Matrix Counts
    tp = sum((yTrueBinary == 1) & (yPredBinary == 1));
    tn = sum((yTrueBinary == 0) & (yPredBinary == 0));
    fp = sum((yTrueBinary == 0) & (yPredBinary == 1));
    fn = sum((yTrueBinary == 1) & (yPredBinary == 0));

    total = tp + tn + fp + fn;

    % 3. Standard Medical Metrics
    sens = tp / max(1, (tp + fn));
    spec = tn / max(1, (tn + fp));
    prec = tp / max(1, (tp + fp));
    rec = sens;
    if (prec + rec) > 0
        f1 = 2 * (prec * rec) / (prec + rec);
    else
        f1 = 0;
    end
    acc = (tp + tn) / max(1, total);

    % 4. Compute Empirical ROC Curve across sweep thresholds
    threshSweep = linspace(0, 1, 101);
    numT = numel(threshSweep);
    tprList = zeros(numT, 1);
    fprList = zeros(numT, 1);

    numPos = max(1, sum(yTrueBinary == 1));
    numNeg = max(1, sum(yTrueBinary == 0));

    for i = 1:numT
        tVal = threshSweep(i);
        pred_i = double(refProbabilities >= tVal);
        tp_i = sum((yTrueBinary == 1) & (pred_i == 1));
        fp_i = sum((yTrueBinary == 0) & (pred_i == 1));
        tprList(i) = tp_i / numPos;
        fprList(i) = fp_i / numNeg;
    end

    % Sort by FPR for monotonic trapezoidal AUC integration
    [sortedFPR, sortIdx] = sort(fprList);
    sortedTPR = tprList(sortIdx);

    % Ensure boundary points [0,0] and [1,1]
    sortedFPR = [0; sortedFPR; 1];
    sortedTPR = [0; sortedTPR; 1];

    auc = trapz(sortedFPR, sortedTPR);
    auc = max(0.0, min(1.0, auc));

    refMetrics = struct();
    refMetrics.Threshold = threshold;
    refMetrics.TotalSamples = total;
    refMetrics.TP = tp;
    refMetrics.TN = tn;
    refMetrics.FP = fp;
    refMetrics.FN = fn;
    refMetrics.Sensitivity = sens;
    refMetrics.Specificity = spec;
    refMetrics.Precision = prec;
    refMetrics.Recall = rec;
    refMetrics.F1 = f1;
    refMetrics.Accuracy = acc;
    refMetrics.AUC = auc;
    refMetrics.ROC = struct(...
        'FPR', sortedFPR, ...
        'TPR', sortedTPR, ...
        'Thresholds', threshSweep);
end
