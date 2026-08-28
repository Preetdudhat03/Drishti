function metrics = calculateMetrics(yTrue, yPred)
% CALCULATEMETRICS Evaluates 5-class DR classification metrics
%
% Syntax:
%   metrics = calculateMetrics(yTrue, yPred)
%
% Inputs:
%   yTrue - Vector of ground truth classes (0 to 4)
%   yPred - Vector of predicted classes (0 to 4)
%
% Outputs:
%   metrics:
%     .ConfusionMatrix      - 5x5 confusion matrix
%     .Accuracy             - Overall multi-class accuracy
%     .MacroPrecision       - Unweighted mean precision across classes
%     .MacroRecall          - Unweighted mean recall across classes
%     .MacroF1              - Unweighted mean F1-score across classes
%     .PerClassMetrics      - Struct array per DR Level
%     .QuadraticWeightedKappa- Inter-rater agreement metric standard in DR
%
% EyeXpert — SIH 2026

    arguments
        yTrue (:,1) double
        yPred (:,1) double
    end

    yTrue = round(yTrue);
    yPred = round(yPred);
    numClasses = 5;

    % 1. Build 5x5 Confusion Matrix (Rows = Ground Truth, Cols = Prediction)
    cm = zeros(numClasses, numClasses);
    for i = 1:numel(yTrue)
        if yTrue(i) >= 0 && yTrue(i) < numClasses && yPred(i) >= 0 && yPred(i) < numClasses
            r = yTrue(i) + 1;
            c = yPred(i) + 1;
            cm(r, c) = cm(r, c) + 1;
        end
    end

    totalSamples = sum(cm(:));
    accuracy = sum(diag(cm)) / max(1, totalSamples);

    % 2. Per-class Precision, Recall, F1, Specificity
    perClass = struct('Level', {}, 'Precision', {}, 'Recall', {}, 'F1', {}, 'Specificity', {}, 'Support', {});
    precList = zeros(numClasses, 1);
    recList = zeros(numClasses, 1);
    f1List = zeros(numClasses, 1);

    for c = 1:numClasses
        tp = cm(c, c);
        fp = sum(cm(:, c)) - tp;
        fn = sum(cm(c, :)) - tp;
        tn = totalSamples - (tp + fp + fn);
        support = sum(cm(c, :));

        p = tp / max(1, (tp + fp));
        r = tp / max(1, (tp + fn));
        if (p + r) > 0
            f = 2 * p * r / (p + r);
        else
            f = 0;
        end
        spec = tn / max(1, (tn + fp));

        precList(c) = p;
        recList(c) = r;
        f1List(c) = f;

        perClass(c).Level = sprintf('Level %d', c - 1);
        perClass(c).Precision = p;
        perClass(c).Recall = r;
        perClass(c).F1 = f;
        perClass(c).Specificity = spec;
        perClass(c).Support = support;
    end

    macroP = mean(precList);
    macroR = mean(recList);
    macroF1 = mean(f1List);

    % 3. Quadratic Weighted Kappa (QWK)
    qwk = computeQuadraticWeightedKappa(cm);

    metrics = struct();
    metrics.ConfusionMatrix = cm;
    metrics.TotalSamples = totalSamples;
    metrics.Accuracy = accuracy;
    metrics.MacroPrecision = macroP;
    metrics.MacroRecall = macroR;
    metrics.MacroF1 = macroF1;
    metrics.QuadraticWeightedKappa = qwk;
    metrics.PerClassMetrics = perClass;
end

function kappa = computeQuadraticWeightedKappa(cm)
    N = size(cm, 1);
    total = sum(cm(:));
    if total == 0
        kappa = 0;
        return;
    end

    % Weight matrix W(i,j) = (i - j)^2 / (N - 1)^2
    [I, J] = ndgrid(1:N, 1:N);
    W = (I - J).^2 / (N - 1)^2;

    % Observed histogram
    histTrue = sum(cm, 2);
    histPred = sum(cm, 1);
    E = (histTrue * histPred) / total;

    num = sum(sum(W .* cm));
    den = sum(sum(W .* E));

    if den == 0
        kappa = 1.0;
    else
        kappa = 1.0 - (num / den);
    end
end
